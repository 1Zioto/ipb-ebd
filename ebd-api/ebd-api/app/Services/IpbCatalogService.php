<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\Institution;
use App\Models\InstitutionHistory;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

class IpbCatalogService
{
    protected static ?array $cachedData = null;

    /**
     * Retorna a lista completa de igrejas do catálogo oficial IPB.
     */
    public function getCatalog(): array
    {
        if (static::$cachedData !== null) {
            return static::$cachedData;
        }

        $possiblePaths = [
            storage_path('app/catalogo_ipb.json'),
            database_path('data/catalogo_ipb.json'),
            base_path('../../igrejas_ipb.json'),
        ];

        foreach ($possiblePaths as $path) {
            if (File::exists($path)) {
                $content = json_decode(File::get($path), true);
                if (! empty($content['igrejas'])) {
                    static::$cachedData = $content['igrejas'];
                    return static::$cachedData;
                }
            }
        }

        return [];
    }

    /**
     * Pesquisa igrejas no catálogo oficial da IPB.
     */
    public function search(array $filters = []): array
    {
        $all = $this->getCatalog();

        $query = trim($filters['q'] ?? '');
        $uf = strtoupper(trim($filters['uf'] ?? ''));
        $cidade = trim($filters['cidade'] ?? '');
        $presbiterio = trim($filters['presbiterio'] ?? '');
        $tipo = trim($filters['tipo'] ?? '');

        $page = max(1, (int) ($filters['page'] ?? 1));
        $perPage = min(100, max(5, (int) ($filters['per_page'] ?? 25)));

        $filtered = array_filter($all, function ($item) use ($query, $uf, $cidade, $presbiterio, $tipo) {
            if ($uf && strtoupper($item['uf'] ?? '') !== $uf) {
                return false;
            }

            if ($tipo && ($item['tipo'] ?? '') !== $tipo) {
                return false;
            }

            if ($cidade && ! Str::contains(mb_strtolower($item['cidade'] ?? ''), mb_strtolower($cidade))) {
                return false;
            }

            if ($presbiterio) {
                $pNome = mb_strtolower($item['presbiterio_nome'] ?? '');
                $pSigla = mb_strtolower($item['presbiterio_sigla'] ?? '');
                $pTerm = mb_strtolower($presbiterio);
                if (! Str::contains($pNome, $pTerm) && ! Str::contains($pSigla, $pTerm)) {
                    return false;
                }
            }

            if ($query) {
                $term = mb_strtolower($query);
                $searchable = mb_strtolower(
                    ($item['id'] ?? '') . ' ' .
                    ($item['nome'] ?? '') . ' ' .
                    ($item['cidade'] ?? '') . ' ' .
                    ($item['uf'] ?? '') . ' ' .
                    ($item['bairro'] ?? '') . ' ' .
                    ($item['presbiterio_nome'] ?? '') . ' ' .
                    ($item['presbiterio_sigla'] ?? '') . ' ' .
                    ($item['sinodo_nome'] ?? '') . ' ' .
                    ($item['sinodo_sigla'] ?? '') . ' ' .
                    ($item['cep'] ?? '')
                );

                if (! Str::contains($searchable, $term)) {
                    return false;
                }
            }

            return true;
        });

        // Reindexar array
        $filtered = array_values($filtered);
        $total = count($filtered);
        $lastPage = (int) ceil($total / $perPage) ?: 1;
        $offset = ($page - 1) * $perPage;
        $items = array_slice($filtered, $offset, $perPage);

        return [
            'data' => $items,
            'total' => $total,
            'current_page' => $page,
            'per_page' => $perPage,
            'last_page' => $lastPage,
        ];
    }

    /**
     * Encontra uma igreja pelo seu ID oficial da IPB.
     */
    public function find(int $id): ?array
    {
        $all = $this->getCatalog();
        foreach ($all as $item) {
            if ((int) ($item['id'] ?? 0) === $id) {
                return $item;
            }
        }
        return null;
    }

