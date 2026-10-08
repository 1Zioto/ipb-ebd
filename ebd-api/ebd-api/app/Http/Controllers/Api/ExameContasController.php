<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ParecerExameContas;
use App\Models\FinancialTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExameContasController extends Controller
{
    /** Listar pareceres emitidos */
    public function index(Request $request): JsonResponse
    {
        $query = ParecerExameContas::query();

        if ($request->filled('ano')) {
            $query->where('ano_exercicio', $request->query('ano'));
        }

        if ($request->filled('resultado')) {
            $query->where('resultado', $request->query('resultado'));
        }

        $pareceres = $query->orderByDesc('ano_exercicio')
            ->orderByDesc('data_emissao')
            ->paginate($request->query('per_page', 20));

        $stats = [
            'total' => ParecerExameContas::count(),
            'sem_ressalvas' => ParecerExameContas::where('resultado', 'Favorável sem ressalvas')->count(),
            'com_ressalvas' => ParecerExameContas::where('resultado', 'Favorável com ressalvas')->count(),
            'desfavoraveis' => ParecerExameContas::where('resultado', 'Desfavorável')->count(),
        ];

        return response()->json([
            'pareceres' => $pareceres,
            'stats' => $stats,
        ]);
    }

    /** Sugestão de auditoria para o período selecionado */
    public function auditarPeriodo(Request $request): JsonResponse
    {
        $ano = (int) $request->query('ano', now()->year);
        $periodo = $request->query('periodo', '1º Trimestre');

        $meses = match ($periodo) {
            '1º Trimestre' => [1, 2, 3],
            '2º Trimestre' => [4, 5, 6],
            '3º Trimestre' => [7, 8, 9],
            '4º Trimestre' => [10, 11, 12],
            default => range(1, 12),
        };

        $receitas = (float) FinancialTransaction::where('type', 'receita')
            ->where('status', 'pago')
            ->whereYear('date', $ano)
            ->whereIn(\DB::raw('EXTRACT(MONTH FROM date)'), $meses)
            ->sum('amount');

        $despesas = (float) FinancialTransaction::where('type', 'despesa')
            ->where('status', 'pago')
            ->whereYear('date', $ano)
            ->whereIn(\DB::raw('EXTRACT(MONTH FROM date)'), $meses)
            ->sum('amount');

        $saldo = $receitas - $despesas;

        return response()->json([
            'ano' => $ano,
            'periodo' => $periodo,
            'total_receitas' => $receitas,
            'total_despesas' => $despesas,
            'saldo' => $saldo,
            'conformidade_livro_caixa' => true,
            'conformidade_extratos_bancarios' => true,
            'conformidade_comprovantes_fiscais' => true,
            'conformidade_cotas_conciliares' => true,
        ]);
    }

    /** Emitir novo parecer */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'numero_parecer' => 'nullable|string|max:50',
            'ano_exercicio' => 'required|integer',
            'periodo' => 'required|string|max:60',
            'data_emissao' => 'required|date',
            'relator' => 'required|string|max:120',
            'membros_comissao' => 'nullable|array',
            'resultado' => 'required|string|max:50',
            'total_receitas_auditado' => 'required|numeric',
            'total_despesas_auditado' => 'required|numeric',
            'saldo_apurado' => 'required|numeric',
            'conformidade_livro_caixa' => 'required|boolean',
            'conformidade_extratos_bancarios' => 'required|boolean',
            'conformidade_comprovantes_fiscais' => 'required|boolean',
            'conformidade_cotas_conciliares' => 'required|boolean',
            'ressalvas_e_recomendacoes' => 'nullable|string',
            'texto_conclusao' => 'required|string',
            'status' => 'required|string|max:40',
        ]);

        if (empty($validated['numero_parecer'])) {
            $count = ParecerExameContas::where('ano_exercicio', $validated['ano_exercicio'])->count() + 1;
            $validated['numero_parecer'] = sprintf('PAR-%04d/%02d', $validated['ano_exercicio'], $count);
        }

        $parecer = ParecerExameContas::create($validated);

        return response()->json($parecer, 201);
    }

    /** Exibir detalhes do parecer */
    public function show(ParecerExameContas $parecer): JsonResponse
    {
        return response()->json($parecer);
    }

    /** Atualizar parecer */
    public function update(Request $request, ParecerExameContas $parecer): JsonResponse
    {
        $validated = $request->validate([
            'resultado' => 'sometimes|string|max:50',
            'total_receitas_auditado' => 'sometimes|numeric',
            'total_despesas_auditado' => 'sometimes|numeric',
            'saldo_apurado' => 'sometimes|numeric',
            'conformidade_livro_caixa' => 'sometimes|boolean',
            'conformidade_extratos_bancarios' => 'sometimes|boolean',
            'conformidade_comprovantes_fiscais' => 'sometimes|boolean',
            'conformidade_cotas_conciliares' => 'sometimes|boolean',
            'ressalvas_e_recomendacoes' => 'nullable|string',
            'texto_conclusao' => 'sometimes|string',
            'status' => 'sometimes|string|max:40',
        ]);

        $parecer->update($validated);

        return response()->json($parecer);
    }
}
