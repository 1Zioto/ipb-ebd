<?php

namespace App\Services\Financial;

use App\Models\ColetaDizimo;
use App\Models\FinancialAccount;
use App\Models\FinancialCategory;
use App\Models\FinancialCostCenter;
use App\Models\FinancialMonthClosing;
use App\Models\FinancialTransaction;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class FinancialService
{
    /**
     * Cria uma transação e atualiza o saldo das contas afetadas.
     */
    public function createTransaction(array $data, User $user, ?int $institutionId): FinancialTransaction
    {
        return DB::transaction(function () use ($data, $user, $institutionId) {
            $data['institution_id'] = $institutionId;
            $data['created_by'] = $user->id;

            if (($data['status'] ?? 'pago') === 'pago' && empty($data['paid_at'])) {
                $data['paid_at'] = now();
            }

            $transaction = FinancialTransaction::create($data);

            // Atualiza saldo da conta de origem
            if ($transaction->account) {
                $transaction->account->recalculateBalance();
            }

            // Se for transferência, atualiza conta de destino
            if ($transaction->type === 'transferencia' && $transaction->destinationAccount) {
                $transaction->destinationAccount->recalculateBalance();
            }

            return $transaction;
        });
    }

    /**
     * Atualiza uma transação existente e sincroniza os saldos.
     */
    public function updateTransaction(FinancialTransaction $transaction, array $data, User $user): FinancialTransaction
    {
        return DB::transaction(function () use ($transaction, $data, $user) {
            $oldAccount = $transaction->account;
            $oldDestAccount = $transaction->destinationAccount;

            $data['updated_by'] = $user->id;
            $transaction->update($data);

            if ($oldAccount) {
                $oldAccount->recalculateBalance();
            }
            if ($oldDestAccount && $oldDestAccount->id !== $oldAccount?->id) {
                $oldDestAccount->recalculateBalance();
            }

            if ($transaction->account && $transaction->account->id !== $oldAccount?->id) {
                $transaction->account->recalculateBalance();
            }
            if ($transaction->destinationAccount && $transaction->destinationAccount->id !== $oldDestAccount?->id) {
                $transaction->destinationAccount->recalculateBalance();
            }

            return $transaction;
        });
    }

    /**
     * Exclui (soft delete) uma transação e recalcula saldos.
     */
    public function deleteTransaction(FinancialTransaction $transaction, User $user): void
    {
        DB::transaction(function () use ($transaction, $user) {
            $account = $transaction->account;
            $destAccount = $transaction->destinationAccount;

            $transaction->update(['updated_by' => $user->id]);
            $transaction->delete();

            if ($account) {
                $account->recalculateBalance();
            }
            if ($destAccount) {
                $destAccount->recalculateBalance();
            }
        });
    }

    /**
     * Sincroniza uma Coleta de Dízimos com o Livro Caixa Financeiro.
     */
    public function syncFromColeta(ColetaDizimo $coleta, User $user): ?FinancialTransaction
    {
        return DB::transaction(function () use ($coleta, $user) {
            $institutionId = $coleta->institution_id;

            // Busca ou define a categoria de Dízimos
            $category = FinancialCategory::where('institution_id', $institutionId)
                ->where(function ($q) {
                    $q->where('code', '1.01')->orWhere('name', 'ilike', '%dízimo%');
                })
                ->first();

            // Busca o centro de custo de Conselho/Geral
            $costCenter = FinancialCostCenter::where('institution_id', $institutionId)
                ->where(function ($q) {
                    $q->where('code', 'CC-01')->orWhere('name', 'ilike', '%conselho%');
                })
                ->first();

            // Busca a conta padrão ativa (primeira corrente ou caixa)
            $account = FinancialAccount::where('institution_id', $institutionId)
                ->where('is_active', true)
                ->orderByRaw("CASE WHEN account_type = 'corrente' THEN 1 ELSE 2 END")
                ->first();

            if (! $account) {
                // Cria conta padrão se não existir nenhuma
                $account = FinancialAccount::create([
                    'institution_id' => $institutionId,
                    'name' => 'Caixa Tesouraria',
                    'account_type' => 'caixa',
                    'initial_balance' => 0.00,
                    'current_balance' => 0.00,
                    'is_active' => true,
                ]);
            }

            $transaction = FinancialTransaction::where('coleta_id', $coleta->id)->first();

            if ($coleta->status === 'Fechada') {
                $data = [
                    'institution_id' => $institutionId,
                    'financial_account_id' => $account->id,
                    'financial_category_id' => $category?->id,
                    'financial_cost_center_id' => $costCenter?->id,
                    'type' => 'receita',
                    'date' => $coleta->date,
                    'competency_date' => $coleta->date,
                    'amount' => $coleta->total_amount,
                    'description' => "Coleta de Dízimos #{$coleta->id} - " . ($coleta->service_meeting ?: 'Culto') . ($coleta->description ? ' (' . $coleta->description . ')' : ''),
                    'entity_name' => 'Membros e Contribuintes',
                    'document_number' => "COL-{$coleta->id}",
                    'payment_method' => 'dinheiro',
                    'status' => 'pago',
                    'paid_at' => $coleta->closed_at ?: now(),
                    'coleta_id' => $coleta->id,
                ];

                if ($transaction) {
                    $transaction->update($data + ['updated_by' => $user->id]);
                } else {
                    $transaction = FinancialTransaction::create($data + ['created_by' => $user->id]);
                }

                $account->recalculateBalance();

                return $transaction;
            } else {
                // Se a coleta foi reaberta ou cancelada
                if ($transaction) {
                    $transaction->update(['status' => 'pendente', 'updated_by' => $user->id]);
                    $account->recalculateBalance();
                }

                return $transaction;
            }
        });
    }

    /**
     * Obtém o Livro Caixa detalhado para um período específico.
     */
    public function getLedger(array $filters, ?int $institutionId): array
    {
        $year = (int) ($filters['year'] ?? now()->year);
        $month = isset($filters['month']) ? (int) $filters['month'] : null;

        if ($month) {
            $startDate = Carbon::createFromDate($year, $month, 1)->startOfMonth()->toDateString();
            $endDate = Carbon::createFromDate($year, $month, 1)->endOfMonth()->toDateString();
        } else {
            $startDate = Carbon::createFromDate($year, 1, 1)->startOfYear()->toDateString();
            $endDate = Carbon::createFromDate($year, 12, 31)->endOfYear()->toDateString();
        }

        $accountId = $filters['account_id'] ?? null;
        $costCenterId = $filters['cost_center_id'] ?? null;
        $categoryId = $filters['category_id'] ?? null;

        // 1. Saldo Anterior (antes de $startDate)
        $initialBalanceAccounts = FinancialAccount::where('institution_id', $institutionId)
            ->when($accountId, fn ($q) => $q->where('id', $accountId))
            ->sum('initial_balance');

        $priorIncomesQuery = FinancialTransaction::where('institution_id', $institutionId)
            ->where('status', 'pago')
            ->where('date', '<', $startDate)
            ->when($accountId, fn ($q) => $q->where('financial_account_id', $accountId))
            ->when($costCenterId, fn ($q) => $q->where('financial_cost_center_id', $costCenterId))
            ->when($categoryId, fn ($q) => $q->where('financial_category_id', $categoryId));

        $priorIncomes = (float) (clone $priorIncomesQuery)->where('type', 'receita')->sum('amount');
        $priorExpenses = (float) (clone $priorIncomesQuery)->where('type', 'despesa')->sum('amount');

        $openingBalance = round((float) $initialBalanceAccounts + $priorIncomes - $priorExpenses, 2);

        // 2. Transações do Período
        $transactionsQuery = FinancialTransaction::with(['account', 'category', 'costCenter', 'creator'])
            ->where('institution_id', $institutionId)
            ->whereBetween('date', [$startDate, $endDate])
            ->when($accountId, fn ($q) => $q->where('financial_account_id', $accountId))
            ->when($costCenterId, fn ($q) => $q->where('financial_cost_center_id', $costCenterId))
            ->when($categoryId, fn ($q) => $q->where('financial_category_id', $categoryId))
            ->orderBy('date', 'asc')
            ->orderBy('id', 'asc');

        $transactions = $transactionsQuery->get();

        $runningBalance = $openingBalance;
        $periodIncome = 0.00;
        $periodExpense = 0.00;

        $items = [];
        foreach ($transactions as $tx) {
            $amount = (float) $tx->amount;
            if ($tx->status === 'pago') {
                if ($tx->type === 'receita') {
                    $runningBalance += $amount;
                    $periodIncome += $amount;
                } elseif ($tx->type === 'despesa') {
                    $runningBalance -= $amount;
                    $periodExpense += $amount;
                }
            }

            $txArray = $tx->toArray();
            $txArray['running_balance'] = round($runningBalance, 2);
            $items[] = $txArray;
        }

        // Verifica status de fechamento do mês
        $closing = null;
        if ($month) {
            $closing = FinancialMonthClosing::where('institution_id', $institutionId)
                ->where('year', $year)
                ->where('month', $month)
                ->first();
        }

        return [
            'period' => [
                'year' => $year,
                'month' => $month,
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
            'closing_status' => $closing ? $closing->status : 'aberto',
            'closing_info' => $closing,
            'summary' => [
                'opening_balance' => round($openingBalance, 2),
                'total_income' => round($periodIncome, 2),
                'total_expense' => round($periodExpense, 2),
                'net_result' => round($periodIncome - $periodExpense, 2),
                'closing_balance' => round($runningBalance, 2),
                'transactions_count' => count($items),
            ],
            'transactions' => $items,
        ];
    }

    /**
     * Balancete Mensal/Anual consolidado por Categorias e Centros de Custo.
     */
    public function getTrialBalance(int $year, ?int $month, ?int $institutionId): array
    {
        $ledger = $this->getLedger(['year' => $year, 'month' => $month], $institutionId);

        // Agrupamento por Categorias Contábeis
        $categoriesBreakdown = FinancialTransaction::query()
            ->leftJoin('financial_categories', 'financial_transactions.financial_category_id', '=', 'financial_categories.id')
            ->where('financial_transactions.institution_id', $institutionId)
            ->where('financial_transactions.status', 'pago')
            ->whereBetween('financial_transactions.date', [$ledger['period']['start_date'], $ledger['period']['end_date']])
            ->select(
                'financial_categories.id as category_id',
                'financial_categories.code as category_code',
                'financial_categories.name as category_name',
                'financial_transactions.type as transaction_type',
                DB::raw('COUNT(financial_transactions.id) as count'),
                DB::raw('SUM(financial_transactions.amount) as total_amount')
            )
            ->groupBy('financial_categories.id', 'financial_categories.code', 'financial_categories.name', 'financial_transactions.type')
            ->orderBy('category_code', 'asc')
            ->get();

        // Agrupamento por Centros de Custo
        $costCentersBreakdown = FinancialTransaction::query()
            ->leftJoin('financial_cost_centers', 'financial_transactions.financial_cost_center_id', '=', 'financial_cost_centers.id')
            ->where('financial_transactions.institution_id', $institutionId)
            ->where('financial_transactions.status', 'pago')
            ->whereBetween('financial_transactions.date', [$ledger['period']['start_date'], $ledger['period']['end_date']])
            ->select(
                'financial_cost_centers.id as cost_center_id',
                'financial_cost_centers.code as cost_center_code',
                'financial_cost_centers.name as cost_center_name',
                'financial_transactions.type as transaction_type',
                DB::raw('COUNT(financial_transactions.id) as count'),
                DB::raw('SUM(financial_transactions.amount) as total_amount')
            )
            ->groupBy('financial_cost_centers.id', 'financial_cost_centers.code', 'financial_cost_centers.name', 'financial_transactions.type')
            ->orderBy('cost_center_code', 'asc')
            ->get();

        return [
            'period' => $ledger['period'],
            'summary' => $ledger['summary'],
            'closing_status' => $ledger['closing_status'],
            'categories' => $categoriesBreakdown,
            'cost_centers' => $costCentersBreakdown,
        ];
    }

    /**
     * Realiza o fechamento mensal da contabilidade.
     */
    public function closeMonth(int $year, int $month, ?string $notes, User $user, ?int $institutionId): FinancialMonthClosing
    {
        $ledger = $this->getLedger(['year' => $year, 'month' => $month], $institutionId);

        return FinancialMonthClosing::updateOrCreate(
            [
                'institution_id' => $institutionId,
                'year' => $year,
                'month' => $month,
            ],
            [
                'status' => 'fechado',
                'opening_balance' => $ledger['summary']['opening_balance'],
                'total_income' => $ledger['summary']['total_income'],
                'total_expense' => $ledger['summary']['total_expense'],
                'closing_balance' => $ledger['summary']['closing_balance'],
                'closed_by' => $user->id,
                'closed_at' => now(),
                'accounting_notes' => $notes,
            ]
        );
    }

    /**
     * Reabre um mês fechado.
     */
    public function reopenMonth(int $year, int $month, User $user, ?int $institutionId): FinancialMonthClosing
    {
        $closing = FinancialMonthClosing::where('institution_id', $institutionId)
            ->where('year', $year)
            ->where('month', $month)
            ->firstOrFail();

        $closing->update([
            'status' => 'aberto',
            'accounting_notes' => ($closing->accounting_notes ? $closing->accounting_notes . "\n" : '') . "Reaberto em " . now()->format('d/m/Y H:i') . " por " . $user->name,
        ]);

        return $closing;
    }
}
