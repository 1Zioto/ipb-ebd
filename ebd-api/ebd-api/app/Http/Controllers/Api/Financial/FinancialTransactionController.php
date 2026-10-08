<?php

namespace App\Http\Controllers\Api\Financial;

use App\Http\Controllers\Controller;
use App\Models\FinancialMonthClosing;
use App\Models\FinancialTransaction;
use App\Services\Financial\FinancialService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FinancialTransactionController extends Controller
{
    public function __construct(
        protected FinancialService $financialService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $query = FinancialTransaction::with(['account', 'category', 'costCenter', 'creator'])
            ->where('institution_id', $institutionId);

        if ($request->filled('start_date')) {
            $query->where('date', '>=', $request->query('start_date'));
        }
        if ($request->filled('end_date')) {
            $query->where('date', '<=', $request->query('end_date'));
        }
        if ($request->filled('year') && ! $request->filled('start_date')) {
            $year = (int) $request->query('year');
            $month = $request->filled('month') ? (int) $request->query('month') : null;

            if ($month) {
                $query->whereYear('date', $year)->whereMonth('date', $month);
            } else {
                $query->whereYear('date', $year);
            }
        }
        if ($request->filled('type')) {
            $query->where('type', $request->query('type'));
        }
        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }
        if ($request->filled('account_id')) {
            $query->where('financial_account_id', $request->query('account_id'));
        }
        if ($request->filled('cost_center_id')) {
            $query->where('financial_cost_center_id', $request->query('cost_center_id'));
        }
        if ($request->filled('category_id')) {
            $query->where('financial_category_id', $request->query('category_id'));
        }
        if ($request->filled('search')) {
            $search = '%' . $request->query('search') . '%';
            $query->where(function ($q) use ($search) {
                $q->where('description', 'ilike', $search)
                  ->orWhere('entity_name', 'ilike', $search)
                  ->orWhere('document_number', 'ilike', $search);
            });
        }

        $transactions = $query->orderBy('date', 'desc')->orderBy('id', 'desc')->paginate(50);

        return response()->json($transactions);
    }

    public function store(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $validated = $request->validate([
            'financial_account_id' => 'required|exists:financial_accounts,id',
            'financial_category_id' => 'nullable|exists:financial_categories,id',
            'financial_cost_center_id' => 'nullable|exists:financial_cost_centers,id',
            'destination_account_id' => 'nullable|exists:financial_accounts,id',
            'type' => 'required|in:receita,despesa,transferencia',
            'date' => 'required|date',
            'competency_date' => 'nullable|date',
            'amount' => 'required|numeric|min:0.01',
            'description' => 'required|string|max:255',
            'entity_name' => 'nullable|string|max:180',
            'document_number' => 'nullable|string|max:80',
            'payment_method' => 'required|string|max:40',
            'status' => 'required|in:pago,pendente,cancelado',
            'paid_at' => 'nullable|date',
            'attachment_url' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
        ]);

        // Verifica se o mês está fechado
        $date = Carbon::parse($validated['date']);
        $closing = FinancialMonthClosing::where('institution_id', $institutionId)
            ->where('year', $date->year)
            ->where('month', $date->month)
            ->where('status', 'fechado')
            ->first();

        if ($closing) {
            return response()->json([
                'message' => 'O mês contábil correspondente a este lançamento já está fechado. Reabra o mês para fazer alterações.',
            ], 422);
        }

        $transaction = $this->financialService->createTransaction($validated, $request->user(), $institutionId);

        return response()->json($transaction->load(['account', 'category', 'costCenter']), 201);
    }

    public function show(Request $request, FinancialTransaction $transaction): JsonResponse
    {
        if ($request->user()->institution_id && $transaction->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        return response()->json($transaction->load(['account', 'destinationAccount', 'category', 'costCenter', 'creator']));
    }

    public function update(Request $request, FinancialTransaction $transaction): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        if ($institutionId && $transaction->institution_id !== $institutionId) {
            abort(403);
        }

        $validated = $request->validate([
            'financial_account_id' => 'required|exists:financial_accounts,id',
            'financial_category_id' => 'nullable|exists:financial_categories,id',
            'financial_cost_center_id' => 'nullable|exists:financial_cost_centers,id',
            'destination_account_id' => 'nullable|exists:financial_accounts,id',
            'type' => 'required|in:receita,despesa,transferencia',
            'date' => 'required|date',
            'competency_date' => 'nullable|date',
            'amount' => 'required|numeric|min:0.01',
            'description' => 'required|string|max:255',
            'entity_name' => 'nullable|string|max:180',
            'document_number' => 'nullable|string|max:80',
            'payment_method' => 'required|string|max:40',
            'status' => 'required|in:pago,pendente,cancelado',
            'paid_at' => 'nullable|date',
            'attachment_url' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
        ]);

        // Verifica se o mês original ou novo está fechado
        $origDate = Carbon::parse($transaction->date);
        $newDate = Carbon::parse($validated['date']);

        $closedOriginal = FinancialMonthClosing::where('institution_id', $institutionId)
            ->where('year', $origDate->year)->where('month', $origDate->month)
            ->where('status', 'fechado')->exists();

        $closedNew = FinancialMonthClosing::where('institution_id', $institutionId)
            ->where('year', $newDate->year)->where('month', $newDate->month)
            ->where('status', 'fechado')->exists();

        if ($closedOriginal || $closedNew) {
            return response()->json([
                'message' => 'O mês deste lançamento está fechado na contabilidade. Reabra o mês para alterá-lo.',
            ], 422);
        }

        $updated = $this->financialService->updateTransaction($transaction, $validated, $request->user());

        return response()->json($updated->load(['account', 'category', 'costCenter']));
    }

    public function destroy(Request $request, FinancialTransaction $transaction): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        if ($institutionId && $transaction->institution_id !== $institutionId) {
            abort(403);
        }

        $date = Carbon::parse($transaction->date);
        $closed = FinancialMonthClosing::where('institution_id', $institutionId)
            ->where('year', $date->year)->where('month', $date->month)
            ->where('status', 'fechado')->exists();

        if ($closed) {
            return response()->json([
                'message' => 'Não é permitido excluir lançamentos de um mês fechado.',
            ], 422);
        }

        $this->financialService->deleteTransaction($transaction, $request->user());

        return response()->json(['message' => 'Lançamento excluído com sucesso.']);
    }

    public function summary(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        $year = (int) ($request->query('year') ?: now()->year);
        $month = (int) ($request->query('month') ?: now()->month);

        $startDate = Carbon::createFromDate($year, $month, 1)->startOfMonth()->toDateString();
        $endDate = Carbon::createFromDate($year, $month, 1)->endOfMonth()->toDateString();

        $incomesPaid = (float) FinancialTransaction::where('institution_id', $institutionId)
            ->where('type', 'receita')
            ->where('status', 'pago')
            ->whereBetween('date', [$startDate, $endDate])
            ->sum('amount');

        $expensesPaid = (float) FinancialTransaction::where('institution_id', $institutionId)
            ->where('type', 'despesa')
            ->where('status', 'pago')
            ->whereBetween('date', [$startDate, $endDate])
            ->sum('amount');

        $incomesPending = (float) FinancialTransaction::where('institution_id', $institutionId)
            ->where('type', 'receita')
            ->where('status', 'pendente')
            ->whereBetween('date', [$startDate, $endDate])
            ->sum('amount');

        $expensesPending = (float) FinancialTransaction::where('institution_id', $institutionId)
            ->where('type', 'despesa')
            ->where('status', 'pendente')
            ->whereBetween('date', [$startDate, $endDate])
            ->sum('amount');

        // Total em caixa / contas no momento
        $accountsBalance = (float) \App\Models\FinancialAccount::where('institution_id', $institutionId)
            ->where('is_active', true)
            ->sum('current_balance');

        return response()->json([
            'year' => $year,
            'month' => $month,
            'accounts_total_balance' => round($accountsBalance, 2),
            'incomes_paid' => round($incomesPaid, 2),
            'expenses_paid' => round($expensesPaid, 2),
            'net_paid' => round($incomesPaid - $expensesPaid, 2),
            'incomes_pending' => round($incomesPending, 2),
            'expenses_pending' => round($expensesPending, 2),
        ]);
    }
}
