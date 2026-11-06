<?php

namespace App\Http\Controllers\Api\Financial;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\ColetaDizimo;
use App\Models\FinancialAccount;
use App\Models\FinancialAnnualClosing;
use App\Models\FinancialTransaction;
use App\Models\Institution;
use App\Models\LancamentoDizimo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FinancialAnnualClosingController extends Controller
{
    /**
     * Listagem dos fechamentos de exercício da instituição
     */
    public function index(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $closings = FinancialAnnualClosing::where('institution_id', $institutionId)
            ->with(['closedBy:id,name', 'approvedBy:id,name'])
            ->orderBy('year', 'desc')
            ->get();

        return response()->json($closings);
    }

    /**
     * Exibe os detalhes e o snapshot completo de um exercício fechado
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $closing = FinancialAnnualClosing::where('institution_id', $institutionId)
            ->with(['closedBy:id,name', 'approvedBy:id,name', 'institution:id,name,short_name,city,state'])
            ->findOrFail($id);

        return response()->json($closing);
    }

    /**
     * Realiza o Fechamento do Exercício Financeiro do ano especificado (gerando snapshot)
     */
    public function closeExercise(Request $request): JsonResponse
    {
        $request->validate([
            'year' => 'required|integer|min:2000|max:2100',
            'closing_date' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        $institutionId = $request->user()->institution_id;
        $user = $request->user();
        $year = (int) $request->input('year');
        $closingDate = $request->input('closing_date') ?: now()->toDateString();

        // Verificar se já existe fechamento
        $existing = FinancialAnnualClosing::where('institution_id', $institutionId)
            ->where('year', $year)
            ->first();

        if ($existing && $existing->status === 'publicado_membros') {
            return response()->json([
                'message' => 'O exercício deste ano já foi encerrado e homologado para os membros. Não pode ser sobrescrito sem autorização do Conselho.'
            ], 422);
        }

        // Calcular valores do ano para o snapshot imutável
        $snapshot = $this->generateYearSnapshot($institutionId, $year);

        $closing = FinancialAnnualClosing::updateOrCreate(
            [
                'institution_id' => $institutionId,
                'year' => $year,
            ],
            [
                'closing_date' => $closingDate,
                'initial_balance' => $snapshot['initial_balance'],
                'total_revenues' => $snapshot['total_revenues'],
                'total_expenses' => $snapshot['total_expenses'],
                'final_balance' => $snapshot['final_balance'],
                'surplus_deficit' => $snapshot['surplus_deficit'],
                'summary_snapshot' => $snapshot,
                'status' => 'em_analise',
                'closed_by_user_id' => $user->id,
            ]
        );

        AuditLog::create([
            'user_id' => $user->id,
            'institution_id' => $institutionId,
            'action' => 'fechar_exercicio_financeiro',
            'entity_type' => 'FinancialAnnualClosing',
            'entity_id' => $closing->id,
            'details' => json_encode([
                'year' => $year,
                'total_revenues' => $closing->total_revenues,
                'total_expenses' => $closing->total_expenses,
                'final_balance' => $closing->final_balance,
            ]),
        ]);

        return response()->json([
            'message' => "Exercício de {$year} fechado com sucesso e submetido para apreciação do Conselho / Exame de Contas.",
            'closing' => $closing,
        ], 201);
    }

    /**
     * Parecer e Aprovação pelo Conselho / Comissão de Exame de Contas
     */
    public function approveConselho(Request $request, int $id): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        $user = $request->user();

        $request->validate([
            'parecer' => 'required|string|min:10',
        ]);

        $closing = FinancialAnnualClosing::where('institution_id', $institutionId)->findOrFail($id);

        $closing->update([
            'status' => 'aprovado_conselho',
            'conselho_parecer' => $request->input('parecer'),
            'approved_by_user_id' => $user->id,
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'institution_id' => $institutionId,
            'action' => 'aprovar_exercicio_conselho',
            'entity_type' => 'FinancialAnnualClosing',
            'entity_id' => $closing->id,
            'details' => json_encode(['year' => $closing->year]),
        ]);

        return response()->json([
            'message' => "Parecer do Conselho registrado e exercício de {$closing->year} aprovado.",
            'closing' => $closing,
        ]);
    }

    /**
     * Publicação para visualização simplificada na Área do Membro
     */
    public function publishToMembers(Request $request, int $id): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        $user = $request->user();

        $closing = FinancialAnnualClosing::where('institution_id', $institutionId)->findOrFail($id);

        $closing->update([
            'status' => 'publicado_membros',
            'published_at' => now(),
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'institution_id' => $institutionId,
            'action' => 'publicar_prestacao_contas_membros',
            'entity_type' => 'FinancialAnnualClosing',
            'entity_id' => $closing->id,
            'details' => json_encode(['year' => $closing->year]),
        ]);

        return response()->json([
            'message' => "Prestação de Contas do exercício {$closing->year} publicada com sucesso para a Área do Membro.",
            'closing' => $closing,
        ]);
    }

    /**
     * Visualização simplificada e transparente da Prestação de Contas para os Membros
     */
    public function publicMemberView(Request $request, int $institutionId, ?int $year = null): JsonResponse
    {
        $query = FinancialAnnualClosing::where('institution_id', $institutionId)
            ->where('status', 'publicado_membros')
            ->orderBy('year', 'desc');

        if ($year) {
            $closing = $query->where('year', $year)->first();
        } else {
            $closing = $query->first();
        }

        if (!$closing) {
            return response()->json([
                'message' => 'Nenhuma prestação de contas homologada está disponível no momento para esta igreja.',
                'available_years' => [],
            ], 404);
        }

        $availableYears = FinancialAnnualClosing::where('institution_id', $institutionId)
            ->where('status', 'publicado_membros')
            ->orderBy('year', 'desc')
            ->pluck('year');

        // Retorna apenas dados agregados e públicos (sem detalhes confidenciais de doadores)
        $snapshot = $closing->summary_snapshot;

        return response()->json([
            'institution' => [
                'id' => $closing->institution->id,
                'name' => $closing->institution->name,
                'city' => $closing->institution->city,
                'state' => $closing->institution->state,
            ],
            'year' => $closing->year,
            'closing_date' => $closing->closing_date,
            'published_at' => $closing->published_at,
            'conselho_parecer' => $closing->conselho_parecer,
            'financial_summary' => [
                'initial_balance' => $closing->initial_balance,
                'total_revenues' => $closing->total_revenues,
                'total_expenses' => $closing->total_expenses,
                'final_balance' => $closing->final_balance,
                'surplus_deficit' => $closing->surplus_deficit,
            ],
            'monthly_evolution' => $snapshot['monthly_evolution'] ?? [],
            'expenses_by_category' => $snapshot['expenses_by_category'] ?? [],
            'quarterly_summary' => $snapshot['quarters'] ?? [],
            'available_years' => $availableYears,
        ]);
    }

    private function generateYearSnapshot(int $institutionId, int $year): array
    {
        $transactions = FinancialTransaction::where('institution_id', $institutionId)
            ->whereYear('date', $year)
            ->where('status', 'pago')
            ->with(['category:id,name,type', 'account:id,name'])
            ->get();

        $coletas = ColetaDizimo::where('institution_id', $institutionId)
            ->whereYear('date', $year)
            ->where('status', 'fechada')
            ->get();

        $totalTithes = (float) $coletas->sum('total_dizimos');
        $totalOfferings = (float) $coletas->sum('total_ofertas');
        $totalCollected = $totalTithes + $totalOfferings;

        $txIncome = (float) $transactions->where('type', 'receita')->sum('amount');
        $totalRevenues = max($txIncome, $totalCollected);
        if ($txIncome > 0 && $totalCollected > 0 && $txIncome != $totalCollected) {
            $totalRevenues = $txIncome;
        }

        $totalExpenses = (float) $transactions->where('type', 'despesa')->sum('amount');
        $surplusDeficit = $totalRevenues - $totalExpenses;

        $accounts = FinancialAccount::where('institution_id', $institutionId)->where('is_active', true)->get();
        $finalBalance = (float) $accounts->sum('current_balance');
        $initialBalance = max(0, $finalBalance - $surplusDeficit);

        // Evolução Mensal
        $monthlyEvolution = [];
        $monthsNames = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
        for ($m = 1; $m <= 12; $m++) {
            $mTx = $transactions->filter(fn ($t) => $t->date && $t->date->month === $m);
            $rev = (float) $mTx->where('type', 'receita')->sum('amount');
            $exp = (float) $mTx->where('type', 'despesa')->sum('amount');

            if ($rev === 0.0) {
                $mColetas = $coletas->filter(fn ($c) => $c->date && $c->date->month === $m);
                $rev = (float) ($mColetas->sum('total_dizimos') + $mColetas->sum('total_ofertas'));
            }

            $monthlyEvolution[] = [
                'month' => $m,
                'name' => $monthsNames[$m - 1],
                'revenue' => round($rev, 2),
                'expense' => round($exp, 2),
                'balance' => round($rev - $exp, 2),
            ];
        }

        // Categorias de Despesas Agrupadas
        $expensesByCategory = [];
        $expenseTransactions = $transactions->where('type', 'despesa');
        $groupedCat = $expenseTransactions->groupBy('financial_category_id');
        foreach ($groupedCat as $catId => $catTxs) {
            $catName = $catTxs->first()->category?->name ?? 'Outras Despesas';
            $amount = (float) $catTxs->sum('amount');
            $percentage = $totalExpenses > 0 ? round(($amount / $totalExpenses) * 100, 1) : 0;
            $expensesByCategory[] = [
                'category_id' => $catId,
                'name' => $catName,
                'amount' => round($amount, 2),
                'percentage' => $percentage,
            ];
        }
        usort($expensesByCategory, fn ($a, $b) => $b['amount'] <=> $a['amount']);

        return [
            'initial_balance' => round($initialBalance, 2),
            'total_revenues' => round($totalRevenues, 2),
            'total_expenses' => round($totalExpenses, 2),
            'final_balance' => round($finalBalance, 2),
            'surplus_deficit' => round($surplusDeficit, 2),
            'monthly_evolution' => $monthlyEvolution,
            'expenses_by_category' => $expensesByCategory,
            'accounts_snapshot' => $accounts->map(fn ($a) => [
                'name' => $a->name,
                'type' => $a->account_type,
                'balance' => (float) $a->current_balance,
            ])->all(),
        ];
    }
}
