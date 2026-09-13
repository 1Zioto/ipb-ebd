<?php

namespace App\Services;

use App\Models\ColetaDizimo;
use App\Models\Institution;
use App\Models\InstitutionHistory;
use App\Models\InstitutionLinkRequest;
use App\Models\InstitutionTransfer;
use App\Models\Person;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class InstitutionService
{
    /**
     * Retorna os IDs de todas as instituições descendentes (diretas e indiretas)
     * utilizando CTE Recursivo (PostgreSQL / MySQL 8+ compatível).
     */
    public function getDescendantIds(int $institutionId, bool $includeSelf = true): array
    {
        $sql = "
            WITH RECURSIVE descendants AS (
                SELECT id, parent_institution_id
                FROM institutions
                WHERE id = ? AND deleted_at IS NULL
                
                UNION ALL
                
                SELECT i.id, i.parent_institution_id
                FROM institutions i
                INNER JOIN descendants d ON i.parent_institution_id = d.id
                WHERE i.deleted_at IS NULL
            )
            SELECT id FROM descendants
        ";

        $results = DB::select($sql, [$institutionId]);
        $ids = array_map(fn ($row) => (int) $row->id, $results);

        if (! $includeSelf) {
            $ids = array_values(array_filter($ids, fn ($id) => $id !== $institutionId));
        }

        return $ids;
    }

    /**
     * Retorna a linha ascendente de instituições (do nó atual até a raiz).
     */
    public function getAncestorIds(int $institutionId, bool $includeSelf = true): array
    {
        $sql = "
            WITH RECURSIVE ancestors AS (
                SELECT id, parent_institution_id, 1 as depth
                FROM institutions
                WHERE id = ? AND deleted_at IS NULL
                
                UNION ALL
                
                SELECT i.id, i.parent_institution_id, a.depth + 1
                FROM institutions i
                INNER JOIN ancestors a ON i.id = a.parent_institution_id
                WHERE i.deleted_at IS NULL
            )
            SELECT id FROM ancestors ORDER BY depth ASC
        ";

        $results = DB::select($sql, [$institutionId]);
        $ids = array_map(fn ($row) => (int) $row->id, $results);

        if (! $includeSelf) {
            $ids = array_values(array_filter($ids, fn ($id) => $id !== $institutionId));
        }

        return $ids;
    }

    /**
     * Retorna a lista de breadcrumbs (da raiz até a instituição atual).
     */
    public function getBreadcrumbs(int $institutionId): array
    {
        $sql = "
            WITH RECURSIVE ancestors AS (
                SELECT id, name, short_name, type, parent_institution_id, 1 as depth
                FROM institutions
                WHERE id = ? AND deleted_at IS NULL
                
                UNION ALL
                
                SELECT i.id, i.name, i.short_name, i.type, i.parent_institution_id, a.depth + 1
                FROM institutions i
                INNER JOIN ancestors a ON i.id = a.parent_institution_id
                WHERE i.deleted_at IS NULL
            )
            SELECT id, name, short_name, type FROM ancestors ORDER BY depth DESC
        ";

        $results = DB::select($sql, [$institutionId]);
        return array_map(fn ($row) => (array) $row, $results);
    }

    /**
     * Retorna a árvore completa de instituições em formato aninhado.
     */
    public function getTree(?int $rootId = null): array
    {
        $allowedIds = $rootId ? $this->getDescendantIds($rootId, true) : null;

        $query = Institution::query()->whereNull('deleted_at');
        if ($allowedIds) {
            $query->whereIn('id', $allowedIds);
        }

        $all = $query->orderBy('type')->orderBy('name')->get();

        // Mapear métricas básicas por instituição
        $metricsMap = $this->getBasicMetricsForInstitutions($all->pluck('id')->all());

        $grouped = [];
        foreach ($all as $inst) {
            $parentId = $inst->parent_institution_id ?? 0;
            if ($rootId && $inst->id === $rootId) {
                $parentId = 0; // Trata o nó raiz como topo da subárvore
            }
            $grouped[$parentId][] = [
                'id' => $inst->id,
                'name' => $inst->name,
                'short_name' => $inst->short_name,
                'type' => $inst->type,
                'status' => $inst->status,
                'city' => $inst->city,
                'state' => $inst->state,
                'parent_institution_id' => $inst->parent_institution_id,
                'members_count' => $metricsMap[$inst->id]['members_count'] ?? 0,
                'subordinates_count' => $metricsMap[$inst->id]['subordinates_count'] ?? 0,
                'children' => [],
            ];
        }

        return $this->buildTreeNodes($grouped, 0);
    }

    private function buildTreeNodes(array &$grouped, int $parentId): array
    {
        if (! isset($grouped[$parentId])) {
            return [];
        }

        $nodes = [];
        foreach ($grouped[$parentId] as $node) {
            $children = $this->buildTreeNodes($grouped, $node['id']);
            $node['children'] = $children;
            // Total subordinados soma filhos diretos + descendentes
            $node['subordinates_count'] = count($children);
            $nodes[] = $node;
        }

        return $nodes;
    }

    /**
     * Retorna métricas agregadas básicas para uma lista de IDs de instituição.
     */
    private function getBasicMetricsForInstitutions(array $ids): array
    {
        if (empty($ids)) {
            return [];
        }

        $peopleCounts = Person::query()
            ->select('institution_id', DB::raw('COUNT(*) as total'))
            ->whereIn('institution_id', $ids)
            ->where('is_active', true)
            ->groupBy('institution_id')
            ->pluck('total', 'institution_id');

        $subCounts = Institution::query()
            ->select('parent_institution_id', DB::raw('COUNT(*) as total'))
            ->whereIn('parent_institution_id', $ids)
            ->whereNull('deleted_at')
            ->groupBy('parent_institution_id')
            ->pluck('total', 'parent_institution_id');

        $result = [];
        foreach ($ids as $id) {
            $result[$id] = [
                'members_count' => (int) ($peopleCounts[$id] ?? 0),
                'subordinates_count' => (int) ($subCounts[$id] ?? 0),
            ];
        }

        return $result;
    }

    /**
     * Retorna estatísticas consolidadas recursivas (membresia, EBD, financeiro).
     */
    public function getConsolidatedStats(int $institutionId, bool $consolidated = true, ?int $year = null, ?int $month = null): array
    {
        $targetIds = $consolidated
            ? $this->getDescendantIds($institutionId, true)
            : [$institutionId];

        // Membresia
        $peopleQuery = Person::query()->whereIn('institution_id', $targetIds)->where('is_active', true);
        $totalMembers = (clone $peopleQuery)->count();
        $totalTithers = (clone $peopleQuery)->where('is_tither', true)->count();
        $totalTeachers = (clone $peopleQuery)->where('can_teach', true)->count();
        $totalSuperintendents = (clone $peopleQuery)->where('can_superintend', true)->count();

        // EBD Classes e Matrículas
        $totalClasses = DB::table('classes')->whereIn('institution_id', $targetIds)->whereNull('deleted_at')->count();
        $totalStudents = DB::table('class_students')
            ->join('classes', 'class_students.class_id', '=', 'classes.id')
            ->whereIn('classes.institution_id', $targetIds)
            ->where('class_students.is_active', true)
            ->count();

        // Financeiro Agregado (respeitando permissão de compartilhamento da instituição inferior)
        $financialIds = $consolidated
            ? Institution::whereIn('id', $targetIds)
                ->where(function ($q) use ($institutionId) {
                    $q->where('id', $institutionId)
                      ->orWhere('share_financials_with_parent', true);
                })
                ->pluck('id')
                ->all()
            : [$institutionId];

        $coletasQuery = DB::table('coletas_dizimos')
            ->whereIn('institution_id', $financialIds)
            ->where('status', 'Fechada')
            ->whereNull('deleted_at');

        if ($year) {
            $coletasQuery->whereYear('date', $year);
            if ($month) {
                $coletasQuery->whereMonth('date', $month);
            }
        }

        $totalRevenue = (float) (clone $coletasQuery)->sum('total_amount');
        $coletasCount = (clone $coletasQuery)->count();

        // Subordinadas diretas
        $directSubordinates = Institution::query()
            ->where('parent_institution_id', $institutionId)
            ->whereNull('deleted_at')
            ->count();

        $allSubordinates = count($targetIds) - 1;

        return [
            'institution_id' => $institutionId,
            'is_consolidated' => $consolidated,
            'subordinates_direct_count' => $directSubordinates,
            'subordinates_total_count' => max(0, $allSubordinates),
            'members' => [
                'total' => $totalMembers,
                'tithers' => $totalTithers,
                'teachers' => $totalTeachers,
                'superintendents' => $totalSuperintendents,
            ],
            'ebd' => [
                'classes_count' => $totalClasses,
                'students_count' => $totalStudents,
            ],
            'financial' => [
                'total_revenue' => $totalRevenue,
                'coletas_count' => $coletasCount,
            ],
        ];
    }

    /**
     * Detalhamento por filho direto (drilldown).
     */
    public function getDrilldownStats(int $institutionId, string $metric = 'members'): array
    {
        $directChildren = Institution::query()
            ->where('parent_institution_id', $institutionId)
            ->whereNull('deleted_at')
            ->orderBy('name')
            ->get();

        $items = [];

        // Inclui também a própria instituição para comparação
        $selfIds = [$institutionId];
        $items[] = [
            'institution_id' => $institutionId,
            'name' => '(Esta própria instituição)',
            'type' => 'própria',
            'value' => $this->getMetricValueForSubtree($selfIds, $metric),
        ];

        foreach ($directChildren as $child) {
            $descendantIds = $this->getDescendantIds($child->id, true);
            $value = $this->getMetricValueForSubtree($descendantIds, $metric);

            $items[] = [
                'institution_id' => $child->id,
                'name' => $child->name,
                'short_name' => $child->short_name,
                'type' => $child->type,
                'value' => $value,
                'has_children' => $child->children()->count() > 0,
            ];
        }

        return [
            'parent_institution_id' => $institutionId,
            'metric' => $metric,
            'items' => $items,
        ];
    }

    private function getMetricValueForSubtree(array $institutionIds, string $metric): mixed
    {
        return match ($metric) {
            'members' => Person::query()->whereIn('institution_id', $institutionIds)->where('is_active', true)->count(),
            'revenue' => (float) DB::table('coletas_dizimos')->whereIn('institution_id', $institutionIds)->where('status', 'Fechada')->sum('total_amount'),
            'ebd_students' => DB::table('class_students')->join('classes', 'class_students.class_id', '=', 'classes.id')->whereIn('classes.institution_id', $institutionIds)->where('class_students.is_active', true)->count(),
            'subordinates' => count($institutionIds) - 1,
            default => 0,
        };
    }

    /**
     * Arrecadação Domingo a Domingo (Culto a Culto) para uma instituição/subárvore.
     */
    public function getCultByCultRevenue(int $institutionId, bool $consolidated = true, int $limit = 12): array
    {
        $targetIds = $consolidated
            ? $this->getDescendantIds($institutionId, true)
            : [$institutionId];

        $coletas = DB::table('coletas_dizimos')
            ->select('date', 'service_meeting', DB::raw('SUM(total_amount) as total'), DB::raw('SUM(entry_count) as entries'))
            ->whereIn('institution_id', $targetIds)
            ->where('status', 'Fechada')
            ->whereNull('deleted_at')
            ->groupBy('date', 'service_meeting')
            ->orderBy('date', 'desc')
            ->limit($limit)
            ->get();

        return array_reverse(array_map(fn ($c) => [
            'date' => $c->date,
            'service_meeting' => $c->service_meeting ?? 'Culto Regular',
            'total_amount' => (float) $c->total,
            'entries_count' => (int) $c->entries,
        ], $coletas->toArray()));
    }

    /**
     * Transferência de instituição para novo pai + registro histórico.
     */
    public function transferParent(int $institutionId, ?int $newParentId, string $reason, int $userId): Institution
    {
        return DB::transaction(function () use ($institutionId, $newParentId, $reason, $userId) {
            $institution = Institution::findOrFail($institutionId);
            $oldParentId = $institution->parent_institution_id;

            // Evitar ciclos (novo pai não pode ser a própria instituição ou um descendente dela)
            if ($newParentId) {
                if ($newParentId === $institutionId) {
                    throw new \InvalidArgumentException('Uma instituição não pode ser pai de si mesma.');
                }
                $descendants = $this->getDescendantIds($institutionId, false);
                if (in_array($newParentId, $descendants, true)) {
                    throw new \InvalidArgumentException('Não é possível vincular uma instituição a uma das suas próprias subordinadas.');
                }
            }

            $institution->parent_institution_id = $newParentId;
            $institution->save();

            InstitutionTransfer::create([
                'institution_id' => $institutionId,
                'old_parent_id' => $oldParentId,
                'new_parent_id' => $newParentId,
                'transferred_by_user_id' => $userId,
                'reason' => $reason,
                'transferred_at' => now(),
            ]);

            $oldParentName = $oldParentId ? Institution::find($oldParentId)?->name : 'Nenhum';
            $newParentName = $newParentId ? Institution::find($newParentId)?->name : 'Nenhum';

            InstitutionHistory::create([
                'institution_id' => $institutionId,
                'event_type' => 'mudanca_superior',
                'title' => 'Transferência de Vinculo Hierárquico',
                'description' => "Vínculo alterado de [{$oldParentName}] para [{$newParentName}]. Motivo: {$reason}",
                'user_id' => $userId,
                'payload' => [
                    'old_parent_id' => $oldParentId,
                    'new_parent_id' => $newParentId,
                    'reason' => $reason,
                ],
            ]);

            return $institution;
        });
    }

    /**
     * Busca uma instituição pelo seu código único.
     */
    public function findByCode(string $code): ?Institution
    {
        $cleanCode = strtoupper(trim($code));
        return Institution::where('code', $cleanCode)->first();
    }

    /**
     * Inicia uma solicitação de vínculo (superior, inferior ou desvínculo) via código.
     */
    public function createLinkRequest(int $requesterId, string $targetCode, string $type, ?string $reason, int $userId): InstitutionLinkRequest
    {
        $target = $this->findByCode($targetCode);
        if (! $target) {
            throw new \InvalidArgumentException("Instituição com o código '{$targetCode}' não foi encontrada.");
        }

        if ($target->id === $requesterId) {
            throw new \InvalidArgumentException("Não é possível solicitar vínculo da instituição com ela mesma.");
        }

        if (! in_array($type, ['vinculo_superior', 'vinculo_inferior', 'desvinculo'], true)) {
            throw new \InvalidArgumentException("Tipo de solicitação inválido.");
        }

        // Verificar validações hierárquicas
        if ($type === 'vinculo_superior') {
            $descendants = $this->getDescendantIds($requesterId, false);
            if (in_array($target->id, $descendants, true)) {
                throw new \InvalidArgumentException("Não é possível vincular como superior uma instituição que já é sua subordinada.");
            }
        } elseif ($type === 'vinculo_inferior') {
            $descendants = $this->getDescendantIds($target->id, false);
            if (in_array($requesterId, $descendants, true)) {
                throw new \InvalidArgumentException("Não é possível vincular como inferior uma instituição que é sua própria superior.");
            }
        } elseif ($type === 'desvinculo') {
            $requester = Institution::findOrFail($requesterId);
            $isParent = ($requester->parent_institution_id === $target->id);
            $isChild = ($target->parent_institution_id === $requesterId);
            if (! $isParent && ! $isChild) {
                throw new \InvalidArgumentException("Não há vínculo ativo entre estas duas instituições para desvincular.");
            }
        }

        // Verificar se já existe solicitação pendente
        $existing = InstitutionLinkRequest::where('status', 'pendente')
            ->where(function ($q) use ($requesterId, $target) {
                $q->where(function ($q1) use ($requesterId, $target) {
                    $q1->where('requester_institution_id', $requesterId)
                       ->where('target_institution_id', $target->id);
                })->orWhere(function ($q2) use ($requesterId, $target) {
                    $q2->where('requester_institution_id', $target->id)
                       ->where('target_institution_id', $requesterId);
                });
            })->first();

        if ($existing) {
            throw new \InvalidArgumentException("Já existe uma solicitação de vínculo pendente entre estas duas instituições.");
        }

        return InstitutionLinkRequest::create([
            'requester_institution_id' => $requesterId,
            'target_institution_id' => $target->id,
            'type' => $type,
            'status' => 'pendente',
            'requested_by_user_id' => $userId,
            'reason' => $reason,
        ]);
    }

    /**
     * Lista solicitações de vínculo (recebidas e enviadas) para uma instituição.
     */
    public function getLinkRequests(int $institutionId, ?string $status = null): array
    {
        $receivedQuery = InstitutionLinkRequest::with(['requesterInstitution:id,name,short_name,type,code,city,state', 'requestedBy:id,name'])
            ->where('target_institution_id', $institutionId);

        $sentQuery = InstitutionLinkRequest::with(['targetInstitution:id,name,short_name,type,code,city,state', 'requestedBy:id,name'])
            ->where('requester_institution_id', $institutionId);

        if ($status) {
            $receivedQuery->where('status', $status);
            $sentQuery->where('status', $status);
        }

        return [
            'received' => $receivedQuery->orderBy('created_at', 'desc')->get(),
            'sent' => $sentQuery->orderBy('created_at', 'desc')->get(),
        ];
    }

    /**
     * Aceita uma solicitação de vínculo/desvínculo pendente.
     */
    public function acceptLinkRequest(int $requestId, int $userId, ?string $notes = null): InstitutionLinkRequest
    {
        return DB::transaction(function () use ($requestId, $userId, $notes) {
            $request = InstitutionLinkRequest::lockForUpdate()->findOrFail($requestId);

            if ($request->status !== 'pendente') {
                throw new \InvalidArgumentException("Esta solicitação já foi processada.");
            }

            $requester = Institution::findOrFail($request->requester_institution_id);
            $target = Institution::findOrFail($request->target_institution_id);

            if ($request->type === 'vinculo_superior') {
                $requester->parent_institution_id = $target->id;
                $requester->save();

                InstitutionHistory::create([
                    'institution_id' => $requester->id,
                    'event_type' => 'vinculo_aceito',
                    'title' => 'Vínculo Superior Aceito',
                    'description' => "Vínculo aceito com a instituição superior [{$target->name}].",
                    'user_id' => $userId,
                ]);

                InstitutionHistory::create([
                    'institution_id' => $target->id,
                    'event_type' => 'subordinada_adicionada',
                    'title' => 'Nova Subordinada Aceita',
                    'description' => "Vínculo aceito adicionando [{$requester->name}] como subordinada.",
                    'user_id' => $userId,
                ]);
            } elseif ($request->type === 'vinculo_inferior') {
                $target->parent_institution_id = $requester->id;
                $target->save();

                InstitutionHistory::create([
                    'institution_id' => $target->id,
                    'event_type' => 'vinculo_aceito',
                    'title' => 'Vínculo Superior Aceito',
                    'description' => "Vínculo aceito tornando [{$requester->name}] sua instituição superior.",
                    'user_id' => $userId,
                ]);

                InstitutionHistory::create([
                    'institution_id' => $requester->id,
                    'event_type' => 'subordinada_adicionada',
                    'title' => 'Nova Subordinada Aceita',
                    'description' => "Vínculo aceito adicionando [{$target->name}] como subordinada.",
                    'user_id' => $userId,
                ]);
            } elseif ($request->type === 'desvinculo') {
                if ($requester->parent_institution_id === $target->id) {
                    $requester->parent_institution_id = null;
                    $requester->save();
                } elseif ($target->parent_institution_id === $requester->id) {
                    $target->parent_institution_id = null;
                    $target->save();
                }

                InstitutionHistory::create([
                    'institution_id' => $requester->id,
                    'event_type' => 'desvinculo_aceito',
                    'title' => 'Desvinculação Aceita',
                    'description' => "Vínculo removido com [{$target->name}].",
                    'user_id' => $userId,
                ]);

                InstitutionHistory::create([
                    'institution_id' => $target->id,
                    'event_type' => 'desvinculo_aceito',
                    'title' => 'Desvinculação Aceita',
                    'description' => "Vínculo removido com [{$requester->name}].",
                    'user_id' => $userId,
                ]);
            }

            $request->update([
                'status' => 'aceita',
                'actioned_by_user_id' => $userId,
                'action_notes' => $notes,
                'actioned_at' => now(),
            ]);

            return $request->fresh(['requesterInstitution', 'targetInstitution', 'actionedBy']);
        });
    }

    /**
     * Recusa uma solicitação de vínculo/desvínculo.
     */
    public function rejectLinkRequest(int $requestId, int $userId, ?string $notes = null): InstitutionLinkRequest
    {
        $request = InstitutionLinkRequest::findOrFail($requestId);

        if ($request->status !== 'pendente') {
            throw new \InvalidArgumentException("Esta solicitação já foi processada.");
        }

        $request->update([
            'status' => 'recusada',
            'actioned_by_user_id' => $userId,
            'action_notes' => $notes,
            'actioned_at' => now(),
        ]);

        return $request->fresh(['requesterInstitution', 'targetInstitution', 'actionedBy']);
    }

    /**
     * Cancela uma solicitação enviada pelo solicitante.
     */
    public function cancelLinkRequest(int $requestId, int $userId): InstitutionLinkRequest
    {
        $request = InstitutionLinkRequest::findOrFail($requestId);

        if ($request->status !== 'pendente') {
            throw new \InvalidArgumentException("Somente solicitações pendentes podem ser canceladas.");
        }

        $request->update([
            'status' => 'cancelada',
            'actioned_by_user_id' => $userId,
            'actioned_at' => now(),
        ]);

        return $request->fresh(['requesterInstitution', 'targetInstitution']);
    }
}
