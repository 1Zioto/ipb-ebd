<?php

namespace App\Http\Controllers\Api\Financial;

use App\Http\Controllers\Controller;
use App\Models\FinancialCostCenter;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FinancialCostCenterController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        $year = (int) ($request->query('year') ?: now()->year);
        $month = $request->filled('month') ? (int) $request->query('month') : null;

        $startDate = $month
            ? Carbon::createFromDate($year, $month, 1)->startOfMonth()->toDateString()
            : Carbon::createFromDate($year, 1, 1)->startOfYear()->toDateString();
        $endDate = $month
            ? Carbon::createFromDate($year, $month, 1)->endOfMonth()->toDateString()
            : Carbon::createFromDate($year, 12, 31)->endOfYear()->toDateString();

        $costCenters = FinancialCostCenter::where('institution_id', $institutionId)
            ->withCount(['transactions' => fn ($q) => $q->where('status', 'pago')])
            ->orderBy('is_active', 'desc')
            ->orderBy('code', 'asc')
            ->orderBy('name', 'asc')
            ->get();

        // Agrega totais de despesas no período para cada centro de custo
        $expensesByCenter = DB::table('financial_transactions')
            ->where('institution_id', $institutionId)
            ->where('type', 'despesa')
            ->where('status', 'pago')
            ->whereBetween('date', [$startDate, $endDate])
            ->whereNotNull('financial_cost_center_id')
            ->groupBy('financial_cost_center_id')
            ->select('financial_cost_center_id', DB::raw('SUM(amount) as total_expense'))
            ->pluck('total_expense', 'financial_cost_center_id');

        $result = $costCenters->map(function ($cc) use ($expensesByCenter) {
            $totalExpense = (float) ($expensesByCenter[$cc->id] ?? 0.00);
            $ccArray = $cc->toArray();
            $ccArray['period_expense'] = round($totalExpense, 2);
            $ccArray['budget_percentage'] = $cc->budget_limit && $cc->budget_limit > 0
                ? round(($totalExpense / (float) $cc->budget_limit) * 100, 1)
                : null;
            return $ccArray;
        });

        return response()->json($result);
    }

    public function store(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $validated = $request->validate([
            'code' => 'nullable|string|max:30',
            'name' => 'required|string|max:120',
            'description' => 'nullable|string|max:255',
            'budget_limit' => 'nullable|numeric|min:0',
        ]);

        $costCenter = FinancialCostCenter::create($validated + [
            'institution_id' => $institutionId,
            'is_active' => true,
        ]);

        return response()->json($costCenter, 201);
    }

    public function show(Request $request, FinancialCostCenter $costCenter): JsonResponse
    {
        if ($request->user()->institution_id && $costCenter->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        return response()->json($costCenter->load(['transactions' => fn ($q) => $q->latest()->limit(20)]));
    }

    public function update(Request $request, FinancialCostCenter $costCenter): JsonResponse
    {
        if ($request->user()->institution_id && $costCenter->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        $validated = $request->validate([
            'code' => 'nullable|string|max:30',
            'name' => 'required|string|max:120',
            'description' => 'nullable|string|max:255',
            'budget_limit' => 'nullable|numeric|min:0',
            'is_active' => 'boolean',
        ]);

        $costCenter->update($validated);

        return response()->json($costCenter);
    }

    public function destroy(Request $request, FinancialCostCenter $costCenter): JsonResponse
    {
        if ($request->user()->institution_id && $costCenter->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        if ($costCenter->transactions()->exists()) {
            $costCenter->update(['is_active' => false]);
            return response()->json(['message' => 'Centro de custo desativado pois possui movimentações vinculadas.']);
        }

        $costCenter->delete();

        return response()->json(['message' => 'Centro de custo removido com sucesso.']);
    }
}
