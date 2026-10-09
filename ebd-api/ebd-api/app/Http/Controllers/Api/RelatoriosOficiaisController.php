<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FinancialTransaction;
use App\Models\Person;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RelatoriosOficiaisController extends Controller
{
    /** Lista de Pastores e Ministros Ativos da Igreja para seleção em Documentos Oficiais */
    public function pastores(Request $request): JsonResponse
    {
        $pastores = $this->getPastoresAtivos();
        return response()->json($pastores);
    }

    /** Helper para recuperar pastores ativos ordenados (titular primeiro) */
    private function getPastoresAtivos()
    {
        return User::where('is_pastor', true)
            ->where('is_active', true)
            ->orderByDesc('is_pastor_titular')
            ->orderBy('name')
            ->get(['id', 'name', 'titulo_pastoral', 'cargo_pastoral', 'is_pastor_titular'])
            ->map(fn($u) => [
                'id' => $u->id,
                'nome' => $u->name,
                'titulo_pastoral' => $u->titulo_pastoral ?: $u->name,
                'cargo_pastoral' => $u->cargo_pastoral ?: 'Pastor da Igreja',
                'is_pastor_titular' => (bool) $u->is_pastor_titular,
                'display' => ($u->titulo_pastoral ?: $u->name) . ($u->cargo_pastoral ? " ({$u->cargo_pastoral})" : ''),
            ]);
    }

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

        $pastores = $this->getPastoresAtivos();
        $pastorId = $request->query('pastor_id');
        $pastorEscolhido = null;
        if ($pastorId) {
            $pastorEscolhido = $pastores->firstWhere('id', (int) $pastorId);
        }
        if (!$pastorEscolhido) {
            $pastorEscolhido = $pastores->firstWhere('is_pastor_titular', true) ?: $pastores->first();
        }

        $nomePastor = $pastorEscolhido ? $pastorEscolhido['titulo_pastoral'] : 'Rev. Pastor Presidente';
        $cargoPastor = $pastorEscolhido ? $pastorEscolhido['cargo_pastoral'] : 'Pastor Presidente do Conselho';

        $assinaturas = [
            ['titulo' => 'Tesoureiro da Igreja', 'nome' => 'Presb. Tesoureiro Responsável'],
            ['titulo' => 'Relator da Comissão de Exame de Contas', 'nome' => 'Relator da Comissão'],
            ['titulo' => $cargoPastor, 'nome' => $nomePastor],
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
            'pastores' => $pastores,
            'pastor_responsavel' => [
                'id' => $pastorEscolhido['id'] ?? null,
                'nome' => $nomePastor,
                'cargo' => $cargoPastor,
                'is_titular' => (bool) ($pastorEscolhido['is_pastor_titular'] ?? false),
            ],
            'assinaturas' => $assinaturas,
            'data_emissao' => now()->format('d/m/Y'),
        ]);
    }

    /** Ficha Cadastral Ministerial Individual Completa */
    public function fichaMinisterial(Request $request, Person $person): JsonResponse
    {
        $person->load([
            'families',
            'enrollments.classRoom',
            'teachingClasses.classRoom',
            'sociedadeMembros.sociedade',
        ]);

        $cargosAtuais = $person->sociedadeMembros
            ->where('status', 'ativo')
            ->map(fn($sm) => [
                'sociedade' => $sm->sociedade ? ($sm->sociedade->sigla . ' - ' . $sm->sociedade->nome) : 'Sociedade',
                'sigla' => $sm->sociedade?->sigla,
                'cargo' => $sm->cargo_atual ?: ($sm->tipo_socio === 'efetivo' ? 'Sócio Efetivo' : 'Sócio Cooperador'),
                'tipo_socio' => $sm->tipo_socio,
                'data_admissao' => $sm->data_admissao?->format('d/m/Y'),
            ])->values();

        $classesAluno = $person->enrollments
            ->map(fn($e) => $e->classRoom?->name)
            ->filter()
            ->unique()
            ->values();

        $classesProfessor = $person->teachingClasses
            ->map(fn($tc) => $tc->classRoom?->name)
            ->filter()
            ->unique()
            ->values();

        $familias = $person->families->map(fn($f) => [
            'id' => $f->id,
            'name' => $f->name,
            'relationship' => $f->pivot?->relationship,
            'is_head' => (bool) ($f->pivot?->is_head ?? false),
        ])->values();

        $pastores = $this->getPastoresAtivos();
        $pastorId = $request->query('pastor_id');
        $pastorEscolhido = null;
        if ($pastorId) {
            $pastorEscolhido = $pastores->firstWhere('id', (int) $pastorId);
        }
        if (!$pastorEscolhido) {
            $pastorEscolhido = $pastores->firstWhere('is_pastor_titular', true) ?: $pastores->first();
        }

        $nomePastor = $pastorEscolhido ? $pastorEscolhido['titulo_pastoral'] : 'Rev. Pastor Presidente';
        $cargoPastor = $pastorEscolhido ? $pastorEscolhido['cargo_pastoral'] : 'Pastor Presidente do Conselho';

        return response()->json([
            'person' => $person,
            'membro' => $person, // compatibilidade
            'cargos_atuais' => $cargosAtuais,
            'classes_aluno' => $classesAluno,
            'classes_professor' => $classesProfessor,
            'familias' => $familias,
            'igreja' => 'Igreja Presbiteriana em Campo Verde',
            'presbiterio' => 'Presbitério Campo Verde (PCVD) / Sínodo Mato Grosso',
            'pastores' => $pastores,
            'pastor_responsavel' => [
                'id' => $pastorEscolhido['id'] ?? null,
                'nome' => $nomePastor,
                'cargo' => $cargoPastor,
                'is_titular' => (bool) ($pastorEscolhido['is_pastor_titular'] ?? false),
            ],
            'pastor_presidente' => $nomePastor,
            'data_emissao' => now()->format('d/m/Y'),
            'hora_emissao' => now()->format('H:i:s'),
            'codigo_autenticidade' => strtoupper(substr(md5('IPB-FICHA-' . $person->id . '-' . now()->toDateString()), 0, 12)),
        ]);
    }
}
