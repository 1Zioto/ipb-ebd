<?php

namespace App\Http\Controllers\Api\Financial;

use App\Http\Controllers\Controller;
use App\Models\FinancialCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FinancialCategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $query = FinancialCategory::where('institution_id', $institutionId)
            ->with('parent')
            ->orderBy('code', 'asc')
            ->orderBy('name', 'asc');

        if ($request->filled('type')) {
            $query->where('type', $request->query('type'));
        }

        if ($request->boolean('tree')) {
            $categories = FinancialCategory::where('institution_id', $institutionId)
                ->whereNull('parent_id')
                ->with(['children' => fn ($q) => $q->orderBy('code', 'asc')])
                ->when($request->filled('type'), fn ($q) => $q->where('type', $request->query('type')))
                ->orderBy('code', 'asc')
                ->get();
            return response()->json($categories);
        }

        return response()->json($query->get());
    }

    public function store(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $validated = $request->validate([
            'parent_id' => 'nullable|exists:financial_categories,id',
            'code' => 'nullable|string|max:30',
            'name' => 'required|string|max:120',
            'type' => 'required|in:receita,despesa',
            'description' => 'nullable|string|max:255',
        ]);

        $category = FinancialCategory::create($validated + [
            'institution_id' => $institutionId,
            'is_active' => true,
        ]);

        return response()->json($category->load('parent'), 201);
    }

    public function show(Request $request, FinancialCategory $category): JsonResponse
    {
        if ($request->user()->institution_id && $category->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        return response()->json($category->load(['parent', 'children']));
    }

    public function update(Request $request, FinancialCategory $category): JsonResponse
    {
        if ($request->user()->institution_id && $category->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        $validated = $request->validate([
            'parent_id' => 'nullable|exists:financial_categories,id',
            'code' => 'nullable|string|max:30',
            'name' => 'required|string|max:120',
            'type' => 'required|in:receita,despesa',
            'description' => 'nullable|string|max:255',
            'is_active' => 'boolean',
        ]);

        $category->update($validated);

        return response()->json($category->load('parent'));
    }

    public function destroy(Request $request, FinancialCategory $category): JsonResponse
    {
        if ($request->user()->institution_id && $category->institution_id !== $request->user()->institution_id) {
            abort(403);
        }

        if ($category->transactions()->exists() || $category->children()->exists()) {
            $category->update(['is_active' => false]);
            return response()->json(['message' => 'Categoria desativada pois possui lançamentos ou subcategorias vinculadas.']);
        }

        $category->delete();

        return response()->json(['message' => 'Categoria removida com sucesso.']);
    }
}
