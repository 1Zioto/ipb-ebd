<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BibliotecaEmprestimo;
use App\Models\BibliotecaLivro;
use App\Models\DiscipuladoCatecumeno;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DiscipuladoBibliotecaController extends Controller
{
    // ==========================================
    // DISCIPULADO & CATECÚMENOS
    // ==========================================

    public function discipulado(Request $request): JsonResponse
    {
        $query = DiscipuladoCatecumeno::query()->with([
            'person:id,full_name,phone,email',
            'mentor:id,name',
        ]);

        if ($request->filled('fase')) {
            $query->where('fase', $request->query('fase'));
        }

        $items = $query->orderBy('created_at', 'desc')->paginate(15);

        $stats = [
            'total' => DiscipuladoCatecumeno::count(),
            'catecumenos' => DiscipuladoCatecumeno::where('fase', 'Classe de Catecúmenos')->count(),
            'novos_convertidos' => DiscipuladoCatecumeno::where('fase', 'Novo Convertido')->count(),
            'aptos_profissao' => DiscipuladoCatecumeno::where('fase', 'Apto para Batismo/Profissão')->count(),
            'concluidos' => DiscipuladoCatecumeno::where('fase', 'Concluído')->count(),
        ];

        return response()->json([
            'items' => $items,
            'stats' => $stats,
        ]);
    }

    public function storeCatecumeno(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'person_id' => 'required|exists:people,id',
            'mentor_id' => 'nullable|exists:users,id',
            'fase' => 'required|string|max:60',
            'data_inicio' => 'required|date',
            'total_licoes' => 'nullable|integer',
            'observacoes' => 'nullable|string',
        ]);

        $validated['institution_id'] = $request->user()->institution_id ?? 5;
        $validated['licoes_concluidas'] = 0;
        $validated['total_licoes'] = $validated['total_licoes'] ?? 10;

        $cat = DiscipuladoCatecumeno::create($validated);
        return response()->json($cat->load(['person', 'mentor']), 201);
    }

    public function updateCatecumeno(Request $request, DiscipuladoCatecumeno $item): JsonResponse
    {
        $validated = $request->validate([
            'fase' => 'nullable|string|max:60',
            'mentor_id' => 'nullable|exists:users,id',
            'licoes_concluidas' => 'nullable|integer|min:0|max:20',
            'data_conclusao' => 'nullable|date',
            'observacoes' => 'nullable|string',
        ]);

        $item->update($validated);
        return response()->json($item->load(['person', 'mentor']));
    }

    // ==========================================
    // BIBLIOTECA & EMPRÉSTIMOS
    // ==========================================

    public function livros(Request $request): JsonResponse
    {
        $query = BibliotecaLivro::query();

        if ($request->filled('categoria')) {
            $query->where('categoria', $request->query('categoria'));
        }
        if ($request->filled('search')) {
            $s = $request->query('search');
            $query->where(function ($q) use ($s) {
                $q->where('titulo', 'ilike', "%{$s}%")
                  ->orWhere('autor', 'ilike', "%{$s}%");
            });
        }

        $livros = $query->orderBy('titulo')->paginate(20);

        $stats = [
            'total_titulos' => BibliotecaLivro::count(),
            'total_exemplares' => BibliotecaLivro::sum('quantidade_total'),
            'disponiveis' => BibliotecaLivro::sum('quantidade_disponivel'),
            'emprestados' => BibliotecaEmprestimo::where('status', 'Emprestado')->count(),
            'atrasados' => BibliotecaEmprestimo::where('status', 'Emprestado')
                ->where('data_prevista_devolucao', '<', now()->toDateString())
                ->count(),
        ];

        return response()->json([
            'livros' => $livros,
            'stats' => $stats,
        ]);
    }

    public function storeLivro(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'titulo' => 'required|string|max:180',
            'autor' => 'required|string|max:150',
            'categoria' => 'required|string|max:80',
            'editora' => 'nullable|string|max:100',
            'ano' => 'nullable|integer',
            'isbn' => 'nullable|string|max:40',
            'quantidade_total' => 'required|integer|min:1',
            'localizacao' => 'nullable|string|max:100',
        ]);

        $validated['institution_id'] = $request->user()->institution_id ?? 5;
        $validated['quantidade_disponivel'] = $validated['quantidade_total'];

        $livro = BibliotecaLivro::create($validated);
        return response()->json($livro, 201);
    }

    public function emprestimos(Request $request): JsonResponse
    {
        $query = BibliotecaEmprestimo::query()->with([
            'livro:id,titulo,autor,categoria',
            'person:id,full_name,phone',
        ]);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        $emprestimos = $query->orderBy('data_emprestimo', 'desc')->paginate(15);
        return response()->json($emprestimos);
    }

    public function storeEmprestimo(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'livro_id' => 'required|exists:biblioteca_livros,id',
            'person_id' => 'required|exists:people,id',
            'data_emprestimo' => 'required|date',
            'data_prevista_devolucao' => 'required|date',
            'observacoes' => 'nullable|string',
        ]);

        $livro = BibliotecaLivro::findOrFail($validated['livro_id']);
        if ($livro->quantidade_disponivel <= 0) {
            return response()->json(['message' => 'Nenhum exemplar deste livro disponível no momento.'], 422);
        }

        $emprestimo = BibliotecaEmprestimo::create([
            'livro_id' => $livro->id,
            'person_id' => $validated['person_id'],
            'data_emprestimo' => $validated['data_emprestimo'],
            'data_prevista_devolucao' => $validated['data_prevista_devolucao'],
            'status' => 'Emprestado',
            'observacoes' => $validated['observacoes'] ?? null,
        ]);

        $livro->decrement('quantidade_disponivel');

        return response()->json($emprestimo->load(['livro', 'person']), 201);
    }

    public function devolverEmprestimo(Request $request, BibliotecaEmprestimo $emprestimo): JsonResponse
    {
        $emprestimo->update([
            'data_devolucao' => now()->toDateString(),
            'status' => 'Devolvido',
        ]);

        $emprestimo->livro->increment('quantidade_disponivel');

        return response()->json($emprestimo);
    }
}
