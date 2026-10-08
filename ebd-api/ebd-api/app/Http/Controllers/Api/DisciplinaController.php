<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProcessoDisciplinar;
use App\Models\Person;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DisciplinaController extends Controller
{
    /** Listar processos disciplinares com filtros */
    public function index(Request $request): JsonResponse
    {
        $query = ProcessoDisciplinar::with(['person:id,full_name,roll_number,canonical_status', 'ataConselho:id,numero_ata,data_reuniao']);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('tipo_falta')) {
            $query->where('tipo_falta', $request->query('tipo_falta'));
        }

        if ($request->filled('search')) {
            $s = $request->query('search');
            $query->where(function ($q) use ($s) {
                $q->where('numero_processo', 'like', "%{$s}%")
                  ->orWhere('descricao_falta', 'like', "%{$s}%")
                  ->orWhere('relator_presbitero', 'like', "%{$s}%")
                  ->orWhereHas('person', function ($pq) use ($s) {
                      $pq->where('full_name', 'like', "%{$s}%");
                  });
            });
        }

        $processos = $query->orderByDesc('data_abertura')->paginate($request->query('per_page', 20));

        $stats = [
            'total' => ProcessoDisciplinar::count(),
            'em_aberto' => ProcessoDisciplinar::where('status', 'Em Aberto')->count(),
            'cumprindo_disciplina' => ProcessoDisciplinar::where('status', 'Cumprindo Disciplina')->count(),
            'restaurados' => ProcessoDisciplinar::where('status', 'Restaurado')->count(),
            'sob_disciplina_membros' => Person::where('canonical_status', 'sob_disciplina')->count(),
        ];

        return response()->json([
            'processos' => $processos,
            'stats' => $stats,
        ]);
    }

    /** Criar novo processo disciplinar */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'person_id' => 'required|exists:people,id',
            'numero_processo' => 'nullable|string|max:50',
            'tipo_falta' => 'required|string|max:60',
            'descricao_falta' => 'required|string',
            'medida_disciplinar' => 'required|string|max:60',
            'data_abertura' => 'required|date',
            'data_julgamento' => 'nullable|date',
            'prazo_meses' => 'nullable|integer',
            'relator_presbitero' => 'nullable|string|max:120',
            'ata_conselho_id' => 'nullable|exists:atas_conselho,id',
            'status' => 'required|string|max:40',
            'observacoes_pastorais' => 'nullable|string',
        ]);

        if (empty($validated['numero_processo'])) {
            $count = ProcessoDisciplinar::whereYear('created_at', now()->year)->count() + 1;
            $validated['numero_processo'] = sprintf('PROC-%04d/%03d', now()->year, $count);
        }

        $processo = ProcessoDisciplinar::create($validated);

        // Se a medida for suspensão ou exclusão, sincroniza o status canônico do membro
        if (in_array($processo->medida_disciplinar, ['Sob Admoestação', 'Sob Censura', 'Suspensão dos Sacramentos'])) {
            Person::where('id', $processo->person_id)->update(['canonical_status' => 'sob_disciplina']);
        } elseif ($processo->medida_disciplinar === 'Exclusão do Rol') {
            Person::where('id', $processo->person_id)->update(['canonical_status' => 'jurisdicao_especial']);
        }

        return response()->json($processo->load(['person', 'ataConselho']), 201);
    }

    /** Detalhar processo */
    public function show(ProcessoDisciplinar $processo): JsonResponse
    {
        return response()->json($processo->load(['person', 'ataConselho']));
    }

    /** Atualizar processo */
    public function update(Request $request, ProcessoDisciplinar $processo): JsonResponse
    {
        $validated = $request->validate([
            'tipo_falta' => 'sometimes|string|max:60',
            'descricao_falta' => 'sometimes|string',
            'medida_disciplinar' => 'sometimes|string|max:60',
            'data_abertura' => 'sometimes|date',
            'data_julgamento' => 'nullable|date',
            'data_restauracao' => 'nullable|date',
            'prazo_meses' => 'nullable|integer',
            'relator_presbitero' => 'nullable|string|max:120',
            'ata_conselho_id' => 'nullable|exists:atas_conselho,id',
            'status' => 'sometimes|string|max:40',
            'observacoes_pastorais' => 'nullable|string',
        ]);

        $processo->update($validated);

        return response()->json($processo->load(['person', 'ataConselho']));
    }

    /** Restaurar membro à plena comunhão */
    public function restaurar(Request $request, ProcessoDisciplinar $processo): JsonResponse
    {
        $validated = $request->validate([
            'data_restauracao' => 'required|date',
            'observacoes_pastorais' => 'nullable|string',
        ]);

        $processo->update([
            'status' => 'Restaurado',
            'medida_disciplinar' => 'Restaurado',
            'data_restauracao' => $validated['data_restauracao'],
            'observacoes_pastorais' => ($processo->observacoes_pastorais ? $processo->observacoes_pastorais . "\n" : '') .
                "[Restauração em {$validated['data_restauracao']}]: " . ($validated['observacoes_pastorais'] ?? 'Restauração aprovada pelo Conselho.'),
        ]);

        // Retorna o membro para comungante
        Person::where('id', $processo->person_id)->update(['canonical_status' => 'comungante']);

        return response()->json([
            'message' => 'Membro restaurado à plena comunhão com sucesso!',
            'processo' => $processo->load('person'),
        ]);
    }

    /** Alerta de ausência prolongada (Abandono do rol há mais de 1 ano) */
    public function alertasAbandono(): JsonResponse
    {
        // Membros sem registros de presença/dízimo ou cadastrados como ausentes há mais de 1 ano
        $membrosEmRisco = Person::where('canonical_status', 'comungante')
            ->where(function ($q) {
                $q->whereNull('last_seen_date')
                  ->orWhere('last_seen_date', '<', now()->subYear());
            })
            ->select('id', 'full_name', 'roll_number', 'phone', 'canonical_status', 'created_at')
            ->take(30)
            ->get();

        return response()->json($membrosEmRisco);
    }
}
