<?php

namespace App\Http\Controllers\Api\Financial;

use App\Http\Controllers\Controller;
use App\Services\Financial\FinancialService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class FinancialAccountingController extends Controller
{
    public function __construct(
        protected FinancialService $financialService
    ) {}

    public function ledger(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        $filters = [
            'year' => (int) ($request->query('year') ?: now()->year),
            'month' => $request->filled('month') ? (int) $request->query('month') : null,
            'account_id' => $request->query('account_id'),
            'cost_center_id' => $request->query('cost_center_id'),
            'category_id' => $request->query('category_id'),
        ];

        $ledger = $this->financialService->getLedger($filters, $institutionId);

        return response()->json($ledger);
    }

    public function trialBalance(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        $year = (int) ($request->query('year') ?: now()->year);
        $month = $request->filled('month') ? (int) $request->query('month') : null;

        $trialBalance = $this->financialService->getTrialBalance($year, $month, $institutionId);

        return response()->json($trialBalance);
    }

    public function closeMonth(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $validated = $request->validate([
            'year' => 'required|integer|min:2000|max:2100',
            'month' => 'required|integer|min:1|max:12',
            'notes' => 'nullable|string|max:1000',
        ]);

        $closing = $this->financialService->closeMonth(
            $validated['year'],
            $validated['month'],
            $validated['notes'] ?? null,
            $request->user(),
            $institutionId
        );

        return response()->json([
            'message' => "Mês {$validated['month']}/{$validated['year']} fechado com sucesso para a contabilidade.",
            'closing' => $closing,
        ]);
    }

    public function reopenMonth(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $validated = $request->validate([
            'year' => 'required|integer|min:2000|max:2100',
            'month' => 'required|integer|min:1|max:12',
        ]);

        $closing = $this->financialService->reopenMonth(
            $validated['year'],
            $validated['month'],
            $request->user(),
            $institutionId
        );

        return response()->json([
            'message' => "Mês {$validated['month']}/{$validated['year']} reaberto com sucesso.",
            'closing' => $closing,
        ]);
    }

    public function exportCsv(Request $request): StreamedResponse
    {
        $institutionId = $request->user()->institution_id;
        $year = (int) ($request->query('year') ?: now()->year);
        $month = $request->filled('month') ? (int) $request->query('month') : null;

        $filters = [
            'year' => $year,
            'month' => $month,
            'account_id' => $request->query('account_id'),
            'cost_center_id' => $request->query('cost_center_id'),
            'category_id' => $request->query('category_id'),
        ];

        $ledger = $this->financialService->getLedger($filters, $institutionId);
        $periodLabel = $month ? sprintf('%02d-%d', $month, $year) : (string) $year;
        $filename = "livro_caixa_contabilidade_{$periodLabel}.csv";

        return response()->streamDownload(function () use ($ledger) {
            $handle = fopen('php://output', 'w');
            // BOM UTF-8 para abrir no Excel em português sem corromper acentos
            fprintf($handle, chr(0xEF).chr(0xBB).chr(0xBF));

            // Cabeçalho institucional
            fputcsv($handle, ['RELATÓRIO FINANCEIRO E CONTÁBIL - LIVRO CAIXA'], ';');
            fputcsv($handle, ['Período:', $ledger['period']['start_date'] . ' a ' . $ledger['period']['end_date']], ';');
            fputcsv($handle, ['Status de Fechamento:', strtoupper($ledger['closing_status'])], ';');
            fputcsv($handle, ['Saldo Anterior (R$):', number_format($ledger['summary']['opening_balance'], 2, ',', '.')], ';');
            fputcsv($handle, ['Total de Receitas (R$):', number_format($ledger['summary']['total_income'], 2, ',', '.')], ';');
            fputcsv($handle, ['Total de Despesas (R$):', number_format($ledger['summary']['total_expense'], 2, ',', '.')], ';');
            fputcsv($handle, ['Resultado do Período (R$):', number_format($ledger['summary']['net_result'], 2, ',', '.')], ';');
            fputcsv($handle, ['Saldo Final (R$):', number_format($ledger['summary']['closing_balance'], 2, ',', '.')], ';');
            fputcsv($handle, [], ';');

            // Colunas da tabela
            fputcsv($handle, [
                'Data',
                'Tipo',
                'Código Contábil',
                'Categoria',
                'Centro de Custo',
                'Conta / Caixa',
                'Descrição / Histórico',
                'Favorecido / Fornecedor',
                'Nº Documento',
                'Forma de Pagamento',
                'Status',
                'Entrada (R$)',
                'Saída (R$)',
                'Saldo Acumulado (R$)',
            ], ';');

            foreach ($ledger['transactions'] as $tx) {
                $isIncome = ($tx['type'] === 'receita');
                $isExpense = ($tx['type'] === 'despesa');
                $amount = (float) $tx['amount'];

                fputcsv($handle, [
                    Carbon::parse($tx['date'])->format('d/m/Y'),
                    ucfirst($tx['type']),
                    $tx['category']['code'] ?? '',
                    $tx['category']['name'] ?? '',
                    $tx['cost_center']['name'] ?? '',
                    $tx['account']['name'] ?? '',
                    $tx['description'],
                    $tx['entity_name'] ?? '',
                    $tx['document_number'] ?? '',
                    strtoupper($tx['payment_method']),
                    ucfirst($tx['status']),
                    $isIncome ? number_format($amount, 2, ',', '.') : '0,00',
                    $isExpense ? number_format($amount, 2, ',', '.') : '0,00',
                    number_format((float) ($tx['running_balance'] ?? 0), 2, ',', '.'),
                ], ';');
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ]);
    }
}
