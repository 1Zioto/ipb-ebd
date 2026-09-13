<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Institution;
use App\Models\InstitutionHistory;
use App\Models\InstitutionLinkRequest;
use App\Services\InstitutionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InstitutionController extends Controller
{
    public function __construct(
        protected InstitutionService $institutionService
    ) {}

    /**
     * Lista/pesquisa de instituições respeitando a árvore permitida ao usuário.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $userInstId = $user->institution_id;

        $allowedIds = $user->hasGlobalInstitutionAccess()
            ? null
            : ($userInstId ? $this->institutionService->getDescendantIds($userInstId, true) : []);

        $query = Institution::query();

        if ($allowedIds !== null) {
            $query->whereIn('id', $allowedIds);
        }

        if ($search = $request->input('search')) {
            $term = trim($search);
            $query->where(function ($q) use ($term) {
                $q->where('name', 'like', "%{$term}%")
                    ->orWhere('short_name', 'like', "%{$term}%")
                    ->orWhere('code', 'like', "%{$term}%")
                    ->orWhere('cnpj', 'like', "%{$term}%")
                    ->orWhere('city', 'like', "%{$term}%")
                    ->orWhere('state', 'like', "%{$term}%")
                    ->orWhere('type', 'like', "%{$term}%");
            });
        }

        if ($type = $request->input('type')) {
            $query->where('type', $type);
        }

        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        if ($parentId = $request->input('parent_institution_id')) {
            $query->where('parent_institution_id', $parentId);
        }

        $institutions = $query->with('parent:id,name,short_name,type')
            ->orderBy('type')
            ->orderBy('name')
            ->paginate($request->input('per_page', 20));

        return response()->json($institutions);
    }

    /**
     * Árvore institucional completa em formato hierárquico aninhado.
     */
    public function tree(Request $request): JsonResponse
    {
        $user = $request->user();
        $rootId = $request->input('root_id')
            ? (int) $request->input('root_id')
            : ($user->hasGlobalInstitutionAccess() ? null : $user->institution_id);

        if ($rootId && ! $user->canAccessInstitution($rootId)) {
            return response()->json(['message' => 'Acesso não autorizado a esta árvore.'], 403);
        }

        $tree = $this->institutionService->getTree($rootId);

        return response()->json([
            'root_id' => $rootId,
            'tree' => $tree,
        ]);
    }

    /**
     * Cadastrar nova instituição.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:200',
            'short_name' => 'required|string|max:100',
            'type' => 'required|string|max:50',
            'cnpj' => 'nullable|string|max:20',
            'foundation_date' => 'nullable|date',
            'organization_date' => 'nullable|date',
            'status' => 'required|string|max:30',
            'parent_institution_id' => 'nullable|exists:institutions,id',
            'zipcode' => 'nullable|string|max:20',
            'street' => 'nullable|string|max:200',
            'number' => 'nullable|string|max:20',
            'complement' => 'nullable|string|max:100',
            'district' => 'nullable|string|max:100',
            'city' => 'nullable|string|max:100',
            'state' => 'nullable|string|max:50',
            'country' => 'nullable|string|max:50',
            'phone' => 'nullable|string|max:30',
            'whatsapp' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:180',
            'website' => 'nullable|string|max:255',
            'social_media' => 'nullable|array',
            'logo' => 'nullable|string|max:255',
            'fantasy_name' => 'nullable|string|max:200',
            'internal_code' => 'nullable|string|max:50',
            'denominational_code' => 'nullable|string|max:50',
            'notes' => 'nullable|string',
        ]);

        $user = $request->user();

        // Se o usuário não for programador e especificou um pai, verificar acesso
        if (isset($validated['parent_institution_id']) && ! $user->canAccessInstitution($validated['parent_institution_id'])) {
            return response()->json(['message' => 'Não é permitido vincular a uma instituição fora do seu escopo.'], 403);
        }

        $institution = Institution::create($validated);

        InstitutionHistory::create([
            'institution_id' => $institution->id,
            'event_type' => 'criacao',
            'title' => 'Instituição Cadastrada',
            'description' => "Instituição [{$institution->name}] tipo [{$institution->type}] criada com sucesso.",
            'user_id' => $user->id,
            'payload' => $validated,
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'INSTITUTION_CREATE',
            'entity_type' => 'Institution',
            'entity_id' => $institution->id,
            'new_values' => $validated,
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'message' => 'Instituição cadastrada com sucesso.',
            'data' => $institution->load('parent:id,name,short_name,type'),
        ], 201);
    }

    /**
     * Exibir detalhes de uma instituição.
     */
    public function show(Request $request, Institution $institution): JsonResponse
    {
        if (! $request->user()->canAccessInstitution($institution->id)) {
            return response()->json(['message' => 'Acesso não autorizado a esta instituição.'], 403);
        }

        $institution->load(['parent:id,name,short_name,type']);

        $breadcrumbs = $this->institutionService->getBreadcrumbs($institution->id);

        return response()->json([
            'data' => $institution,
            'breadcrumbs' => $breadcrumbs,
        ]);
    }

    /**
     * Atualizar dados da instituição.
     */
    public function update(Request $request, Institution $institution): JsonResponse
    {
        if (! $request->user()->canAccessInstitution($institution->id)) {
            return response()->json(['message' => 'Acesso não autorizado a esta instituição.'], 403);
        }

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:200',
            'short_name' => 'sometimes|required|string|max:100',
            'type' => 'sometimes|required|string|max:50',
            'cnpj' => 'nullable|string|max:20',
            'foundation_date' => 'nullable|date',
            'organization_date' => 'nullable|date',
            'status' => 'sometimes|required|string|max:30',
            'zipcode' => 'nullable|string|max:20',
            'street' => 'nullable|string|max:200',
            'number' => 'nullable|string|max:20',
            'complement' => 'nullable|string|max:100',
            'district' => 'nullable|string|max:100',
            'city' => 'nullable|string|max:100',
            'state' => 'nullable|string|max:50',
            'country' => 'nullable|string|max:50',
            'phone' => 'nullable|string|max:30',
            'whatsapp' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:180',
            'website' => 'nullable|string|max:255',
            'social_media' => 'nullable|array',
            'logo' => 'nullable|string|max:255',
            'fantasy_name' => 'nullable|string|max:200',
            'internal_code' => 'nullable|string|max:50',
            'denominational_code' => 'nullable|string|max:50',
            'share_financials_with_parent' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        $oldValues = $institution->toArray();
        $institution->update($validated);

        InstitutionHistory::create([
            'institution_id' => $institution->id,
            'event_type' => 'atualizacao',
            'title' => 'Cadastro Atualizado',
            'description' => 'Dados cadastrais atualizados.',
            'user_id' => $request->user()->id,
            'payload' => $validated,
        ]);

        AuditLog::create([
            'user_id' => $request->user()->id,
            'action' => 'INSTITUTION_UPDATE',
            'entity_type' => 'Institution',
            'entity_id' => $institution->id,
            'old_values' => $oldValues,
            'new_values' => $validated,
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'message' => 'Instituição atualizada com sucesso.',
            'data' => $institution->fresh(['parent:id,name,short_name,type']),
        ]);
    }

    /**
     * Inativar / Excluir instituição.
     */
    public function destroy(Request $request, Institution $institution): JsonResponse
    {
        if (! $request->user()->canAccessInstitution($institution->id)) {
            return response()->json(['message' => 'Acesso não autorizado a esta instituição.'], 403);
        }

        if ($institution->children()->whereNull('deleted_at')->exists()) {
            return response()->json([
                'message' => 'Não é possível excluir uma instituição que possui outras instituições subordinadas ativas.',
            ], 422);
        }

        $institution->delete();

        AuditLog::create([
            'user_id' => $request->user()->id,
            'action' => 'INSTITUTION_DELETE',
            'entity_type' => 'Institution',
            'entity_id' => $institution->id,
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json(['message' => 'Instituição removida com sucesso.']);
    }

    /**
     * Instituições subordinadas (lista com resumo métrico).
     */
    public function subordinates(Request $request, Institution $institution): JsonResponse
    {
        if (! $request->user()->canAccessInstitution($institution->id)) {
            return response()->json(['message' => 'Acesso não autorizado.'], 403);
        }

        $query = Institution::query()
            ->where('parent_institution_id', $institution->id)
            ->whereNull('deleted_at');

        $children = $query->orderBy('name')->get();

        $data = $children->map(function ($child) {
            $descendantIds = $this->institutionService->getDescendantIds($child->id, true);
            $stats = $this->institutionService->getConsolidatedStats($child->id, true);

            $isShared = (bool) $child->share_financials_with_parent;

            return [
                'id' => $child->id,
                'name' => $child->name,
                'short_name' => $child->short_name,
                'type' => $child->type,
                'status' => $child->status,
                'city' => $child->city,
                'state' => $child->state,
                'members_count' => $stats['members']['total'],
                'subordinates_count' => $stats['subordinates_total_count'],
                'share_financials_with_parent' => $isShared,
                'revenue_total' => $isShared ? $stats['financial']['total_revenue'] : null,
            ];
        });

        return response()->json([
            'parent_institution_id' => $institution->id,
            'subordinates' => $data,
        ]);
    }

    /**
     * Breadcrumbs para a instituição.
     */
    public function breadcrumbs(Request $request, Institution $institution): JsonResponse
    {
        if (! $request->user()->canAccessInstitution($institution->id)) {
            return response()->json(['message' => 'Acesso não autorizado.'], 403);
        }

        $breadcrumbs = $this->institutionService->getBreadcrumbs($institution->id);

        return response()->json($breadcrumbs);
    }

    /**
     * Transferência de instituição superior.
     */
    public function transfer(Request $request, Institution $institution): JsonResponse
    {
        if (! $request->user()->canAccessInstitution($institution->id)) {
            return response()->json(['message' => 'Acesso não autorizado.'], 403);
        }

        $validated = $request->validate([
            'new_parent_id' => 'nullable|exists:institutions,id',
            'reason' => 'required|string|min:5',
        ]);

        try {
            $updated = $this->institutionService->transferParent(
                $institution->id,
                $validated['new_parent_id'] ?? null,
                $validated['reason'],
                $request->user()->id
            );

            return response()->json([
                'message' => 'Vínculo hierárquico transferido com sucesso.',
                'data' => $updated->load('parent:id,name,short_name,type'),
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Histórico de eventos da instituição.
     */
    public function history(Request $request, Institution $institution): JsonResponse
    {
        if (! $request->user()->canAccessInstitution($institution->id)) {
            return response()->json(['message' => 'Acesso não autorizado.'], 403);
        }

        $history = InstitutionHistory::query()
            ->where('institution_id', $institution->id)
            ->with('user:id,name')
            ->orderBy('created_at', 'desc')
            ->paginate($request->input('per_page', 15));

        return response()->json($history);
    }

    /**
     * Resumo de indicadores do Dashboard (Somente Esta vs Consolidado).
     */
    public function dashboardSummary(Request $request, Institution $institution): JsonResponse
    {
        if (! $request->user()->canAccessInstitution($institution->id)) {
            return response()->json(['message' => 'Acesso não autorizado.'], 403);
        }

        $consolidated = filter_var($request->input('consolidated', true), FILTER_VALIDATE_BOOLEAN);
        $year = $request->input('year') ? (int) $request->input('year') : null;
        $month = $request->input('month') ? (int) $request->input('month') : null;

        $stats = $this->institutionService->getConsolidatedStats($institution->id, $consolidated, $year, $month);

        return response()->json($stats);
    }

    /**
     * Detalhamento para navegação pelos números (drilldown).
     */
    public function dashboardDrilldown(Request $request, Institution $institution): JsonResponse
    {
        if (! $request->user()->canAccessInstitution($institution->id)) {
            return response()->json(['message' => 'Acesso não autorizado.'], 403);
        }

        $metric = $request->input('metric', 'members');
        $drilldown = $this->institutionService->getDrilldownStats($institution->id, $metric);

        return response()->json($drilldown);
    }

    /**
     * Arrecadação por culto (domingo a domingo).
     */
    public function cultByCult(Request $request, Institution $institution): JsonResponse
    {
        if (! $request->user()->canAccessInstitution($institution->id)) {
            return response()->json(['message' => 'Acesso não autorizado.'], 403);
        }

        $consolidated = filter_var($request->input('consolidated', true), FILTER_VALIDATE_BOOLEAN);
        $limit = (int) $request->input('limit', 12);

        $evolution = $this->institutionService->getCultByCultRevenue($institution->id, $consolidated, $limit);

        return response()->json($evolution);
    }

    /**
     * Consulta instituição por código único.
     */
    public function lookupCode(Request $request, string $code): JsonResponse
    {
        $institution = $this->institutionService->findByCode($code);

        if (! $institution) {
            return response()->json(['message' => 'Instituição não encontrada com o código fornecido.'], 404);
        }

        return response()->json([
            'data' => [
                'id' => $institution->id,
                'name' => $institution->name,
                'short_name' => $institution->short_name,
                'type' => $institution->type,
                'code' => $institution->code,
                'city' => $institution->city,
                'state' => $institution->state,
                'status' => $institution->status,
                'parent_institution_id' => $institution->parent_institution_id,
            ],
        ]);
    }

    /**
     * Lista solicitações de vínculo/desvínculo da instituição.
     */
    public function indexLinkRequests(Request $request): JsonResponse
    {
        $user = $request->user();
        $institutionId = $request->input('institution_id')
            ? (int) $request->input('institution_id')
            : $user->institution_id;

        if (! $institutionId) {
            return response()->json(['message' => 'Nenhuma instituição selecionada no contexto.'], 422);
        }

        if (! $user->canAccessInstitution($institutionId)) {
            return response()->json(['message' => 'Acesso não autorizado.'], 403);
        }

        $status = $request->input('status');
        $data = $this->institutionService->getLinkRequests($institutionId, $status);

        return response()->json($data);
    }

    /**
     * Cria nova solicitação de vínculo/desvínculo por código.
     */
    public function storeLinkRequest(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'requester_institution_id' => 'nullable|exists:institutions,id',
            'target_code' => 'required|string|max:30',
            'type' => 'required|string|in:vinculo_superior,vinculo_inferior,desvinculo',
            'reason' => 'nullable|string|max:500',
        ]);

        $user = $request->user();
        $requesterId = $validated['requester_institution_id'] ?? $user->institution_id;

        if (! $requesterId) {
            return response()->json(['message' => 'Instituição solicitante não especificada.'], 422);
        }

        if (! $user->canAccessInstitution($requesterId)) {
            return response()->json(['message' => 'Não é permitido criar solicitações em nome desta instituição.'], 403);
        }

        try {
            $linkRequest = $this->institutionService->createLinkRequest(
                $requesterId,
                $validated['target_code'],
                $validated['type'],
                $validated['reason'] ?? null,
                $user->id
            );

            return response()->json([
                'message' => 'Solicitação de vínculo enviada com sucesso. Aguardando aceite da instituição destino.',
                'data' => $linkRequest->load(['targetInstitution:id,name,type,code']),
            ], 201);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Aceitar solicitação de vínculo/desvínculo.
     */
    public function acceptLinkRequest(Request $request, InstitutionLinkRequest $linkRequest): JsonResponse
    {
        $user = $request->user();

        if (! $user->canAccessInstitution($linkRequest->target_institution_id)) {
            return response()->json(['message' => 'Somente a instituição destino pode aceitar esta solicitação.'], 403);
        }

        $validated = $request->validate([
            'action_notes' => 'nullable|string|max:500',
        ]);

        try {
            $updated = $this->institutionService->acceptLinkRequest(
                $linkRequest->id,
                $user->id,
                $validated['action_notes'] ?? null
            );

            return response()->json([
                'message' => 'Solicitação de vínculo aceita com sucesso.',
                'data' => $updated,
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Recusar solicitação de vínculo/desvínculo.
     */
    public function rejectLinkRequest(Request $request, InstitutionLinkRequest $linkRequest): JsonResponse
    {
        $user = $request->user();

        if (! $user->canAccessInstitution($linkRequest->target_institution_id)) {
            return response()->json(['message' => 'Somente a instituição destino pode recusar esta solicitação.'], 403);
        }

        $validated = $request->validate([
            'action_notes' => 'nullable|string|max:500',
        ]);

        try {
            $updated = $this->institutionService->rejectLinkRequest(
                $linkRequest->id,
                $user->id,
                $validated['action_notes'] ?? null
            );

            return response()->json([
                'message' => 'Solicitação de vínculo recusada.',
                'data' => $updated,
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Cancelar solicitação enviada.
     */
    public function cancelLinkRequest(Request $request, InstitutionLinkRequest $linkRequest): JsonResponse
    {
        $user = $request->user();

        if (! $user->canAccessInstitution($linkRequest->requester_institution_id)) {
            return response()->json(['message' => 'Somente a instituição solicitante pode cancelar esta solicitação.'], 403);
        }

        try {
            $updated = $this->institutionService->cancelLinkRequest($linkRequest->id, $user->id);

            return response()->json([
                'message' => 'Solicitação de vínculo cancelada.',
                'data' => $updated,
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }
}
