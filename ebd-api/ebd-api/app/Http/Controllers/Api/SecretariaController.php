<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AtaConselho;
use App\Models\CartaTransferencia;
use App\Models\Person;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SecretariaController extends Controller
{
    /** Rol Canônico de Membros */
    public function membros(Request $request): JsonResponse
    {
        $query = Person::query()->with('families:id,name');

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

        $perPage = (int) $request->query('per_page', 20);
        $membros = $query->orderBy('full_name')->paginate($perPage);

        $stats = [
            'total' => Person::count(),
            'comungantes' => Person::where('canonical_status', 'comungante')->count(),
            'nao_comungantes' => Person::where('canonical_status', 'nao_comungante')->count(),
            'sob_disciplina' => Person::where('canonical_status', 'sob_disciplina')->count(),
            'jurisdicao_especial' => Person::where('canonical_status', 'jurisdicao_especial')->count(),
            'falecidos' => Person::where('canonical_status', 'falecido')->count(),
        ];

        return response()->json([
            'membros' => $membros,
            'stats' => $stats,
        ]);
    }

    /** Exibir detalhes do membro */
    public function showMembro(Person $person): JsonResponse
    {
        return response()->json($person->load('families'));
    }

    /** Atualizar dados canônicos do membro */
    public function updateMembro(Request $request, Person $person): JsonResponse
    {
        $validated = $request->validate([
            'canonical_status' => 'required|string|in:comungante,nao_comungante,sob_disciplina,jurisdicao_especial,falecido',
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

        $totalComungantes = Person::where('canonical_status', 'comungante')->count();
        $totalNaoComungantes = Person::where('canonical_status', 'nao_comungante')->count();
        $totalSobDisciplina = Person::where('canonical_status', 'sob_disciplina')->count();
        $totalFalecidosAno = Person::where('canonical_status', 'falecido')
            ->whereYear('exit_date', $ano)
            ->count();

        $recebidosProfissaoBatismo = Person::where('reception_type', 'profissao_fe_batismo')
            ->whereYear('reception_date', $ano)
            ->count();
        $recebidosProfissao = Person::where('reception_type', 'profissao_fe')
            ->whereYear('reception_date', $ano)
            ->count();
        $recebidosTransferencia = CartaTransferencia::where('tipo', 'Recebida')
            ->whereYear('data_emissao', $ano)
            ->count();

        $saidasTransferencia = CartaTransferencia::where('tipo', 'Emitida')
            ->whereYear('data_emissao', $ano)
            ->count();

        $casamentosRealizados = Person::whereNotNull('marriage_date')
            ->whereYear('marriage_date', $ano)
            ->count();

        $batismosInfantis = Person::where('canonical_status', 'nao_comungante')
            ->whereNotNull('baptism_date')
            ->whereYear('baptism_date', $ano)
            ->count();

        return response()->json([
            'ano' => $ano,
            'igreja' => 'Igreja Presbiteriana em Campo Verde',
            'presbiterio' => 'Presbitério Campo Verde (PCVD) / Sínodo Mato Grosso',
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

        $validated['institution_id'] = $request->user()->institution_id ?? 5;
        $validated['status'] = $validated['status'] ?? 'Ativa';

        $carta = CartaTransferencia::create($validated);
        return response()->json($carta->load('person'), 201);
    }

    public function showCarta(CartaTransferencia $carta): JsonResponse
    {
        return response()->json($carta->load('person'));
    }

    /** Atas do Conselho */
    public function atas(Request $request): JsonResponse
    {
        $query = AtaConselho::query();

        if ($request->filled('tipo')) {
            $query->where('tipo', $request->query('tipo'));
        }
        if ($request->filled('search')) {
            $s = $request->query('search');
            $query->where(function ($q) use ($s) {
                $q->where('numero_ata', 'ilike', "%{$s}%")
                  ->orWhere('pauta', 'ilike', "%{$s}%")
                  ->orWhere('deliberacoes', 'ilike', "%{$s}%");
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
            'status' => 'nullable|string|in:Rascunho,Aprovada,Assinada',
        ]);

        $validated['institution_id'] = $request->user()->institution_id ?? 5;
        $validated['status'] = $validated['status'] ?? 'Aprovada';

        $ata = AtaConselho::create($validated);
        return response()->json($ata, 201);
    }

    public function showAta(AtaConselho $ata): JsonResponse
    {
        return response()->json($ata);
    }

    public function updateAta(Request $request, AtaConselho $ata): JsonResponse
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
            'status' => 'nullable|string|in:Rascunho,Aprovada,Assinada',
        ]);

        $ata->update($validated);
        return response()->json($ata);
    }
}
