<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AttendanceRecord;
use App\Models\AttendanceSession;
use App\Models\CartaTransferencia;
use App\Models\ClassRoom;
use App\Models\ClassStudent;
use App\Models\EbdEvent;
use App\Models\Family;
use App\Models\Institution;
use App\Models\Person;
use App\Models\SociedadeInterna;
use App\Models\SociedadeMembro;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

class EcclesiasticalIntelligenceController extends Controller
{
    /**
     * Resolve o ID da instituição alvo com suporte a hierarquia e filtro.
     */
    private function resolveInstitutionId(Request $request): int
    {
        $requested = $request->query('institution_id');
        if ($requested && is_numeric($requested)) {
            return (int) $requested;
        }

        return $request->user()?->institution_id ?: 5;
    }

    /**
     * Obtém instituições subordinadas ou a própria para consolidação.
     */
    private function getTargetInstitutionIds(int $institutionId, bool $consolidated = false): array
    {
        if (! $consolidated) {
            return [$institutionId];
        }

        $descendants = DB::select("
            WITH RECURSIVE subordinates AS (
                SELECT id FROM institutions WHERE id = ? AND deleted_at IS NULL
                UNION ALL
                SELECT i.id FROM institutions i
                INNER JOIN subordinates s ON i.parent_institution_id = s.id
                WHERE i.deleted_at IS NULL
            )
            SELECT id FROM subordinates
        ", [$institutionId]);

        return ! empty($descendants) ? array_column($descendants, 'id') : [$institutionId];
    }

    /**
     * 1. Visão Geral da Igreja (Executive Overview)
     */
    public function overview(Request $request): JsonResponse
    {
        $instId = $this->resolveInstitutionId($request);
        $consolidated = filter_var($request->query('consolidated', false), FILTER_VALIDATE_BOOLEAN);
        $targetIds = $this->getTargetInstitutionIds($instId, $consolidated);
        $ano = (int) ($request->query('ano') ?: now()->year);

        $peopleQuery = Person::whereIn('institution_id', $targetIds);
        $totalPessoas = (clone $peopleQuery)->count();
        $totalMembros = (clone $peopleQuery)->where('is_active', true)->count();
        $comungantes = (clone $peopleQuery)->where('is_active', true)->where('canonical_status', 'comungante')->count();
        $naoComungantes = (clone $peopleQuery)->where('is_active', true)->where('canonical_status', 'nao_comungante')->count();
        $sobDisciplina = (clone $peopleQuery)->where('is_active', true)->where('canonical_status', 'sob_disciplina')->count();
        $outrosCanonicos = max(0, $totalMembros - ($comungantes + $naoComungantes + $sobDisciplina));

        $totalFamilias = Family::whereIn('institution_id', $targetIds)->where('is_active', true)->count();
        $totalAlunosEbd = ClassStudent::join('classes', 'class_students.class_id', '=', 'classes.id')
            ->whereIn('classes.institution_id', $targetIds)
            ->where('class_students.is_active', true)
            ->distinct('class_students.person_id')
            ->count('class_students.person_id');
        $totalProfessores = (clone $peopleQuery)->where('is_active', true)->where('can_teach', true)->count();
        $totalSuperintendentes = (clone $peopleQuery)->where('is_active', true)->where('can_superintend', true)->count();
        $totalDizimistas = (clone $peopleQuery)->where('is_active', true)->where('is_tither', true)->count();

        // Movimentação do Ano
        $admissoesAno = (clone $peopleQuery)->whereYear('reception_date', $ano)->count();
        $saidasAno = (clone $peopleQuery)->whereYear('exit_date', $ano)->count();
        $crescimentoLiquido = $admissoesAno - $saidasAno;

        // Idades e Média
        $birthDates = (clone $peopleQuery)->where('is_active', true)->whereNotNull('birth_date')->pluck('birth_date');
        $ages = [];
        $ageDistribution = [
            'infantil' => 0,   // 0 a 11 anos (Crianças / UCP)
            'adolescentes' => 0, // 12 a 17 anos (UPA)
            'jovens' => 0,     // 18 a 35 anos (UMP)
            'adultos' => 0,    // 36 a 59 anos (SAF / UPH)
            'melhor_idade' => 0, // 60+ anos
        ];

        foreach ($birthDates as $bd) {
            $age = Carbon::parse($bd)->age;
            $ages[] = $age;
            if ($age < 12) {
                $ageDistribution['infantil']++;
            } elseif ($age < 18) {
                $ageDistribution['adolescentes']++;
            } elseif ($age < 36) {
                $ageDistribution['jovens']++;
            } elseif ($age < 60) {
                $ageDistribution['adultos']++;
            } else {
                $ageDistribution['melhor_idade']++;
            }
        }

        $mediaIdade = count($ages) > 0 ? round(array_sum($ages) / count($ages), 1) : 0;
        sort($ages);
        $medianaIdade = 0;
        $countAges = count($ages);
        if ($countAges > 0) {
            $middle = (int) floor($countAges / 2);
            $medianaIdade = ($countAges % 2 !== 0)
                ? $ages[$middle]
                : round(($ages[$middle - 1] + $ages[$middle]) / 2, 1);
        }

        // Aniversariantes do Mês
        $currentMonth = now()->month;
        $aniversariantesMes = (clone $peopleQuery)->where('is_active', true)
            ->whereNotNull('birth_date')
            ->whereMonth('birth_date', $currentMonth)
            ->count();

        // Taxa média da EBD no ano
        $eventIds = EbdEvent::whereIn('institution_id', $targetIds)->whereYear('event_date', $ano)->pluck('id');
        $sessions = AttendanceSession::whereIn('ebd_event_id', $eventIds)->get();
        $sessionIds = $sessions->pluck('id');
        $records = AttendanceRecord::whereIn('attendance_session_id', $sessionIds)->get();
        $presentCount = $records->where('present', true)->count();
        $absentCount = $records->where('present', false)->count();
        $totalChamadas = $presentCount + $absentCount;
        $frequenciaEbdMedia = $totalChamadas > 0 ? round(($presentCount / $totalChamadas) * 100, 1) : 0;

        return response()->json([
            'ano' => $ano,
            'institution_id' => $instId,
            'is_consolidated' => $consolidated,
            'kpis' => [
                'total_pessoas' => $totalPessoas,
                'total_membros' => $totalMembros,
                'comungantes' => $comungantes,
                'nao_comungantes' => $naoComungantes,
                'sob_disciplina' => $sobDisciplina,
                'total_familias' => $totalFamilias,
                'total_alunos_ebd' => $totalAlunosEbd,
                'total_professores' => $totalProfessores,
                'total_superintendentes' => $totalSuperintendentes,
                'total_dizimistas' => $totalDizimistas,
                'admissoes_ano' => $admissoesAno,
                'saidas_ano' => $saidasAno,
                'crescimento_liquido' => $crescimentoLiquido,
                'media_idade' => $mediaIdade,
                'mediana_idade' => $medianaIdade,
                'aniversariantes_mes' => $aniversariantesMes,
                'frequencia_ebd_media' => $frequenciaEbdMedia,
            ],
            'age_distribution' => $ageDistribution,
            'canonical_chart' => [
                'labels' => ['Comungantes', 'Não Comungantes', 'Sob Disciplina', 'Outros'],
                'data' => [$comungantes, $naoComungantes, $sobDisciplina, $outrosCanonicos],
            ],
        ]);
    }

    /**
     * 2. Perfil Demográfico Detalhado da Membresia
     */
    public function demographics(Request $request): JsonResponse
    {
        $instId = $this->resolveInstitutionId($request);
        $people = Person::where('institution_id', $instId)->where('is_active', true)->get();

        // 1. Faixas etárias detalhadas
        $faixas = [
            '0 a 11 anos (Infantil)' => 0,
            '12 a 17 anos (Adolescentes)' => 0,
            '18 a 29 anos (Jovens)' => 0,
            '30 a 44 anos (Adultos Jovens)' => 0,
            '45 a 59 anos (Maduros)' => 0,
            '60 a 74 anos (Seniores)' => 0,
            '75 anos ou mais' => 0,
            'Não informada' => 0,
        ];

        $ages = [];
        $aniversariosPorMes = array_fill(1, 12, 0);

        foreach ($people as $p) {
            if (! $p->birth_date) {
                $faixas['Não informada']++;
                continue;
            }
            $age = $p->birth_date->age;
            $ages[] = $age;
            $aniversariosPorMes[$p->birth_date->month]++;

            if ($age <= 11) $faixas['0 a 11 anos (Infantil)']++;
            elseif ($age <= 17) $faixas['12 a 17 anos (Adolescentes)']++;
            elseif ($age <= 29) $faixas['18 a 29 anos (Jovens)']++;
            elseif ($age <= 44) $faixas['30 a 44 anos (Adultos Jovens)']++;
            elseif ($age <= 59) $faixas['45 a 59 anos (Maduros)']++;
            elseif ($age <= 74) $faixas['60 a 74 anos (Seniores)']++;
            else $faixas['75 anos ou mais']++;
        }

        // 2. Estado Civil
        $marital = [
            'Casado(a)' => $people->where('marital_status', 'Casado')->count() + $people->where('marital_status', 'casado')->count(),
            'Solteiro(a)' => $people->where('marital_status', 'Solteiro')->count() + $people->where('marital_status', 'solteiro')->count(),
            'Viúvo(a)' => $people->where('marital_status', 'Viuvo')->count() + $people->where('marital_status', 'viuvo')->count() + $people->where('marital_status', 'Viúvo')->count(),
            'Divorciado(a)' => $people->where('marital_status', 'Divorciado')->count() + $people->where('marital_status', 'divorciado')->count(),
            'Não informado' => $people->whereNull('marital_status')->count(),
        ];

        sort($ages);
        $menorIdade = count($ages) > 0 ? min($ages) : 0;
        $maiorIdade = count($ages) > 0 ? max($ages) : 0;
        $mediaIdade = count($ages) > 0 ? round(array_sum($ages) / count($ages), 1) : 0;

        return response()->json([
            'total_analisado' => $people->count(),
            'menor_idade' => $menorIdade,
            'maior_idade' => $maiorIdade,
            'media_idade' => $mediaIdade,
            'faixas_etarias' => [
                'labels' => array_keys($faixas),
                'data' => array_values($faixas),
            ],
            'estado_civil' => [
                'labels' => array_keys($marital),
                'data' => array_values($marital),
            ],
            'aniversarios_mes' => [
                'labels' => ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
                'data' => array_values($aniversariosPorMes),
            ],
        ]);
    }

    /**
     * 3. Crescimento e Movimentação do Rol
     */
    public function movements(Request $request): JsonResponse
    {
        $instId = $this->resolveInstitutionId($request);
        $ano = (int) ($request->query('ano') ?: now()->year);

        // Evolução Anual (últimos 5 anos)
        $anos = range($ano - 4, $ano);
        $admissoesPorAno = [];
        $saidasPorAno = [];
        $saldoPorAno = [];

        foreach ($anos as $y) {
            $adm = Person::where('institution_id', $instId)->whereYear('reception_date', $y)->count();
            $sai = Person::where('institution_id', $instId)->whereYear('exit_date', $y)->count();
            $admissoesPorAno[] = $adm;
            $saidasPorAno[] = $sai;
            $saldoPorAno[] = $adm - $sai;
        }

        // Admissões por Mês no Ano Selecionado
        $admissoesMes = array_fill(1, 12, 0);
        $peopleAdm = Person::where('institution_id', $instId)
            ->whereYear('reception_date', $ano)
            ->get(['reception_date']);
        foreach ($peopleAdm as $p) {
            if ($p->reception_date) {
                $admissoesMes[(int) Carbon::parse($p->reception_date)->month]++;
            }
        }

        // Admissões por Tipo de Recepção
        $receptionTypes = Person::where('institution_id', $instId)
            ->whereNotNull('reception_type')
            ->select('reception_type', DB::raw('count(*) as total'))
            ->groupBy('reception_type')
            ->pluck('total', 'reception_type')
            ->all();

        // Saídas por Motivo
        $exitTypes = Person::where('institution_id', $instId)
            ->whereNotNull('exit_type')
            ->select('exit_type', DB::raw('count(*) as total'))
            ->groupBy('exit_type')
            ->pluck('total', 'exit_type')
            ->all();

        // Cartas de Transferência
        $cartasRecebidas = CartaTransferencia::where('institution_id', $instId)->where('tipo', 'Recebida')->count();
        $cartasEmitidas = CartaTransferencia::where('institution_id', $instId)->where('tipo', 'Emitida')->count();

        return response()->json([
            'ano_selecionado' => $ano,
            'evolucao_anual' => [
                'anos' => $anos,
                'admissoes' => $admissoesPorAno,
                'saidas' => $saidasPorAno,
                'saldo' => $saldoPorAno,
            ],
            'admissoes_mes' => [
                'labels' => ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
                'data' => array_values($admissoesMes),
            ],
            'tipos_recepcao' => [
                'labels' => array_keys($receptionTypes),
                'data' => array_values($receptionTypes),
            ],
            'tipos_saida' => [
                'labels' => array_keys($exitTypes),
                'data' => array_values($exitTypes),
            ],
            'cartas' => [
                'recebidas' => $cartasRecebidas,
                'emitidas' => $cartasEmitidas,
            ],
        ]);
    }

    /**
     * 4. Vida Eclesiástica (Batismos, Profissões & Tempo de Membresia)
     */
    public function ecclesiasticalLife(Request $request): JsonResponse
    {
        $instId = $this->resolveInstitutionId($request);
        $people = Person::where('institution_id', $instId)->where('is_active', true)->get();

        // Tempo de membresia
        $tempoFaixas = [
            'Menos de 1 ano' => 0,
            '1 a 3 anos' => 0,
            '4 a 5 anos' => 0,
            '6 a 10 anos' => 0,
            '11 a 20 anos' => 0,
            'Mais de 20 anos' => 0,
            'Não informado' => 0,
        ];

        foreach ($people as $p) {
            if (! $p->reception_date) {
                $tempoFaixas['Não informado']++;
                continue;
            }
            $anos = Carbon::parse($p->reception_date)->diffInYears(now());
            if ($anos < 1) $tempoFaixas['Menos de 1 ano']++;
            elseif ($anos <= 3) $tempoFaixas['1 a 3 anos']++;
            elseif ($anos <= 5) $tempoFaixas['4 a 5 anos']++;
            elseif ($anos <= 10) $tempoFaixas['6 a 10 anos']++;
            elseif ($anos <= 20) $tempoFaixas['11 a 20 anos']++;
            else $tempoFaixas['Mais de 20 anos']++;
        }

        // Histórico de Batismos e Profissões de Fé (últimos 5 anos)
        $currentYear = now()->year;
        $anos = range($currentYear - 4, $currentYear);
        $batismosAno = [];
        $profissoesAno = [];

        foreach ($anos as $y) {
            $batismosAno[] = Person::where('institution_id', $instId)->whereYear('baptism_date', $y)->count();
            $profissoesAno[] = Person::where('institution_id', $instId)->whereYear('profession_date', $y)->count();
        }

        return response()->json([
            'tempo_membresia' => [
                'labels' => array_keys($tempoFaixas),
                'data' => array_values($tempoFaixas),
            ],
            'sacramentos_historico' => [
                'anos' => $anos,
                'batismos' => $batismosAno,
                'profissoes' => $profissoesAno,
            ],
            'totais' => [
                'com_batismo_registrado' => $people->whereNotNull('baptism_date')->count(),
                'com_profissao_registrada' => $people->whereNotNull('profession_date')->count(),
                'com_data_casamento' => $people->whereNotNull('marriage_date')->count(),
            ],
        ]);
    }

    /**
     * 5. Famílias e Distribuição Geográfica
     */
    public function familiesGeo(Request $request): JsonResponse
    {
        $instId = $this->resolveInstitutionId($request);

        $families = Family::where('institution_id', $instId)->with('members')->get();
        $totalFamilias = $families->count();

        // 1. Tamanho das Famílias
        $tamanhos = [
            '1 pessoa' => 0,
            '2 pessoas' => 0,
            '3 pessoas' => 0,
            '4 pessoas' => 0,
            '5 ou mais pessoas' => 0,
        ];
        $totalPessoasEmFamilias = 0;

        foreach ($families as $f) {
            $mCount = $f->members->count();
            $totalPessoasEmFamilias += $mCount;
            if ($mCount <= 1) $tamanhos['1 pessoa']++;
            elseif ($mCount === 2) $tamanhos['2 pessoas']++;
            elseif ($mCount === 3) $tamanhos['3 pessoas']++;
            elseif ($mCount === 4) $tamanhos['4 pessoas']++;
            else $tamanhos['5 ou mais pessoas']++;
        }

        $mediaPorFamilia = $totalFamilias > 0 ? round($totalPessoasEmFamilias / $totalFamilias, 1) : 0;

        // 2. Grau de Parentesco
        $parentescos = DB::table('family_members')
            ->join('families', 'family_members.family_id', '=', 'families.id')
            ->where('families.institution_id', $instId)
            ->select('family_members.relationship', DB::raw('count(*) as total'))
            ->groupBy('family_members.relationship')
            ->pluck('total', 'relationship')
            ->all();

        // 3. Distribuição Geográfica por Bairro (Top 8)
        $bairros = Family::where('institution_id', $instId)
            ->whereNotNull('district')
            ->where('district', '!=', '')
            ->select('district', DB::raw('count(*) as total'))
            ->groupBy('district')
            ->orderByDesc('total')
            ->take(8)
            ->pluck('total', 'district')
            ->all();

        // 4. Cidades
        $cidades = Family::where('institution_id', $instId)
            ->whereNotNull('city')
            ->where('city', '!=', '')
            ->select('city', DB::raw('count(*) as total'))
            ->groupBy('city')
            ->orderByDesc('total')
            ->take(5)
            ->pluck('total', 'city')
            ->all();

        return response()->json([
            'total_familias' => $totalFamilias,
            'media_por_familia' => $mediaPorFamilia,
            'total_pessoas_vinculadas' => $totalPessoasEmFamilias,
            'tamanhos_familia' => [
                'labels' => array_keys($tamanhos),
                'data' => array_values($tamanhos),
            ],
            'parentescos' => [
                'labels' => array_keys($parentescos),
                'data' => array_values($parentescos),
            ],
            'top_bairros' => [
                'labels' => array_keys($bairros),
                'data' => array_values($bairros),
            ],
            'cidades' => [
                'labels' => array_keys($cidades),
                'data' => array_values($cidades),
            ],
        ]);
    }

    /**
     * 6. Escola Bíblica Dominical (EBD Analytics)
     */
    public function ebdAnalytics(Request $request): JsonResponse
    {
        $instId = $this->resolveInstitutionId($request);
        $ano = (int) ($request->query('ano') ?: now()->year);

        $events = EbdEvent::where('institution_id', $instId)
            ->whereYear('event_date', $ano)
            ->orderBy('event_date')
            ->get();
        $eventIds = $events->pluck('id');

        $sessions = AttendanceSession::whereIn('ebd_event_id', $eventIds)->get();
        $sessionIds = $sessions->pluck('id');
        $records = AttendanceRecord::whereIn('attendance_session_id', $sessionIds)->get();

        // Frequência Mensal (Jan a Dez)
        $meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
        $presentesMes = array_fill(1, 12, 0);
        $ausentesMes = array_fill(1, 12, 0);
        $taxasMes = array_fill(1, 12, 0);

        for ($m = 1; $m <= 12; $m++) {
            $mEventIds = $events->filter(fn ($e) => $e->event_date && $e->event_date->month === $m)->pluck('id');
            $mSessionIds = $sessions->whereIn('ebd_event_id', $mEventIds)->pluck('id');
            $mRecords = $records->whereIn('attendance_session_id', $mSessionIds);

            $p = $mRecords->where('present', true)->count();
            $a = $mRecords->where('present', false)->count();
            $total = $p + $a;

            $presentesMes[$m] = $p;
            $ausentesMes[$m] = $a;
            $taxasMes[$m] = $total > 0 ? round(($p / $total) * 100, 1) : 0;
        }

        // Frequência por Classe
        $classes = ClassRoom::where('institution_id', $instId)->where('is_active', true)->get();
        $classesStats = [];

        foreach ($classes as $c) {
            $cSessionIds = $sessions->where('class_room_id', $c->id)->pluck('id');
            $cRecords = $records->whereIn('attendance_session_id', $cSessionIds);
            $p = $cRecords->where('present', true)->count();
            $a = $cRecords->where('present', false)->count();
            $total = $p + $a;
            $rate = $total > 0 ? round(($p / $total) * 100, 1) : 0;
            $enrolled = ClassStudent::where('class_id', $c->id)->where('is_active', true)->count();

            $classesStats[] = [
                'class_id' => $c->id,
                'name' => $c->name,
                'enrolled' => $enrolled,
                'present' => $p,
                'absent' => $a,
                'rate' => $rate,
            ];
        }

        $totalBíblias = $records->where('brought_bible', true)->count() + (int) $sessions->sum('bibles_total');
        $totalRevistas = $records->where('brought_magazine', true)->count() + (int) $sessions->sum('magazines_total');

        return response()->json([
            'ano' => $ano,
            'total_encontros' => $events->count(),
            'total_biblias' => $totalBíblias,
            'total_revistas' => $totalRevistas,
            'frequencia_mensal' => [
                'labels' => $meses,
                'presentes' => array_values($presentesMes),
                'ausentes' => array_values($ausentesMes),
                'taxas' => array_values($taxasMes),
            ],
            'classes' => $classesStats,
        ]);
    }

    /**
     * 7. Sociedades Internas (SAF, UPH, UMP, UPA, UCP)
     */
    public function societiesAnalytics(Request $request): JsonResponse
    {
        $instId = $this->resolveInstitutionId($request);

        $sociedades = SociedadeInterna::where('institution_id', $instId)
            ->with(['membros.person:id,full_name,birth_date'])
            ->get();

        $resumoSociedades = [];
        $totalVinculos = 0;

        foreach ($sociedades as $soc) {
            $membrosAtivos = $soc->membros->where('status', 'ativo');
            $comCargo = $membrosAtivos->whereNotNull('cargo_atual')->count();
            $totalVinculos += $membrosAtivos->count();

            $ages = [];
            foreach ($membrosAtivos as $m) {
                if ($m->person?->birth_date) {
                    $ages[] = Carbon::parse($m->person->birth_date)->age;
                }
            }
            $mediaIdade = count($ages) > 0 ? round(array_sum($ages) / count($ages), 1) : null;

            $resumoSociedades[] = [
                'id' => $soc->id,
                'sigla' => $soc->sigla,
                'nome' => $soc->nome,
                'total_membros' => $membrosAtivos->count(),
                'com_cargo' => $comCargo,
                'media_idade' => $mediaIdade,
            ];
        }

        // Se a instituição não tiver sociedades cadastradas, retorna dados estruturados vazios
        return response()->json([
            'total_sociedades_ativas' => $sociedades->count(),
            'total_vinculos' => $totalVinculos,
            'sociedades' => $resumoSociedades,
            'grafico' => [
                'labels' => array_column($resumoSociedades, 'sigla'),
                'data' => array_column($resumoSociedades, 'total_membros'),
            ],
        ]);
    }

    /**
     * 8. Qualidade e Integridade Cadastral
     */
    public function dataQuality(Request $request): JsonResponse
    {
        $instId = $this->resolveInstitutionId($request);
        $people = Person::where('institution_id', $instId)->where('is_active', true)->get();
        $total = $people->count();

        if ($total === 0) {
            return response()->json([
                'total_membros' => 0,
                'indice_completude' => 100,
                'inconsistencias' => [],
            ]);
        }

        $semCpf = $people->filter(fn ($p) => blank($p->cpf))->count();
        $semNascimento = $people->filter(fn ($p) => blank($p->birth_date))->count();
        $semTelefone = $people->filter(fn ($p) => blank($p->phone))->count();
        $semEmail = $people->filter(fn ($p) => blank($p->email))->count();
        $semRol = $people->filter(fn ($p) => blank($p->roll_number))->count();
        $semDataAdmissao = $people->filter(fn ($p) => blank($p->reception_date))->count();

        // Famílias sem endereço
        $familiasSemEndereco = Family::where('institution_id', $instId)
            ->where('is_active', true)
            ->where(function ($q) {
                $q->whereNull('street')->orWhere('street', '')
                  ->orWhereNull('district')->orWhere('district', '');
            })
            ->count();

        // Pessoas sem vínculo familiar
        $pessoasComFamiliaIds = DB::table('family_members')->pluck('person_id')->all();
        $semFamilia = $people->whereNotIn('id', $pessoasComFamiliaIds)->count();

        // Índice Geral de Completude (média de preenchimento dos 6 atributos centrais)
        $taxaCpf = 1 - ($semCpf / $total);
        $taxaNasc = 1 - ($semNascimento / $total);
        $taxaTel = 1 - ($semTelefone / $total);
        $taxaEmail = 1 - ($semEmail / $total);
        $taxaRol = 1 - ($semRol / $total);
        $taxaAdm = 1 - ($semDataAdmissao / $total);

        $indiceCompletude = round((($taxaCpf + $taxaNasc + $taxaTel + $taxaEmail + $taxaRol + $taxaAdm) / 6) * 100, 1);

        $diagnostico = [
            [
                'categoria' => 'Documentação',
                'item' => 'Membros sem CPF',
                'pendentes' => $semCpf,
                'percentual' => round(($semCpf / $total) * 100, 1),
                'gravidade' => 'Média',
            ],
            [
                'categoria' => 'Demografia',
                'item' => 'Sem Data de Nascimento',
                'pendentes' => $semNascimento,
                'percentual' => round(($semNascimento / $total) * 100, 1),
                'gravidade' => 'Alta',
            ],
            [
                'categoria' => 'Contato',
                'item' => 'Sem Telefone / WhatsApp',
                'pendentes' => $semTelefone,
                'percentual' => round(($semTelefone / $total) * 100, 1),
                'gravidade' => 'Alta',
            ],
            [
                'categoria' => 'Contato',
                'item' => 'Sem E-mail Cadastrado',
                'pendentes' => $semEmail,
                'percentual' => round(($semEmail / $total) * 100, 1),
                'gravidade' => 'Baixa',
            ],
            [
                'categoria' => 'Rol Canônico',
                'item' => 'Sem Número de Rol de Membros',
                'pendentes' => $semRol,
                'percentual' => round(($semRol / $total) * 100, 1),
                'gravidade' => 'Alta',
            ],
            [
                'categoria' => 'Rol Canônico',
                'item' => 'Sem Data de Recepção',
                'pendentes' => $semDataAdmissao,
                'percentual' => round(($semDataAdmissao / $total) * 100, 1),
                'gravidade' => 'Média',
            ],
            [
                'categoria' => 'Vínculo Familiar',
                'item' => 'Membros sem Família Vinculada',
                'pendentes' => $semFamilia,
                'percentual' => round(($semFamilia / $total) * 100, 1),
                'gravidade' => 'Média',
            ],
            [
                'categoria' => 'Geografia',
                'item' => 'Famílias sem Endereço Completo',
                'pendentes' => $familiasSemEndereco,
                'percentual' => $total > 0 ? round(($familiasSemEndereco / Family::where('institution_id', $instId)->count()) * 100, 1) : 0,
                'gravidade' => 'Média',
            ],
        ];

        return response()->json([
            'total_membros' => $total,
            'indice_completude' => $indiceCompletude,
            'resumo' => [
                'sem_cpf' => $semCpf,
                'sem_nascimento' => $semNascimento,
                'sem_telefone' => $semTelefone,
                'sem_email' => $semEmail,
                'sem_rol' => $semRol,
                'sem_familia' => $semFamilia,
            ],
            'diagnostico' => $diagnostico,
        ]);
    }

    /**
     * 9. Listagem de Membros da Congregação com Dados Canônicos
     */
    public function membersList(Request $request): JsonResponse
    {
        $instId = $this->resolveInstitutionId($request);
        $consolidated = filter_var($request->query('consolidated', false), FILTER_VALIDATE_BOOLEAN);
        $targetIds = $this->getTargetInstitutionIds($instId, $consolidated);

        $query = Person::whereIn('institution_id', $targetIds)
            ->with([
                'families:id,name',
                'sociedadeMembros.sociedade:id,sigla,nome',
            ]);

        if ($request->has('is_active') && $request->query('is_active') !== '') {
            $query->where('is_active', filter_var($request->query('is_active'), FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->filled('canonical_status')) {
            $query->where('canonical_status', $request->query('canonical_status'));
        }

        if ($request->filled('search')) {
            $search = '%' . trim($request->query('search')) . '%';
            $query->where(function ($q) use ($search) {
                $q->where('full_name', 'like', $search)
                  ->orWhere('roll_number', 'like', $search)
                  ->orWhere('cpf', 'like', $search)
                  ->orWhere('email', 'like', $search);
            });
        }

        $members = $query->orderBy('full_name')->get();

        return response()->json([
            'total' => $members->count(),
            'members' => $members->map(function ($m) {
                return [
                    'id' => $m->id,
                    'roll_number' => $m->roll_number ?: 'S/N',
                    'full_name' => $m->full_name,
                    'canonical_status' => $m->canonical_status ?: 'comungante',
                    'is_active' => (bool) $m->is_active,
                    'birth_date' => $m->birth_date ? Carbon::parse($m->birth_date)->format('Y-m-d') : null,
                    'age' => $m->birth_date ? Carbon::parse($m->birth_date)->age : null,
                    'marital_status' => $m->marital_status,
                    'spouse_name' => $m->spouse_name,
                    'phone' => $m->phone,
                    'email' => $m->email,
                    'cpf' => $m->cpf,
                    'reception_date' => $m->reception_date ? Carbon::parse($m->reception_date)->format('Y-m-d') : null,
                    'reception_type' => $m->reception_type,
                    'baptism_date' => $m->baptism_date ? Carbon::parse($m->baptism_date)->format('Y-m-d') : null,
                    'profession_date' => $m->profession_date ? Carbon::parse($m->profession_date)->format('Y-m-d') : null,
                    'is_tither' => (bool) $m->is_tither,
                    'envelope_number' => $m->envelope_number,
                    'can_teach' => (bool) $m->can_teach,
                    'can_superintend' => (bool) $m->can_superintend,
                    'families' => $m->families->map(fn ($f) => ['id' => $f->id, 'name' => $f->name]),
                    'sociedades' => $m->sociedadeMembros
                        ->filter(fn ($sm) => $sm->status === 'ativo' && $sm->sociedade)
                        ->map(fn ($sm) => $sm->sociedade->sigla ?: $sm->sociedade->nome)
                        ->values(),
                    'notes' => $m->notes,
                ];
            }),
        ]);
    }

    /**
     * 10. Exportação da Lista de Membros para Planilha Excel (CSV com BOM UTF-8 e Delimitador ;)
     */
    public function exportMembers(Request $request): StreamedResponse
    {
        $instId = $this->resolveInstitutionId($request);
        $consolidated = filter_var($request->query('consolidated', false), FILTER_VALIDATE_BOOLEAN);
        $targetIds = $this->getTargetInstitutionIds($instId, $consolidated);

        $institution = Institution::find($instId);
        $nomeInstituicao = $institution?->name ?? 'Igreja Presbiteriana do Brasil';

        $query = Person::whereIn('institution_id', $targetIds)
            ->with([
                'families:id,name',
                'sociedadeMembros.sociedade:id,sigla,nome',
            ]);

        if ($request->has('is_active') && $request->query('is_active') !== '') {
            $query->where('is_active', filter_var($request->query('is_active'), FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->filled('canonical_status')) {
            $query->where('canonical_status', $request->query('canonical_status'));
        }

        $members = $query->orderBy('full_name')->get();

        $dataAtual = now()->format('d/m/Y H:i');
        $slug = Str::slug($nomeInstituicao);
        $nomeArquivo = "rol_membros_{$slug}_" . now()->format('Ymd_His') . ".csv";

        return response()->streamDownload(function () use ($members, $nomeInstituicao, $dataAtual) {
            $handle = fopen('php://output', 'w');
            // BOM UTF-8 para garantir abertura imediata e sem distorção no Microsoft Excel
            fprintf($handle, chr(0xEF) . chr(0xBB) . chr(0xBF));

            // Cabeçalho institucional
            fputcsv($handle, ['IGREJA PRESBITERIANA DO BRASIL'], ';');
            fputcsv($handle, ['ROL GERAL DE MEMBROS E DADOS ECLESIÁSTICOS DA CONGREGAÇÃO'], ';');
            fputcsv($handle, ['Instituição / Congregação:', $nomeInstituicao], ';');
            fputcsv($handle, ['Data e Hora de Emissão:', $dataAtual], ';');
            fputcsv($handle, ['Total de Membros no Relatório:', (string) $members->count()], ';');
            fputcsv($handle, [], ';');

            // Colunas da Planilha
            fputcsv($handle, [
                'Nº do Rol',
                'Nome Completo',
                'Status Canônico',
                'Situação',
                'Data de Nascimento',
                'Idade',
                'Estado Civil',
                'Cônjuge',
                'Telefone / Celular',
                'E-mail',
                'CPF',
                'Data de Recepção',
                'Modo de Recepção',
                'Data de Batismo',
                'Data de Profissão de Fé',
                'Dizimista',
                'Nº Envelope',
                'Professor EBD',
                'Superintendente EBD',
                'Família',
                'Sociedades Internas',
                'Observações',
            ], ';');

            foreach ($members as $m) {
                $canonicalLabel = match ($m->canonical_status) {
                    'comungante' => 'Comungante',
                    'nao_comungante' => 'Não Comungante',
                    'sob_disciplina' => 'Sob Disciplina',
                    'inativo' => 'Inativo',
                    default => ucfirst($m->canonical_status ?? 'Não informado'),
                };

                $familiesStr = $m->families->pluck('name')->filter()->join(', ');
                $sociedadesStr = $m->sociedadeMembros
                    ->filter(fn ($sm) => $sm->status === 'ativo' && $sm->sociedade)
                    ->map(fn ($sm) => $sm->sociedade->sigla ?: $sm->sociedade->nome)
                    ->unique()
                    ->join(', ');

                fputcsv($handle, [
                    $m->roll_number ?: 'S/N',
                    $m->full_name,
                    $canonicalLabel,
                    $m->is_active ? 'Ativo' : 'Inativo',
                    $m->birth_date ? Carbon::parse($m->birth_date)->format('d/m/Y') : '',
                    $m->birth_date ? (string) Carbon::parse($m->birth_date)->age : '',
                    $m->marital_status ?: '',
                    $m->spouse_name ?: '',
                    $m->phone ?: '',
                    $m->email ?: '',
                    $m->cpf ?: '',
                    $m->reception_date ? Carbon::parse($m->reception_date)->format('d/m/Y') : '',
                    $m->reception_type ?: '',
                    $m->baptism_date ? Carbon::parse($m->baptism_date)->format('d/m/Y') : '',
                    $m->profession_date ? Carbon::parse($m->profession_date)->format('d/m/Y') : '',
                    $m->is_tither ? 'Sim' : 'Não',
                    $m->envelope_number ?: '',
                    $m->can_teach ? 'Sim' : 'Não',
                    $m->can_superintend ? 'Sim' : 'Não',
                    $familiesStr,
                    $sociedadesStr,
                    $m->notes ?: '',
                ], ';');
            }

            fclose($handle);
        }, $nomeArquivo, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => "attachment; filename=\"{$nomeArquivo}\"",
            'Pragma' => 'no-cache',
            'Cache-Control' => 'must-revalidate, post-check=0, pre-check=0',
            'Expires' => '0',
        ]);
    }
}
