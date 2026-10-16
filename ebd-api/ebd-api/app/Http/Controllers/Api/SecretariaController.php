<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AtaConselho;
use App\Models\CartaTransferencia;
use App\Models\Institution;
use App\Models\Person;
use App\Services\InstitutionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SecretariaController extends Controller
{
    /** Rol de Membros */
    public function membros(Request $request): JsonResponse
    {
        $query = Person::query()->with('families:id,name');
        $this->restrictToCurrentInstitution($query, $request);

        if ($request->filled('status')) {
            $query->where('canonical_status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $s = $request->query('search');
            $query->where(function ($q) use ($s) {
                $q->where('full_name', 'ilike', "%{$s}%")
                    ->orWhere('roll_number', 'ilike', "%{$s}%")
                    ->orWhere('cpf', 'ilike', "%{$s}%");
            });
        }

        $perPage = min((int) $request->query('per_page', 20), 1000);
        $membros = $query->orderBy('full_name')->paginate($perPage);

        $statsBase = $this->peopleForCurrentInstitution($request);
        $stats = [
            'total' => (clone $statsBase)->count(),
            'comungantes' => (clone $statsBase)->where('canonical_status', 'comungante')->count(),
            'nao_comungantes' => (clone $statsBase)->where('canonical_status', 'nao_comungante')->count(),
            'sob_disciplina' => (clone $statsBase)->where('canonical_status', 'sob_disciplina')->count(),
            'jurisdicao_especial' => (clone $statsBase)->where('canonical_status', 'jurisdicao_especial')->count(),
            'falecidos' => (clone $statsBase)->where('canonical_status', 'falecido')->count(),
        ];

        return response()->json([
            'membros' => $membros,
            'stats' => $stats,
        ]);
    }

    /** Exibir detalhes do membro */
    public function showMembro(Request $request, Person $person): JsonResponse
    {
        $this->ensureCurrentInstitution($request, $person->institution_id);

        return response()->json($person->load('families'));
    }

    /** Atualizar dados eclesiásticos do membro */
    public function updateMembro(Request $request, Person $person): JsonResponse
    {
        $this->ensureCurrentInstitution($request, $person->institution_id);
        $validated = $request->validate([
            'canonical_status' => 'required|string|in:comungante,nao_comungante,sob_disciplina,jurisdicao_especial,falecido',
            'full_name' => 'nullable|string|max:150',
            'birth_date' => 'nullable|date',
            'roll_number' => 'nullable|string|max:50',
            'reception_type' => 'nullable|string|max:60',
            'reception_date' => 'nullable|date',
            'baptism_date' => 'nullable|date',
            'profession_date' => 'nullable|date',
            'exit_type' => 'nullable|string|max:60',
            'exit_date' => 'nullable|date',
            'marital_status' => 'nullable|string|max:30',
            'spouse_name' => 'nullable|string|max:150',
            'marriage_date' => 'nullable|date',
            'phone' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:100',
            'cpf' => 'nullable|string|max:20',
            'notes' => 'nullable|string',
        ]);

        $person->update($validated);

        return response()->json($person);
    }

    /** Estatística Anual Oficial para o Presbitério */
    public function estatisticaPresbiterio(Request $request): JsonResponse
    {
        $ano = (int) $request->query('ano', now()->year);

        $people = $this->peopleForConsolidatedInstitutions($request);
        $totalComungantes = (clone $people)->where('canonical_status', 'comungante')->count();
        $totalNaoComungantes = (clone $people)->where('canonical_status', 'nao_comungante')->count();
        $totalSobDisciplina = (clone $people)->where('canonical_status', 'sob_disciplina')->count();
        $totalFalecidosAno = (clone $people)->where('canonical_status', 'falecido')
            ->whereYear('exit_date', $ano)
            ->count();

        $recebidosProfissaoBatismo = (clone $people)->where('reception_type', 'profissao_fe_batismo')
            ->whereYear('reception_date', $ano)
            ->count();
        $recebidosProfissao = (clone $people)->where('reception_type', 'profissao_fe')
            ->whereYear('reception_date', $ano)
            ->count();
        $cartas = $this->cartasForConsolidatedInstitutions($request);
        $recebidosTransferencia = (clone $cartas)->where('tipo', 'Recebida')
            ->whereYear('data_emissao', $ano)
            ->count();

        $saidasTransferencia = (clone $cartas)->where('tipo', 'Emitida')
            ->whereYear('data_emissao', $ano)
            ->count();

        $casamentosRealizados = (clone $people)->whereNotNull('marriage_date')
            ->whereYear('marriage_date', $ano)
            ->count();

        $batismosInfantis = (clone $people)->where('canonical_status', 'nao_comungante')
            ->whereNotNull('baptism_date')
            ->whereYear('baptism_date', $ano)
            ->count();

        $institutionId = $request->user()?->institution_id ?: 5;
        $institution = Institution::with('parent.parent')->find($institutionId);
        $nomeIgreja = $institution?->name ?: 'Igreja Presbiteriana de Campo Verde';
        $presb = $institution?->parent?->name;
        $sinodo = $institution?->parent?->parent?->name;
        $jurisdicaoPartes = array_filter([$presb, $sinodo]);
        $jurisdicao = ! empty($jurisdicaoPartes)
            ? implode(' • ', $jurisdicaoPartes)
            : ($institution?->city && $institution?->state ? ($institution->city.' / '.$institution->state) : 'Presbitério Sudeste Espírito Santo (PSES) • Sínodo Central Espíritossantense (SCE)');

        return response()->json([
            'ano' => $ano,
            'igreja' => $nomeIgreja,
            'presbiterio' => $jurisdicao,
            'comungantes_atual' => $totalComungantes,
            'nao_comungantes_atual' => $totalNaoComungantes,
            'sob_disciplina_atual' => $totalSobDisciplina,
            'total_membros' => $totalComungantes + $totalNaoComungantes + $totalSobDisciplina,
            'movimento_ano' => [
                'recebidos_profissao_batismo' => $recebidosProfissaoBatismo,
                'recebidos_profissao' => $recebidosProfissao,
                'recebidos_transferencia' => $recebidosTransferencia,
                'saidas_transferencia' => $saidasTransferencia,
                'saidas_falecimento' => $totalFalecidosAno,
                'casamentos' => $casamentosRealizados,
                'batismos_infantis' => $batismosInfantis,
            ],
        ]);
    }

    /** Cartas de Transferência */
    public function cartas(Request $request): JsonResponse
    {
        $query = CartaTransferencia::query()->with('person:id,full_name,roll_number');
        $this->restrictToCurrentInstitution($query, $request);

        if ($request->filled('tipo')) {
            $query->where('tipo', $request->query('tipo'));
        }
        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        $cartas = $query->orderBy('data_emissao', 'desc')->paginate(15);

        return response()->json($cartas);
    }

    public function storeCarta(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'numero_carta' => 'required|string|max:50',
            'tipo' => 'required|string|in:Emitida,Recebida',
            'person_id' => 'required|exists:people,id',
            'igreja_origem' => 'required|string|max:150',
            'igreja_destino' => 'required|string|max:150',
            'cidade_uf' => 'nullable|string|max:100',
            'data_emissao' => 'required|date',
            'data_validade' => 'nullable|date',
            'observacoes' => 'nullable|string',
            'status' => 'nullable|string|in:Ativa,Concluída,Expirada,Cancelada',
        ]);

        $person = Person::findOrFail($validated['person_id']);
        $this->ensureCurrentInstitution($request, $person->institution_id);

        $validated['institution_id'] = $request->user()->institution_id ?? 5;
        $validated['status'] = $validated['status'] ?? 'Ativa';

        $carta = CartaTransferencia::create($validated);

        return response()->json($carta->load('person'), 201);
    }

    public function showCarta(Request $request, CartaTransferencia $carta): JsonResponse
    {
        $this->ensureCurrentInstitution($request, $carta->institution_id);

        return response()->json($carta->load('person'));
    }

    /** Atas do Conselho */
    public function atas(Request $request): JsonResponse
    {
        $query = AtaConselho::query();
        $this->restrictToCurrentInstitution($query, $request);

        if ($request->filled('tipo')) {
            $query->where('tipo', $request->query('tipo'));
        }
        if ($request->filled('search')) {
            $s = $request->query('search');
            $query->where(function ($q) use ($s) {
                $q->where('numero_ata', 'ilike', "%{$s}%")
                    ->orWhere('pauta', 'ilike', "%{$s}%")
                    ->orWhere('deliberacoes', 'ilike', "%{$s}%")
                    ->orWhere('ata_original', 'ilike', "%{$s}%");
            });
        }

        $atas = $query->orderBy('data_reuniao', 'desc')->paginate(15);

        return response()->json($atas);
    }

    public function storeAta(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'numero_ata' => 'required|string|max:50',
            'tipo' => 'required|string|in:Ordinária,Extraordinária',
            'data_reuniao' => 'required|date',
            'horario' => 'nullable|string|max:30',
            'local' => 'nullable|string|max:120',
            'pastor_presidente' => 'nullable|string|max:120',
            'secretario_conselho' => 'nullable|string|max:120',
            'presbiters_presentes' => 'nullable|array',
            'abertura' => 'nullable|string',
            'pauta' => 'nullable|string',
            'deliberacoes' => 'nullable|string',
            'ata_original' => 'nullable|string',
            'status' => 'nullable|string|in:Rascunho,Aprovada,Assinada',
        ]);

        $validated['institution_id'] = $request->user()->institution_id ?? 5;
        $validated['status'] = $validated['status'] ?? 'Aprovada';

        $ata = AtaConselho::create($validated);

        return response()->json($ata, 201);
    }

    public function showAta(Request $request, AtaConselho $ata): JsonResponse
    {
        $this->ensureCurrentInstitution($request, $ata->institution_id);

        return response()->json($ata);
    }

    public function updateAta(Request $request, AtaConselho $ata): JsonResponse
    {
        $this->ensureCurrentInstitution($request, $ata->institution_id);
        $validated = $request->validate([
            'numero_ata' => 'required|string|max:50',
            'tipo' => 'required|string|in:Ordinária,Extraordinária',
            'data_reuniao' => 'required|date',
            'horario' => 'nullable|string|max:30',
            'local' => 'nullable|string|max:120',
            'pastor_presidente' => 'nullable|string|max:120',
            'secretario_conselho' => 'nullable|string|max:120',
            'presbiters_presentes' => 'nullable|array',
            'abertura' => 'nullable|string',
            'pauta' => 'nullable|string',
            'deliberacoes' => 'nullable|string',
            'ata_original' => 'nullable|string',
            'status' => 'nullable|string|in:Rascunho,Aprovada,Assinada',
        ]);

        $ata->update($validated);

        return response()->json($ata);
    }

    public function aprovarAta(Request $request, AtaConselho $ata): JsonResponse
    {
        $this->ensureCurrentInstitution($request, $ata->institution_id);
        $ata->update(['status' => 'Aprovada']);

        return response()->json([
            'message' => 'Ata aprovada com sucesso!',
            'ata' => $ata,
        ]);
    }

    /** Restricts rolls, letters and minutes to the secretary's own church. */
    private function restrictToCurrentInstitution($query, Request $request): void
    {
        if ($request->user()->hasGlobalInstitutionAccess()) {
            return;
        }

        $query->where('institution_id', $request->user()->institution_id ?: 0);
    }

    private function ensureCurrentInstitution(Request $request, ?int $institutionId): void
    {
        if ($request->user()->hasGlobalInstitutionAccess()) {
            return;
        }

        abort_unless((int) $request->user()->institution_id === (int) $institutionId, 403);
    }

    /** Presbytery receives only aggregation across its authorized descendants. */
    private function peopleForConsolidatedInstitutions(Request $request)
    {
        $query = Person::query();
        $this->restrictToConsolidatedInstitutions($query, $request);

        return $query;
    }

    private function cartasForConsolidatedInstitutions(Request $request)
    {
        $query = CartaTransferencia::query();
        $this->restrictToConsolidatedInstitutions($query, $request);

        return $query;
    }

    private function peopleForCurrentInstitution(Request $request)
    {
        $query = Person::query();
        $this->restrictToCurrentInstitution($query, $request);

        return $query;
    }

    private function restrictToConsolidatedInstitutions($query, Request $request): void
    {
        if ($request->user()->hasGlobalInstitutionAccess()) {
            return;
        }

        $institutionId = $request->user()->institution_id;
        if (! $institutionId) {
            $query->whereRaw('1 = 0');

            return;
        }

        $ids = app(InstitutionService::class)->getDescendantIds($institutionId, true);
        $query->whereIn('institution_id', $ids ?: [0]);
    }
}