    /**
     * Vincula uma instituição existente aos dados canônicos oficiais da IPB.
     * Cria ou localiza o Supremo Concílio, Sínodo e Presbitério correspondentes,
     * e ajusta o parent_institution_id da igreja para o Presbitério correto.
     */
    public function vincular(Institution $institution, int $catalogoId, ?int $userId = null): Institution
    {
        $item = $this->find($catalogoId);

        if (! $item) {
            throw new \InvalidArgumentException("Igreja não encontrada no catálogo oficial da IPB (ID: {$catalogoId}).");
        }

        // 1. Supremo Concílio
        $supremo = Institution::firstOrCreate(
            ['type' => 'supremo_concilio'],
            [
                'name' => 'Supremo Concílio da Igreja Presbiteriana do Brasil',
                'short_name' => 'SC-IPB',
                'status' => 'ativa',
                'city' => 'Brasília',
                'state' => 'DF',
                'country' => 'Brasil',
            ]
        );

        // 2. Sínodo
        $sinodoNome = $item['sinodo_nome'] ?: ($item['sinodo_sigla'] ? 'Sínodo ' . $item['sinodo_sigla'] : 'Sínodo');
        $sinodoSigla = $item['sinodo_sigla'] ?: 'SÍNODO';

        $sinodo = Institution::where('type', 'sinodo')
            ->where(function ($q) use ($sinodoNome, $sinodoSigla) {
                $q->where('name', $sinodoNome)
                    ->orWhere('short_name', $sinodoSigla);
            })
            ->first();

        if (! $sinodo) {
            $sinodo = Institution::create([
                'name' => $sinodoNome,
                'short_name' => $sinodoSigla,
                'type' => 'sinodo',
                'status' => 'ativa',
                'parent_institution_id' => $supremo->id,
                'state' => $item['uf'] ?? 'ES',
                'country' => 'Brasil',
                'denominational_code' => $item['sinodo_id'] ? (string) $item['sinodo_id'] : null,
            ]);
        } else {
            // Garante vínculo ao Supremo
            if (! $sinodo->parent_institution_id) {
                $sinodo->parent_institution_id = $supremo->id;
                $sinodo->save();
            }
        }

        // 3. Presbitério
        $presbNome = $item['presbiterio_nome'] ?: ($item['presbiterio_sigla'] ? 'Presbitério ' . $item['presbiterio_sigla'] : 'Presbitério');
        $presbSigla = $item['presbiterio_sigla'] ?: 'PRESB';

        $presbiterio = Institution::where('type', 'presbiterio')
            ->where(function ($q) use ($presbNome, $presbSigla) {
                $q->where('name', $presbNome)
                    ->orWhere('short_name', $presbSigla);
            })
            ->first();

        if (! $presbiterio) {
            $presbiterio = Institution::create([
                'name' => $presbNome,
                'short_name' => $presbSigla,
                'type' => 'presbiterio',
                'status' => 'ativa',
                'parent_institution_id' => $sinodo->id,
                'city' => $item['cidade'] ?? null,
                'state' => $item['uf'] ?? 'ES',
                'country' => 'Brasil',
                'denominational_code' => $item['presbiterio_id'] ? (string) $item['presbiterio_id'] : null,
            ]);
        } else {
            // Garante vínculo ao Sínodo
            if ($presbiterio->parent_institution_id !== $sinodo->id) {
                $presbiterio->parent_institution_id = $sinodo->id;
                $presbiterio->save();
            }
        }

        // 4. Atualizar os dados da instituição
        $oldValues = $institution->only([
            'name', 'short_name', 'type', 'parent_institution_id', 'city', 'state', 'district', 'street', 'zipcode', 'denominational_code'
        ]);

        $institution->name = $item['nome'];
        $institution->type = $item['tipo'];
        $institution->parent_institution_id = $presbiterio->id;
        $institution->denominational_code = (string) $item['id'];
        $institution->city = $item['cidade'] ?: $institution->city;
        $institution->state = $item['uf'] ?: $institution->state;
        if (! empty($item['bairro'])) {
            $institution->district = $item['bairro'];
        }
        if (! empty($item['endereco'])) {
            $institution->street = $item['endereco'];
        }
        if (! empty($item['cep'])) {
            $institution->zipcode = $item['cep'];
        }
        if (! empty($item['email']) && empty($institution->email)) {
            $institution->email = $item['email'];
        }
        if (! empty($item['site']) && empty($institution->website)) {
            $institution->website = $item['site'];
        }
        if (! empty($item['telefone']) && empty($institution->phone)) {
            $institution->phone = $item['telefone'];
        }
        if (! empty($item['data_organizacao'])) {
            $institution->organization_date = $item['data_organizacao'];
        }

        $institution->save();

        // 5. Histórico e Auditoria
        InstitutionHistory::create([
            'institution_id' => $institution->id,
            'user_id' => $userId,
            'event_type' => 'vinculo',
            'title' => 'Vínculo Oficial com Catálogo IPB',
            'description' => "Instituição vinculada à igreja oficial '{$item['nome']}' (ID: {$item['id']}), sob a jurisdição do {$presbNome} ({$presbSigla}) e do {$sinodoNome} ({$sinodoSigla}).",
            'payload' => [
                'catalogo_id' => $item['id'],
                'presbiterio_id' => $presbiterio->id,
                'presbiterio_nome' => $presbNome,
                'sinodo_id' => $sinodo->id,
                'sinodo_nome' => $sinodoNome,
                'antigos' => $oldValues,
            ],
        ]);

        if ($userId) {
            AuditLog::create([
                'user_id' => $userId,
                'action' => 'INSTITUTION_LINK_IPB_CATALOG',
                'entity_type' => 'Institution',
                'entity_id' => $institution->id,
                'old_values' => $oldValues,
                'new_values' => [
                    'catalogo_id' => $item['id'],
                    'name' => $item['nome'],
                    'parent_institution_id' => $presbiterio->id,
                ],
            ]);
        }

        return $institution->load(['parent.parent', 'parent:id,name,short_name,type,parent_institution_id']);
    }

    /**
     * Importa uma igreja do catálogo oficial criando uma nova instituição no sistema.
     */
    public function importar(int $catalogoId, ?int $userId = null): Institution
    {
        $item = $this->find($catalogoId);

        if (! $item) {
            throw new \InvalidArgumentException("Igreja não encontrada no catálogo oficial da IPB (ID: {$catalogoId}).");
        }

        // Verifica se já existe instituição com este denominational_code
        $existing = Institution::where('denominational_code', (string) $item['id'])->first();
        if ($existing) {
            return $this->vincular($existing, $catalogoId, $userId);
        }

        $shortName = $item['tipo'] === 'congregacao'
            ? 'Cong. ' . ($item['bairro'] ?: $item['cidade'])
            : 'IP ' . ($item['bairro'] ?: $item['cidade']);

        $institution = new Institution([
            'name' => $item['nome'],
            'short_name' => $shortName,
            'type' => $item['tipo'],
            'status' => 'ativa',
            'city' => $item['cidade'],
            'state' => $item['uf'],
            'country' => 'Brasil',
        ]);

        return $this->vincular($institution, $catalogoId, $userId);
    }
}
