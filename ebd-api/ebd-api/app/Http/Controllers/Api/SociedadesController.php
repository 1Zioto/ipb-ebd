<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Person;
use App\Models\SociedadeAtividade;
use App\Models\SociedadeAta;
use App\Models\SociedadeDiretoria;
use App\Models\SociedadeInterna;
use App\Models\SociedadeMembro;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SociedadesController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $institutionId = $request->user()?->institution_id ?? 5;

        $sociedades = SociedadeInterna::query()
            ->where('institution_id', $institutionId)
            ->with([
                'diretorias.person:id,full_name',
                'atividades' => fn ($q) => $q->orderBy('data', 'asc')->take(3),
                'membros.person:id,full_name,gender,birth_date,canonical_status',
            ])
            ->withCount(['membros', 'atas'])
            ->orderBy('id', 'asc')
            ->get();

        // Anexa indicadores calculados para cada sociedade
        $sociedades->each(function ($soc) {
            $membrosAtivos = $soc->membros->where('status', 'ativo');
            $dentroFaixa = 0;
            $acimaFaixa = 0;
            $abaixoFaixa = 0;
            $foraGenero = 0;
            $semNascimento = 0;

            foreach ($membrosAtivos as $m) {
                $eval = $soc->evaluateEligibility($m->person);
                match ($eval['status']) {
                    'dentro' => $dentroFaixa++,
                    'acima_faixa' => $acimaFaixa++,
                    'abaixo_faixa' => $abaixoFaixa++,
                    'fora_genero' => $foraGenero++,
                    'sem_nascimento' => $semNascimento++,
                    default => null,
                };
            }

            $soc->setAttribute('indicadores', [
                'total_socios' => $soc->membros->count(),
                'socios_ativos' => $membrosAtivos->count(),
                'dentro_faixa' => $dentroFaixa,
                'acima_faixa' => $acimaFaixa,
                'abaixo_faixa' => $abaixoFaixa,
                'fora_genero' => $foraGenero,
                'sem_nascimento' => $semNascimento,
                'fora_da_faixa' => ($acimaFaixa + $abaixoFaixa + $foraGenero),
            ]);
        });

        // Contagens potenciais gerais no rol da igreja
        $pessoas = Person::where('institution_id', $institutionId)
            ->where('is_active', true)
            ->where('canonical_status', '!=', 'falecido')
            ->get();

        $counts = [];
        foreach ($sociedades as $soc) {
            $counts[$soc->sigla] = $pessoas->filter(function ($p) use ($soc) {
                $eval = $soc->evaluateEligibility($p);
                return $eval['is_eligible'];
            })->count();
        }

        return response()->json([
            'sociedades' => $sociedades,
            'membros_potenciais' => $counts,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'sigla' => 'required|string|max:20',
            'nome' => 'required|string|max:120',
            'lema' => 'nullable|string|max:255',
            'faixa_etaria' => 'nullable|string|max:80',
            'target_gender' => 'nullable|in:Masculino,Feminino,Ambos',
            'min_age' => 'nullable|integer|min:0|max:150',
            'max_age' => 'nullable|integer|min:0|max:150',
            'is_active' => 'nullable|boolean',
            'notes' => 'nullable|string',
            'ano_exercicio' => 'nullable|integer',
            'financial_cost_center_id' => 'nullable|exists:financial_cost_centers,id',
        ]);

        if (isset($validated['min_age'], $validated['max_age']) && $validated['min_age'] !== null && $validated['max_age'] !== null) {
            if ($validated['min_age'] > $validated['max_age']) {
                return response()->json([
                    'message' => 'A idade mínima não pode ser superior à idade máxima.',
                    'errors' => ['min_age' => ['A idade mínima não pode ser maior que a máxima.']],
                ], 422);
            }
        }

        $validated['institution_id'] = $request->user()?->institution_id ?? 5;
        $validated['ano_exercicio'] = $validated['ano_exercicio'] ?? date('Y');
        $validated['sigla'] = strtoupper(trim($validated['sigla']));
        $validated['target_gender'] = $validated['target_gender'] ?? 'Ambos';
        $validated['is_active'] = $validated['is_active'] ?? true;

        $sociedade = SociedadeInterna::create($validated);

        return response()->json($sociedade->load('costCenter'), 201);
    }

    public function update(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'sigla' => 'sometimes|required|string|max:20',
            'nome' => 'sometimes|required|string|max:120',
            'lema' => 'nullable|string|max:255',
            'faixa_etaria' => 'nullable|string|max:80',
            'target_gender' => 'nullable|in:Masculino,Feminino,Ambos',
            'min_age' => 'nullable|integer|min:0|max:150',
            'max_age' => 'nullable|integer|min:0|max:150',
            'is_active' => 'nullable|boolean',
            'notes' => 'nullable|string',
            'ano_exercicio' => 'nullable|integer',
            'financial_cost_center_id' => 'nullable|exists:financial_cost_centers,id',
        ]);

        $minAge = array_key_exists('min_age', $validated) ? $validated['min_age'] : $sociedade->min_age;
        $maxAge = array_key_exists('max_age', $validated) ? $validated['max_age'] : $sociedade->max_age;

        if ($minAge !== null && $maxAge !== null && $minAge > $maxAge) {
            return response()->json([
                'message' => 'A idade mínima não pode ser superior à idade máxima.',
                'errors' => ['min_age' => ['A idade mínima não pode ser maior que a máxima.']],
            ], 422);
        }

        if (isset($validated['sigla'])) {
            $validated['sigla'] = strtoupper(trim($validated['sigla']));
        }

        $sociedade->update($validated);

        return response()->json($sociedade->load('costCenter'));
    }

    public function destroy(SociedadeInterna $sociedade): JsonResponse
    {
        $sociedade->delete();
        return response()->json(['message' => 'Sociedade interna excluída com sucesso.']);
    }

    public function show(SociedadeInterna $sociedade): JsonResponse
    {
        $sociedade->load([
            'diretorias.person:id,full_name,phone,email',
            'atividades' => fn ($q) => $q->orderBy('data', 'desc'),
            'membros.person:id,full_name,phone,email,canonical_status,birth_date,gender',
            'atas.presidente:id,full_name',
            'atas.secretario:id,full_name',
            'costCenter:id,code,name',
        ]);

        // Calcula os indicadores atuais da sociedade
        $membrosAtivos = $sociedade->membros->where('status', 'ativo');
        $dentroFaixa = 0;
        $acimaFaixa = 0;
        $abaixoFaixa = 0;
        $foraGenero = 0;
        $semNascimento = 0;

        foreach ($membrosAtivos as $m) {
            $eval = $sociedade->evaluateEligibility($m->person);
            match ($eval['status']) {
                'dentro' => $dentroFaixa++,
                'acima_faixa' => $acimaFaixa++,
                'abaixo_faixa' => $abaixoFaixa++,
                'fora_genero' => $foraGenero++,
                'sem_nascimento' => $semNascimento++,
                default => null,
            };
        }

        $sociedade->setAttribute('indicadores', [
            'total_socios' => $sociedade->membros->count(),
            'socios_ativos' => $membrosAtivos->count(),
            'dentro_faixa' => $dentroFaixa,
            'acima_faixa' => $acimaFaixa,
            'abaixo_faixa' => $abaixoFaixa,
            'fora_genero' => $foraGenero,
            'sem_nascimento' => $semNascimento,
            'fora_da_faixa' => ($acimaFaixa + $abaixoFaixa + $foraGenero),
        ]);

        return response()->json($sociedade);
    }

    // ==========================================
    // 👥 ROL DE SÓCIOS / MEMBROS DA SOCIEDADE
    // ==========================================

    public function getMembros(SociedadeInterna $sociedade): JsonResponse
    {
        $membros = $sociedade->membros()
            ->with('person:id,full_name,phone,email,canonical_status,birth_date,gender,is_active')
            ->orderBy('tipo_socio', 'asc')
            ->orderBy('id', 'asc')
            ->get();

        $dentroFaixa = 0;
        $acimaFaixa = 0;
        $abaixoFaixa = 0;
        $foraGenero = 0;
        $semNascimento = 0;

        // Anexa avaliação de elegibilidade dinâmica em cada membro
        $membros->each(function ($m) use ($sociedade, &$dentroFaixa, &$acimaFaixa, &$abaixoFaixa, &$foraGenero, &$semNascimento) {
            $eval = $sociedade->evaluateEligibility($m->person);
            $m->setAttribute('elegibilidade', $eval);

            if ($m->status === 'ativo') {
                match ($eval['status']) {
                    'dentro' => $dentroFaixa++,
                    'acima_faixa' => $acimaFaixa++,
                    'abaixo_faixa' => $abaixoFaixa++,
                    'fora_genero' => $foraGenero++,
                    'sem_nascimento' => $semNascimento++,
                    default => null,
                };
            }
        });

        $ativosCount = $membros->where('status', 'ativo')->count();

        return response()->json([
            'sociedade_id' => $sociedade->id,
            'total' => $membros->count(),
            'ativos' => $ativosCount,
            'inativos' => $membros->where('status', 'inativo')->count(),
            'efetivos' => $membros->where('tipo_socio', 'efetivo')->count(),
            'cooperadores' => $membros->where('tipo_socio', 'cooperador')->count(),
            'indicadores' => [
                'total_socios' => $membros->count(),
                'socios_ativos' => $ativosCount,
                'dentro_faixa' => $dentroFaixa,
                'acima_faixa' => $acimaFaixa,
                'abaixo_faixa' => $abaixoFaixa,
                'fora_genero' => $foraGenero,
                'sem_nascimento' => $semNascimento,
                'fora_da_faixa' => ($acimaFaixa + $abaixoFaixa + $foraGenero),
            ],
            'data' => $membros,
        ]);
    }

    /**
     * Retorna os candidatos a arrolamento com suporte a filtros dinâmicos e temporários.
     * Não altera as configurações cadastradas da sociedade.
     */
    public function candidatosArrolamento(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $institutionId = $sociedade->institution_id;

        // Filtros temporários (defaults obtidos da sociedade)
        $targetGender = $request->input('target_gender', $sociedade->target_gender ?? 'Ambos');
        $minAge = $request->filled('min_age') ? (int) $request->input('min_age') : $sociedade->min_age;
        $maxAge = $request->filled('max_age') ? (int) $request->input('max_age') : $sociedade->max_age;
        $search = trim((string) $request->input('search', ''));
        $situacaoCadastral = $request->input('situacao_cadastral', 'ativo'); // 'ativo', 'inativo', 'todos'
        $situacaoSociedade = $request->input('situacao_sociedade', 'nao_arrolado'); // 'nao_arrolado', 'ja_arrolado', 'todos'
        $apenasElegiveis = $request->boolean('apenas_elegiveis', false);

        // IDs dos membros com vínculo ativo na sociedade
        $jaArroladosIds = SociedadeMembro::where('sociedade_id', $sociedade->id)
            ->where('status', 'ativo')
            ->pluck('person_id')
            ->all();

        $query = Person::where('institution_id', $institutionId);

        // Situação cadastral na igreja
        if ($situacaoCadastral === 'ativo') {
            $query->where('is_active', true)->where('canonical_status', '!=', 'falecido');
        } elseif ($situacaoCadastral === 'inativo') {
            $query->where(function ($q) {
                $q->where('is_active', false)->orWhere('canonical_status', 'falecido');
            });
        }

        // Busca textual
        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('full_name', 'ilike', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('email', 'ilike', "%{$search}%")
                    ->orWhere('cpf', 'like', "%{$search}%");
            });
        }

        $pessoas = $query->orderBy('full_name', 'asc')->get();

        // Filtro em memória para cálculo exato de idade e compatibilidade de gênero
        $candidatos = $pessoas->map(function ($p) use ($sociedade, $jaArroladosIds, $targetGender, $minAge, $maxAge) {
            $age = $p->age;
            $jaArrolado = in_array($p->id, $jaArroladosIds, true);

            // Elegibilidade oficial contra os parâmetros da SOCIEDADE
            $evalOficial = $sociedade->evaluateEligibility($p);

            // Elegibilidade contra os FILTROS ATUAIS DA BUSCA
            $reasons = [];
            $statusFiltro = 'dentro';

            if ($targetGender !== 'Ambos' && !empty($p->gender) && strcasecmp($p->gender, $targetGender) !== 0) {
                $reasons[] = "Gênero diferente do filtro ({$p->gender})";
                $statusFiltro = 'fora_genero';
            }

            if ($age === null) {
                $reasons[] = 'Data de nascimento não informada';
                if ($statusFiltro === 'dentro') {
                    $statusFiltro = 'sem_nascimento';
                }
            } else {
                if ($minAge !== null && $age < $minAge) {
                    $reasons[] = "Idade ({$age}) abaixo do filtro ({$minAge})";
                    $statusFiltro = 'abaixo_faixa';
                } elseif ($maxAge !== null && $age > $maxAge) {
                    $reasons[] = "Idade ({$age}) acima do filtro ({$maxAge})";
                    $statusFiltro = 'acima_faixa';
                }
            }

            return [
                'id' => $p->id,
                'full_name' => $p->full_name,
                'gender' => $p->gender,
                'birth_date' => $p->birth_date?->format('Y-m-d'),
                'age' => $age,
                'phone' => $p->phone,
                'email' => $p->email,
                'canonical_status' => $p->canonical_status,
                'is_active' => $p->is_active,
                'ja_arrolado' => $jaArrolado,
                'elegibilidade' => $evalOficial,
                'compativel_com_filtro' => empty($reasons),
                'filtro_status' => $statusFiltro,
            ];
        });

        // Aplica os filtros da busca
        $candidatos = $candidatos->filter(function ($item) use ($situacaoSociedade, $targetGender, $minAge, $maxAge, $apenasElegiveis, $search) {
            // Situação na sociedade
            if ($situacaoSociedade === 'nao_arrolado' && $item['ja_arrolado']) {
                return false;
            }
            if ($situacaoSociedade === 'ja_arrolado' && !$item['ja_arrolado']) {
                return false;
            }

            // Se for busca nominal livre sem filtro etário explícito, permitir ver pessoas sem data de nascimento
            if ($search !== '' && $minAge === null && $maxAge === null && $targetGender === 'Ambos') {
                return true;
            }

            // Filtro de gênero
            if ($targetGender !== 'Ambos' && !empty($item['gender']) && strcasecmp($item['gender'], $targetGender) !== 0) {
                return false;
            }

            // Filtro de idade estrito se definido
            $age = $item['age'];
            if ($minAge !== null || $maxAge !== null) {
                if ($age === null) {
                    // Sem data de nascimento não passa em filtro etário estrito automático, a menos que haja busca nominal direta
                    return $search !== '';
                }
                if ($minAge !== null && $age < $minAge) {
                    return false;
                }
                if ($maxAge !== null && $age > $maxAge) {
                    return false;
                }
            }

            if ($apenasElegiveis && !$item['elegibilidade']['is_eligible']) {
                return false;
            }

            return true;
        })->values();

        return response()->json([
            'sociedade' => [
                'id' => $sociedade->id,
                'sigla' => $sociedade->sigla,
                'nome' => $sociedade->nome,
                'target_gender' => $sociedade->target_gender,
                'min_age' => $sociedade->min_age,
                'max_age' => $sociedade->max_age,
            ],
            'filtros_aplicados' => [
                'target_gender' => $targetGender,
                'min_age' => $minAge,
                'max_age' => $maxAge,
                'search' => $search,
                'situacao_cadastral' => $situacaoCadastral,
                'situacao_sociedade' => $situacaoSociedade,
                'apenas_elegiveis' => $apenasElegiveis,
            ],
            'total' => $candidatos->count(),
            'elegiveis_count' => $candidatos->where('elegibilidade.is_eligible', true)->count(),
            'fora_referencia_count' => $candidatos->where('elegibilidade.is_eligible', false)->count(),
            'ja_arrolados_count' => $candidatos->where('ja_arrolado', true)->count(),
            'data' => $candidatos,
        ]);
    }

    public function storeMembro(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'person_id' => 'required|exists:people,id',
            'tipo_socio' => 'required|in:efetivo,cooperador',
            'data_admissao' => 'nullable|date',
            'cargo_atual' => 'nullable|string|max:60',
            'status' => 'nullable|in:ativo,inativo,licenciado',
            'observacoes' => 'nullable|string',
        ]);

        // Validação de isolamento da instituição
        $person = Person::where('id', $validated['person_id'])
            ->where('institution_id', $sociedade->institution_id)
            ->firstOrFail();

        $status = $validated['status'] ?? 'ativo';

        // Impedir vínculos ativos duplicados
        $vinculoExistente = SociedadeMembro::where('sociedade_id', $sociedade->id)
            ->where('person_id', $person->id)
            ->first();

        if ($vinculoExistente && $vinculoExistente->status === 'ativo' && $status === 'ativo') {
            return response()->json([
                'message' => "{$person->full_name} já possui vínculo ativo com a sociedade {$sociedade->sigla}.",
                'errors' => ['person_id' => ['Esta pessoa já é sócia ativa desta sociedade.']],
            ], 422);
        }

        $validated['institution_id'] = $sociedade->institution_id;
        $validated['sociedade_id'] = $sociedade->id;
        $validated['data_admissao'] = $validated['data_admissao'] ?? now()->toDateString();
        $validated['status'] = $status;
        $validated['created_by'] = $request->user()?->id ?? 1;

        if ($vinculoExistente) {
            $vinculoExistente->update($validated);
            $membro = $vinculoExistente;
        } else {
            $membro = SociedadeMembro::create($validated);
        }

        $elegibilidade = $sociedade->evaluateEligibility($person);
        $membro->load('person:id,full_name,gender,birth_date,canonical_status');
        $membro->setAttribute('elegibilidade', $elegibilidade);

        return response()->json([
            'membro' => $membro,
            'elegibilidade' => $elegibilidade,
            'aviso' => !$elegibilidade['is_eligible'] ? "Atenção: {$person->full_name} foi incluído(a), porém está fora do perfil de referência: " . implode('; ', $elegibilidade['reasons']) : null,
        ], 201);
    }

    public function arrolarEmLote(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'person_ids' => 'required|array|min:1',
            'person_ids.*' => 'integer|exists:people,id',
            'tipo_socio' => 'nullable|in:efetivo,cooperador',
            'observacoes' => 'nullable|string',
        ]);

        $tipo = $validated['tipo_socio'] ?? 'efetivo';
        $userId = $request->user()?->id ?? 1;
        $hoje = now()->toDateString();

        // 1. Garantir isolamento: apenas pessoas da mesma instituição
        $pessoasValidas = Person::where('institution_id', $sociedade->institution_id)
            ->whereIn('id', $validated['person_ids'])
            ->get(['id', 'full_name', 'gender', 'birth_date']);

        if ($pessoasValidas->isEmpty()) {
            return response()->json([
                'message' => 'Nenhuma pessoa válida selecionada para esta instituição.',
            ], 422);
        }

        $validIds = $pessoasValidas->pluck('id')->all();

        // 2. Identificar quem já possui vínculo ativo com a sociedade para impedir duplicidade
        $jaArroladosIds = SociedadeMembro::where('sociedade_id', $sociedade->id)
            ->whereIn('person_id', $validIds)
            ->where('status', 'ativo')
            ->pluck('person_id')
            ->all();

        $novosIds = array_values(array_diff($validIds, $jaArroladosIds));

        // 3. Execução transacional segura
        $adicionados = 0;
        DB::transaction(function () use ($novosIds, $sociedade, $tipo, $userId, $hoje, &$adicionados) {
            foreach ($novosIds as $personId) {
                // Se já existia um registro inativo anterior, reativa; caso contrário, cria novo
                $m = SociedadeMembro::where('sociedade_id', $sociedade->id)
                    ->where('person_id', $personId)
                    ->first();

                if ($m) {
                    $m->update([
                        'status' => 'ativo',
                        'tipo_socio' => $tipo,
                        'data_admissao' => $hoje,
                        'created_by' => $userId,
                        'institution_id' => $sociedade->institution_id,
                    ]);
                } else {
                    SociedadeMembro::create([
                        'institution_id' => $sociedade->institution_id,
                        'sociedade_id' => $sociedade->id,
                        'person_id' => $personId,
                        'tipo_socio' => $tipo,
                        'data_admissao' => $hoje,
                        'status' => 'ativo',
                        'created_by' => $userId,
                    ]);
                }
                $adicionados++;
            }
        });

        $totalSelecionado = count($validIds);
        $totalJaArrolados = count($jaArroladosIds);

        return response()->json([
            'message' => "Arrolamento em lote concluído com sucesso: {$adicionados} novo(s) sócio(s) arrolado(s) na {$sociedade->sigla}.",
            'sociedade' => [
                'id' => $sociedade->id,
                'sigla' => $sociedade->sigla,
                'nome' => $sociedade->nome,
            ],
            'resumo' => [
                'total_selecionado' => $totalSelecionado,
                'novos_arrolados' => $adicionados,
                'ja_arrolados' => $totalJaArrolados,
                'falhas' => 0,
            ],
        ]);
    }

    public function deleteMembro(SociedadeInterna $sociedade, SociedadeMembro $membro): JsonResponse
    {
        if ($membro->sociedade_id !== $sociedade->id) {
            abort(404);
        }

        $membro->delete();
        return response()->json(['message' => 'Sócio removido do rol da sociedade.']);
    }

    // ==========================================
    // 📖 LIVRO DE ATAS DA SOCIEDADE
    // ==========================================

    public function getAtas(SociedadeInterna $sociedade): JsonResponse
    {
        $atas = $sociedade->atas()
            ->with(['presidente:id,full_name', 'secretario:id,full_name'])
            ->orderBy('data_reuniao', 'desc')
            ->orderBy('id', 'desc')
            ->get();

        return response()->json([
            'sociedade_id' => $sociedade->id,
            'total' => $atas->count(),
            'data' => $atas,
        ]);
    }

    public function storeAta(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'numero_ata' => 'required|string|max:30',
            'titulo' => 'required|string|max:160',
            'tipo_reuniao' => 'required|string|max:60',
            'data_reuniao' => 'required|date',
            'horario' => 'nullable|string|max:30',
            'local' => 'nullable|string|max:120',
            'presidente_id' => 'nullable|exists:people,id',
            'secretario_id' => 'nullable|exists:people,id',
            'pauta' => 'nullable|string',
            'conteudo' => 'required|string',
            'presentes_count' => 'nullable|integer',
            'status' => 'nullable|in:Rascunho,Aprovada,Assinada',
        ]);

        $validated['sociedade_id'] = $sociedade->id;
        $validated['status'] = $validated['status'] ?? 'Aprovada';
        $validated['presentes_count'] = $validated['presentes_count'] ?? 0;

        $ata = SociedadeAta::create($validated);

        return response()->json($ata->load(['presidente', 'secretario']), 201);
    }

    public function updateAta(Request $request, SociedadeInterna $sociedade, SociedadeAta $ata): JsonResponse
    {
        if ($ata->sociedade_id !== $sociedade->id) {
            abort(404);
        }

        $validated = $request->validate([
            'numero_ata' => 'sometimes|string|max:30',
            'titulo' => 'sometimes|string|max:160',
            'tipo_reuniao' => 'sometimes|string|max:60',
            'data_reuniao' => 'sometimes|date',
            'horario' => 'nullable|string|max:30',
            'local' => 'nullable|string|max:120',
            'presidente_id' => 'nullable|exists:people,id',
            'secretario_id' => 'nullable|exists:people,id',
            'pauta' => 'nullable|string',
            'conteudo' => 'sometimes|string',
            'presentes_count' => 'nullable|integer',
            'status' => 'nullable|in:Rascunho,Aprovada,Assinada',
            'visto_conselho_data' => 'nullable|date',
            'visto_conselho_relator' => 'nullable|string|max:120',
        ]);

        $ata->update($validated);

        return response()->json($ata->load(['presidente', 'secretario']));
    }

    public function deleteAta(SociedadeInterna $sociedade, SociedadeAta $ata): JsonResponse
    {
        if ($ata->sociedade_id !== $sociedade->id) {
            abort(404);
        }

        $ata->delete();
        return response()->json(['message' => 'Ata excluída com sucesso.']);
    }

    // ==========================================
    // 👥 DIRETORIA E ATIVIDADES (ORIGINAIS)
    // ==========================================

    public function storeDiretoria(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'cargo' => 'required|string|max:60',
            'person_id' => 'required|exists:people,id',
            'ano' => 'nullable|integer',
        ]);

        $validated['sociedade_id'] = $sociedade->id;
        $validated['ano'] = $validated['ano'] ?? $sociedade->ano_exercicio ?? 2026;

        $diretoria = SociedadeDiretoria::updateOrCreate(
            ['sociedade_id' => $sociedade->id, 'cargo' => $validated['cargo'], 'ano' => $validated['ano']],
            ['person_id' => $validated['person_id']]
        );

        // Também assegura que quem está na diretoria está arrolado como membro
        SociedadeMembro::firstOrCreate(
            ['sociedade_id' => $sociedade->id, 'person_id' => $validated['person_id']],
            [
                'tipo_socio' => 'efetivo',
                'data_admissao' => now()->toDateString(),
                'cargo_atual' => $validated['cargo'],
                'status' => 'ativo',
            ]
        );

        return response()->json($diretoria->load('person'), 201);
    }

    public function storeAtividade(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'titulo' => 'required|string|max:150',
            'data' => 'required|date',
            'horario' => 'nullable|string|max:30',
            'tipo' => 'nullable|string|max:60',
            'local' => 'nullable|string|max:120',
            'descricao' => 'nullable|string',
        ]);

        $validated['sociedade_id'] = $sociedade->id;
        $validated['tipo'] = $validated['tipo'] ?? 'Reunião Plenária';

        $atividade = SociedadeAtividade::create($validated);

        return response()->json($atividade, 201);
    }
}
