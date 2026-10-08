<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CotaConciliar;
use App\Models\OrcamentoAnualLinha;
use App\Models\FinancialTransaction;
use App\Models\FinancialCostCenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CotasOrcamentoController extends Controller
{
    // ==========================================
    // 1. COTAS CONCILIARES (PRESBITÉRIO E SC)
    // ==========================================

    public function listarCotas(Request $request): JsonResponse
    {
        $ano = (int) $request->query('ano', now()->year);
        $cotas = CotaConciliar::where('ano', $ano)
            ->orderBy('mes')
            ->get();

        $stats = [
            'total_presbiterio_ano' => (float) $cotas->sum('valor_presbiterio'),
            'total_sc_ano' => (float) $cotas->sum('valor_supremo_concilio'),
            'pago_presbiterio' => (float) $cotas->where('status_presbiterio', 'Pago')->sum('valor_presbiterio'),
            'pendente_presbiterio' => (float) $cotas->where('status_presbiterio', 'Pendente')->sum('valor_presbiterio'),
            'pago_sc' => (float) $cotas->where('status_supremo_concilio', 'Pago')->sum('valor_supremo_concilio'),
            'pendente_sc' => (float) $cotas->where('status_supremo_concilio', 'Pendente')->sum('valor_supremo_concilio'),
        ];

        return response()->json([
            'cotas' => $cotas,
            'stats' => $stats,
        ]);
    }

    public function calcularCotaMes(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'ano' => 'required|integer|min:2020|max:2035',
            'mes' => 'required|integer|min:1|max:12',
            'base_calculo' => 'nullable|numeric|min:0',
            'aliquota_presbiterio_pct' => 'nullable|numeric|min:0|max:100',
            'aliquota_supremo_concilio_pct' => 'nullable|numeric|min:0|max:100',
        ]);

        $ano = $validated['ano'];
        $mes = $validated['mes'];

        // Se não forneceu base_calculo manual, calcula a partir das receitas pagas do mês no Livro Caixa
        if (!isset($validated['base_calculo'])) {
            $baseCalculo = (float) FinancialTransaction::where('type', 'receita')
                ->where('status', 'pago')
                ->whereYear('date', $ano)
                ->whereMonth('date', $mes)
                ->sum('amount');
        } else {
            $baseCalculo = (float) $validated['base_calculo'];
        }

        $aliqPresb = (float) ($validated['aliquota_presbiterio_pct'] ?? 5.00);
        $aliqSC = (float) ($validated['aliquota_supremo_concilio_pct'] ?? 5.00);

        $valorPresb = round(($baseCalculo * $aliqPresb) / 100, 2);
        $valorSC = round(($baseCalculo * $aliqSC) / 100, 2);

        $cota = CotaConciliar::updateOrCreate(
            ['ano' => $ano, 'mes' => $mes],
            [
                'base_calculo' => $baseCalculo,
                'aliquota_presbiterio_pct' => $aliqPresb,
                'aliquota_supremo_concilio_pct' => $aliqSC,
                'valor_presbiterio' => $valorPresb,
                'valor_supremo_concilio' => $valorSC,
            ]
        );

        return response()->json($cota);
    }

    public function atualizarPagamento(Request $request, CotaConciliar $cota): JsonResponse
    {
        $validated = $request->validate([
            'status_presbiterio' => 'sometimes|string|in:Pendente,Pago',
            'status_supremo_concilio' => 'sometimes|string|in:Pendente,Pago',
            'data_pagamento_presbiterio' => 'nullable|date',
            'data_pagamento_sc' => 'nullable|date',
            'comprovante_presbiterio' => 'nullable|string',
            'comprovante_sc' => 'nullable|string',
            'observacoes' => 'nullable|string',
        ]);

        $cota->update($validated);

        return response()->json($cota);
    }

    // ==========================================
    // 2. ORÇAMENTO ANUAL PROGRAMA (ORÇADO VS REALIZADO)
    // ==========================================

    public function comparativoOrcamento(Request $request): JsonResponse
    {
        $ano = (int) $request->query('ano', now()->year);
        $linhas = OrcamentoAnualLinha::with(['financialCategory', 'financialCostCenter'])
            ->where('ano', $ano)
            ->get();

        // Busca todas as despesas pagas do ano agrupadas por departamento/centro de custo
        $despesasPorCentro = FinancialTransaction::where('type', 'despesa')
            ->where('status', 'pago')
            ->whereYear('date', $ano)
            ->whereNotNull('financial_cost_center_id')
            ->selectRaw('financial_cost_center_id, SUM(amount) as total')
            ->groupBy('financial_cost_center_id')
            ->pluck('total', 'financial_cost_center_id');

        $despesasGerais = (float) FinancialTransaction::where('type', 'despesa')
            ->where('status', 'pago')
            ->whereYear('date', $ano)
            ->sum('amount');

        $comparativo = $linhas->map(function ($linha) use ($despesasPorCentro) {
            $previsto = (float) $linha->valor_previsto_anual;
            $realizado = 0.0;

            if ($linha->financial_cost_center_id && isset($despesasPorCentro[$linha->financial_cost_center_id])) {
                $realizado = (float) $despesasPorCentro[$linha->financial_cost_center_id];
            }

            $saldo = $previsto - $realizado;
            $percentual = $previsto > 0 ? round(($realizado / $previsto) * 100, 1) : 0;

            $status = 'Dentro do Orçamento';
            if ($percentual > 100) {
                $status = 'Estourado';
            } elseif ($percentual >= 85) {
                $status = 'Atenção (>85%)';
            }

            return [
                'id' => $linha->id,
                'departamento_ou_sociedade' => $linha->departamento_ou_sociedade,
                'descricao' => $linha->descricao,
                'financial_cost_center' => $linha->financialCostCenter ? $linha->financialCostCenter->name : null,
                'valor_previsto' => $previsto,
                'valor_realizado' => $realizado,
                'saldo' => $saldo,
                'percentual' => $percentual,
                'status' => $status,
                'observacoes' => $linha->observacoes,
            ];
        });

        $totalPrevisto = (float) $linhas->sum('valor_previsto_anual');
        $totalRealizado = (float) $comparativo->sum('valor_realizado');

        return response()->json([
            'ano' => $ano,
            'linhas' => $comparativo,
            'totais' => [
                'previsto_total' => $totalPrevisto,
                'realizado_total' => $totalRealizado,
                'saldo_total' => $totalPrevisto - $totalRealizado,
                'percentual_execucao' => $totalPrevisto > 0 ? round(($totalRealizado / $totalPrevisto) * 100, 1) : 0,
                'despesas_gerais_igreja' => $despesasGerais,
            ],
        ]);
    }

    public function storeLinha(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'ano' => 'required|integer|min:2020|max:2035',
            'departamento_ou_sociedade' => 'required|string|max:100',
            'financial_cost_center_id' => 'nullable|exists:financial_cost_centers,id',
            'descricao' => 'required|string|max:200',
            'valor_previsto_anual' => 'required|numeric|min:0',
            'observacoes' => 'nullable|string',
        ]);

        $linha = OrcamentoAnualLinha::create($validated);

        return response()->json($linha->load('financialCostCenter'), 201);
    }

    public function updateLinha(Request $request, OrcamentoAnualLinha $linha): JsonResponse
    {
        $validated = $request->validate([
            'departamento_ou_sociedade' => 'sometimes|string|max:100',
            'financial_cost_center_id' => 'nullable|exists:financial_cost_centers,id',
            'descricao' => 'sometimes|string|max:200',
            'valor_previsto_anual' => 'sometimes|numeric|min:0',
            'observacoes' => 'nullable|string',
        ]);

        $linha->update($validated);

        return response()->json($linha->load('financialCostCenter'));
    }

    public function destroyLinha(OrcamentoAnualLinha $linha): JsonResponse
    {
        $linha->delete();
        return response()->json(['message' => 'Linha orçamentária removida.']);
    }
}
