<?php

namespace App\Http\Controllers\Api\Financial;

use App\Http\Controllers\Controller;
use App\Models\FinancialAccount;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FinancialAccountController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $accounts = FinancialAccount::where('institution_id', $institutionId)
            ->withCount(['transactions' => fn ($q) => $q->where('status', 'pago')])
            ->orderBy('is_active', 'desc')
            ->orderBy('name', 'asc')
            ->get();

        return response()->json($accounts);
    }

    public function store(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $validated = $request->validate([
            'name' => 'required|string|max:120',
            'account_type' => 'required|in:caixa,corrente,poupanca,aplicacao',
            'bank_name' => 'nullable|string|max:80',
            'agency' => 'nullable|string|max:30',
            'account_number' => 'nullable|string|max:40',
            'initial_balance' => 'required|numeric',
            'notes' => 'nullable|string',
        ]);

        $account = FinancialAccount::create($validated + [
            'institution_id' => $institutionId,
            'current_balance' => $validated['initial_balance'],
            'is_active' => true,
        ]);

        return response()->json($account, 201);
    }

    public function show(Request $request, FinancialAccount $account): JsonResponse
    {
        if ($request->user()->institution_id && $account->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        return response()->json($account->load(['transactions' => fn ($q) => $q->latest()->limit(20)]));
    }

    public function update(Request $request, FinancialAccount $account): JsonResponse
    {
        if ($request->user()->institution_id && $account->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:120',
            'account_type' => 'required|in:caixa,corrente,poupanca,aplicacao',
            'bank_name' => 'nullable|string|max:80',
            'agency' => 'nullable|string|max:30',
            'account_number' => 'nullable|string|max:40',
            'initial_balance' => 'required|numeric',
            'is_active' => 'boolean',
            'notes' => 'nullable|string',
        ]);

        $account->update($validated);
        $account->recalculateBalance();

        return response()->json($account);
    }

    public function destroy(Request $request, FinancialAccount $account): JsonResponse
    {
        if ($request->user()->institution_id && $account->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        if ($account->transactions()->exists()) {
            $account->update(['is_active' => false]);
            return response()->json(['message' => 'Conta desativada pois possui lançamentos vinculados.']);
        }

        $account->delete();

        return response()->json(['message' => 'Conta removida com sucesso.']);
    }

    public function recalculate(Request $request, FinancialAccount $account): JsonResponse
    {
        if ($request->user()->institution_id && $account->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        $newBalance = $account->recalculateBalance();

        return response()->json([
            'message' => 'Saldo recalculado com sucesso.',
            'current_balance' => $newBalance,
        ]);
    }
}
