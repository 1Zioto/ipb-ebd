<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PatrimonioBem;
use App\Models\OrdemServicoDiaconia;
use App\Models\EscalaDiacono;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DiaconiaPatrimonioController extends Controller
{
    // ==========================================
    // 1. LIVRO TOMBO & PATRIMÔNIO DA IGREJA
    // ==========================================

    public function listarBens(Request $request): JsonResponse
    {
        $query = PatrimonioBem::query();

        if ($request->filled('categoria')) {
            $query->where('categoria', $request->query('categoria'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('localizacao')) {
            $query->where('localizacao', $request->query('localizacao'));
        }

        if ($request->filled('search')) {
            $s = $request->query('search');
            $query->where(function ($q) use ($s) {
                $q->where('nome', 'like', "%{$s}%")
                  ->orWhere('numero_tombamento', 'like', "%{$s}%")
                  ->orWhere('descricao', 'like', "%{$s}%")
                  ->orWhere('responsavel_diacono', 'like', "%{$s}%");
            });
        }

        $bens = $query->orderBy('numero_tombamento')->paginate($request->query('per_page', 20));

        $stats = [
            'total_itens' => PatrimonioBem::count(),
            'ativos' => PatrimonioBem::where('status', 'Ativo')->count(),
            'em_manutencao' => PatrimonioBem::where('status', 'Em Manutenção')->count(),
            'valor_total_aquisicao' => (float) PatrimonioBem::sum('valor_aquisicao'),
            'valor_total_atual' => (float) PatrimonioBem::sum('valor_atual'),
        ];

        return response()->json([
            'bens' => $bens,
            'stats' => $stats,
        ]);
    }

    public function storeBem(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'numero_tombamento' => 'nullable|string|max:50',
            'nome' => 'required|string|max:150',
            'categoria' => 'required|string|max:60',
            'localizacao' => 'required|string|max:120',
            'data_aquisicao' => 'nullable|date',
            'valor_aquisicao' => 'nullable|numeric',
            'valor_atual' => 'nullable|numeric',
            'estado_conservacao' => 'required|string|max:40',
            'status' => 'required|string|max:30',
            'nota_fiscal' => 'nullable|string|max:100',
            'descricao' => 'nullable|string',
            'responsavel_diacono' => 'nullable|string|max:120',
        ]);

        if (empty($validated['numero_tombamento'])) {
            $count = PatrimonioBem::count() + 1;
            $validated['numero_tombamento'] = sprintf('TOMBO-%04d', $count);
        }

        if (empty($validated['valor_atual']) && !empty($validated['valor_aquisicao'])) {
            $validated['valor_atual'] = $validated['valor_aquisicao'];
        }

        $bem = PatrimonioBem::create($validated);

        return response()->json($bem, 201);
    }

    public function showBem(PatrimonioBem $bem): JsonResponse
    {
        return response()->json($bem);
    }

    public function updateBem(Request $request, PatrimonioBem $bem): JsonResponse
    {
        $validated = $request->validate([
            'nome' => 'sometimes|string|max:150',
            'categoria' => 'sometimes|string|max:60',
            'localizacao' => 'sometimes|string|max:120',
            'data_aquisicao' => 'nullable|date',
            'valor_aquisicao' => 'nullable|numeric',
            'valor_atual' => 'nullable|numeric',
            'estado_conservacao' => 'sometimes|string|max:40',
            'status' => 'sometimes|string|max:30',
            'nota_fiscal' => 'nullable|string|max:100',
            'descricao' => 'nullable|string',
            'responsavel_diacono' => 'nullable|string|max:120',
        ]);

        $bem->update($validated);

        return response()->json($bem);
    }

    public function destroyBem(PatrimonioBem $bem): JsonResponse
    {
        $bem->delete();
        return response()->json(['message' => 'Bem removido com sucesso.']);
    }

    // ==========================================
    // 2. ORDENS DE SERVIÇO & ZELADORIA DIACONAL
    // ==========================================

    public function listarOS(Request $request): JsonResponse
    {
        $query = OrdemServicoDiaconia::query();

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('prioridade')) {
            $query->where('prioridade', $request->query('prioridade'));
        }

        if ($request->filled('tipo_servico')) {
            $query->where('tipo_servico', $request->query('tipo_servico'));
        }

        $ordens = $query->orderByDesc('data_solicitacao')->paginate($request->query('per_page', 20));

        $stats = [
            'total' => OrdemServicoDiaconia::count(),
            'pendentes' => OrdemServicoDiaconia::where('status', 'Pendente')->count(),
            'em_andamento' => OrdemServicoDiaconia::where('status', 'Em Andamento')->count(),
            'concluidas' => OrdemServicoDiaconia::where('status', 'Concluída')->count(),
            'custo_total_real' => (float) OrdemServicoDiaconia::where('status', 'Concluída')->sum('custo_real'),
        ];

        return response()->json([
            'ordens' => $ordens,
            'stats' => $stats,
        ]);
    }

    public function storeOS(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'numero_os' => 'nullable|string|max:50',
            'titulo' => 'required|string|max:150',
            'descricao' => 'required|string',
            'tipo_servico' => 'required|string|max:60',
            'localizacao' => 'required|string|max:120',
            'prioridade' => 'required|string|max:30',
            'solicitante' => 'required|string|max:120',
            'diacono_responsavel' => 'nullable|string|max:120',
            'data_solicitacao' => 'required|date',
            'data_previsao' => 'nullable|date',
            'custo_estimado' => 'nullable|numeric',
            'observacoes' => 'nullable|string',
        ]);

        if (empty($validated['numero_os'])) {
            $count = OrdemServicoDiaconia::whereYear('created_at', now()->year)->count() + 1;
            $validated['numero_os'] = sprintf('OS-%04d/%03d', now()->year, $count);
        }

        $os = OrdemServicoDiaconia::create($validated);

        return response()->json($os, 201);
    }

    public function updateOS(Request $request, OrdemServicoDiaconia $os): JsonResponse
    {
        $validated = $request->validate([
            'titulo' => 'sometimes|string|max:150',
            'descricao' => 'sometimes|string',
            'tipo_servico' => 'sometimes|string|max:60',
            'localizacao' => 'sometimes|string|max:120',
            'prioridade' => 'sometimes|string|max:30',
            'status' => 'sometimes|string|max:30',
            'diacono_responsavel' => 'nullable|string|max:120',
            'data_previsao' => 'nullable|date',
            'data_conclusao' => 'nullable|date',
            'custo_estimado' => 'nullable|numeric',
            'custo_real' => 'nullable|numeric',
            'observacoes' => 'nullable|string',
        ]);

        $os->update($validated);

        return response()->json($os);
    }

    public function concluirOS(Request $request, OrdemServicoDiaconia $os): JsonResponse
    {
        $validated = $request->validate([
            'data_conclusao' => 'required|date',
            'custo_real' => 'required|numeric',
            'observacoes' => 'nullable|string',
        ]);

        $os->update([
            'status' => 'Concluída',
            'data_conclusao' => $validated['data_conclusao'],
            'custo_real' => $validated['custo_real'],
            'observacoes' => $validated['observacoes'] ?? $os->observacoes,
        ]);

        return response()->json([
            'message' => 'Ordem de serviço concluída com sucesso!',
            'os' => $os,
        ]);
    }

    // ==========================================
    // 3. ESCALAS DE DIÁCONOS DO CULTO
    // ==========================================

    public function listarEscalas(Request $request): JsonResponse
    {
        $query = EscalaDiacono::query();

        if ($request->filled('mes') && $request->filled('ano')) {
            $query->whereYear('data_culto', $request->query('ano'))
                  ->whereMonth('data_culto', $request->query('mes'));
        }

        $escalas = $query->orderBy('data_culto')->get();

        return response()->json($escalas);
    }

    public function storeEscala(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'data_culto' => 'required|date',
            'periodo' => 'required|string|max:40',
            'recepcao_porta' => 'nullable|string|max:255',
            'recolhimento_ofertas' => 'nullable|string|max:255',
            'apoio_pulpito_ceia' => 'nullable|string|max:255',
            'seguranca_patio' => 'nullable|string|max:255',
            'diacono_coordenador' => 'nullable|string|max:120',
            'observacoes' => 'nullable|string',
        ]);

        $escala = EscalaDiacono::create($validated);

        return response()->json($escala, 201);
    }

    public function updateEscala(Request $request, EscalaDiacono $escala): JsonResponse
    {
        $validated = $request->validate([
            'data_culto' => 'sometimes|date',
            'periodo' => 'sometimes|string|max:40',
            'recepcao_porta' => 'nullable|string|max:255',
            'recolhimento_ofertas' => 'nullable|string|max:255',
            'apoio_pulpito_ceia' => 'nullable|string|max:255',
            'seguranca_patio' => 'nullable|string|max:255',
            'diacono_coordenador' => 'nullable|string|max:120',
            'observacoes' => 'nullable|string',
        ]);

        $escala->update($validated);

        return response()->json($escala);
    }
}
