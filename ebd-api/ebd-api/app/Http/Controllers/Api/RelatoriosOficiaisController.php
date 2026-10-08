<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FinancialTransaction;
use App\Models\Person;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RelatoriosOficiaisController extends Controller
{
    /** Termo de Aprovação do Balancete com Parecer da Comissão de Exame de Contas */
    public function termoBalancete(Request $request): JsonResponse
    {
        $year = (int) $request->query('year', now()->year);
        $month = (int) $request->query('month', now()->month);

        $entradas = FinancialTransaction::whereYear('competency_date', $year)
            ->whereMonth('competency_date', $month)
            ->where('type', 'income')
            ->where('status', 'confirmed')
            ->sum('amount');

        $saidas = FinancialTransaction::whereYear('competency_date', $year)
            ->whereMonth('competency_date', $month)
            ->where('type', 'expense')
            ->where('status', 'confirmed')
            ->sum('amount');

        $saldoAnterior = FinancialTransaction::where('competency_date', '<', "{$year}-" . str_pad($month, 2, '0', STR_PAD_LEFT) . "-01")
            ->where('status', 'confirmed')
            ->selectRaw("SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) as saldo")
            ->value('saldo') ?? 0.0;

        $saldoAtual = $saldoAnterior + $entradas - $saidas;

        $meses = [
            1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
            5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
            9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro'
        ];

        return response()->json([
            'ano' => $year,
            'mes' => $month,
            'mes_extenso' => $meses[$month] ?? '',
            'igreja' => 'Igreja Presbiteriana em Campo Verde',
            'cnpj' => '04.839.291/0001-44',
            'saldo_anterior' => round($saldoAnterior, 2),
            'entradas' => round($entradas, 2),
            'saidas' => round($saidas, 2),
            'saldo_atual' => round($saldoAtual, 2),
            'parecer_texto' => "A Comissão de Exame de Contas da Igreja Presbiteriana em Campo Verde, reunida na forma canônica, examinou minuciosamente os livros, comprovantes, extratos bancários e documentos fiscais referentes ao mês de {$meses[$month]} de {$year}. Constatou-se a exatidão dos lançamentos, a lisura das operações financeiras e a perfeita consonância com o orçamento e as resoluções do Conselho da Igreja. Pelo exposto, esta Comissão é de parecer unânime que as presentes contas sejam APROVADAS com louvor ao Senhor.",
            'assinaturas' => [
                ['titulo' => 'Tesoureiro da Igreja', 'nome' => 'Presb. Tesoureiro Responsável'],
                ['titulo' => 'Relator da Comissão de Exame de Contas', 'nome' => 'Relator da Comissão'],
                ['titulo' => 'Membro da Comissão de Exame de Contas', 'nome' => 'Membro da Comissão'],
            ],
            'data_emissao' => now()->format('d/m/Y'),
        ]);
    }

    /** Ficha Cadastral Ministerial Individual */
    public function fichaMinisterial(Request $request, Person $person): JsonResponse
    {
        $person->load([
            'families.head',
            'enrollments.class',
            'teachingClasses.class',
        ]);

        return response()->json([
            'person' => $person,
            'igreja' => 'Igreja Presbiteriana em Campo Verde',
            'presbiterio' => 'Presbitério Campo Verde (PCVD) / Sínodo Mato Grosso',
            'pastor_presidente' => 'Rev. Carlos Eduardo',
            'data_emissao' => now()->format('d/m/Y'),
        ]);
    }
}
