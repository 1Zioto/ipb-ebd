<?php

namespace App\Http\Controllers\Api\Dizimos;

use App\Http\Controllers\Controller;
use App\Models\ColetaDizimo;
use App\Models\ConsolidacaoDizimoMensal;
use App\Models\LancamentoDizimo;
use App\Services\Dizimos\AuditoriaDizimosService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TithesReportController extends Controller
{
    public function general(Request $request): JsonResponse
    {
        $year = (int) ($request->query('year') ?: now()->year);
        $month = $request->query('month') ? (int) $request->query('month') : null;

        $query = ColetaDizimo::query()->whereYear('date', $year);

        if ($month) {
            $query->whereMonth('date', $month);
        }

        $collectionsCount = (clone $query)->count();
        $totalAmount = (float) (clone $query)->sum('total_amount');
        $totalEntries = (int) (clone $query)->sum('entry_count');
        $totalUnidentified = (int) (clone $query)->sum('unidentified_count');

        // Evolução mensal agregada
        $monthlyTotals = ColetaDizimo::query()
            ->whereYear('date', $year)
            ->select(
                DB::raw('EXTRACT(MONTH FROM date) as month_num'),
                DB::raw('SUM(total_amount) as total_amount'),
                DB::raw('SUM(entry_count) as total_entries'),
                DB::raw('COUNT(id) as collection_count')
            )
            ->groupBy(DB::raw('EXTRACT(MONTH FROM date)'))
            ->orderBy('month_num')
            ->get();

        return response()->json([
            'filter' => [
                'year' => $year,
                'month' => $month,
            ],
            'summary' => [
                'collections_count' => $collectionsCount,
                'total_amount' => round($totalAmount, 2),
                'total_entries' => $totalEntries,
                'total_unidentified' => $totalUnidentified,
                'average_per_collection' => $collectionsCount > 0 ? round($totalAmount / $collectionsCount, 2) : 0.00,
            ],
            'monthly_breakdown' => $monthlyTotals,
        ]);
    }

    public function export(Request $request): JsonResponse
    {
        AuditoriaDizimosService::log('relatorios.exportar', 'relatorio_dizimos', null, [
            'year' => $request->query('year'),
            'format' => $request->query('format', 'json'),
        ], $request->user());

        $reportData = $this->general($request)->getData(true);

        return response()->json([
            'exported_at' => now()->toIso8601String(),
            'exported_by' => $request->user()->name,
            'data' => $reportData,
        ]);
    }
}
