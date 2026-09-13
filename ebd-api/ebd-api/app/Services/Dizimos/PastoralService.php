<?php

namespace App\Services\Dizimos;

use App\Models\AcompanhamentoDizimo;
use App\Models\AlertaDizimo;
use App\Models\ConsolidacaoDizimoMensal;
use App\Models\Person;
use App\Models\SolicitacaoDiaconato;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;

class PastoralService
{
    public function getDashboardStats(): array
    {
        return [
            'people_followed' => AlertaDizimo::whereIn('status', ['Em análise', 'Em acompanhamento'])->distinct('person_id')->count('person_id'),
            'active_alerts' => AlertaDizimo::whereIn('status', ['Novo', 'Em análise', 'Em acompanhamento'])->count(),
            'new_alerts' => AlertaDizimo::where('status', 'Novo')->count(),
            'in_progress_alerts' => AlertaDizimo::whereIn('status', ['Em análise', 'Em acompanhamento'])->count(),
            'resolved_alerts' => AlertaDizimo::whereIn('status', ['Resolvido', 'Descartado'])->count(),
        ];
    }

    public function getMemberFinancialHistory(Person $person, User $user): array
    {
        if (! $user->hasPermission('dizimos.historico_individual.view') && ! $user->hasRole('pastor')) {
            throw new AuthorizationException('Acesso não autorizado ao histórico financeiro individual do membro.');
        }

        AuditoriaDizimosService::log('historico_individual.visualizar', 'person', $person->id, [], $user);

        // Buscar dados consolidados dos últimos 12 meses
        $consolidated = ConsolidacaoDizimoMensal::where('person_id', $person->id)
            ->orderBy('year', 'desc')
            ->orderBy('month', 'desc')
            ->take(12)
            ->get()
            ->reverse()
            ->values();

        $monthCount = $consolidated->count();
        $historicalAvg = $monthCount > 0 ? round($consolidated->avg('total_amount'), 2) : 0.00;
        $recentMonths = $consolidated->take(-3);
        $recentAvg = $recentMonths->count() > 0 ? round($recentMonths->avg('total_amount'), 2) : 0.00;

        $variationPercentage = $historicalAvg > 0
            ? round((($recentAvg - $historicalAvg) / $historicalAvg) * 100, 2)
            : 0.00;

        // Classificação da tendência
        $trend = 'Estável';
        if ($monthCount < 3) {
            $trend = 'Histórico insuficiente';
        } elseif ($recentAvg == 0 && $historicalAvg > 0) {
            $trend = 'Sem contribuição recente';
        } elseif ($variationPercentage <= -30.0) {
            $trend = 'Queda significativa';
        } elseif ($variationPercentage < -10.0) {
            $trend = 'Pequena redução';
        } elseif ($variationPercentage >= 15.0) {
            $trend = 'Crescimento';
        }

        return [
            'person' => [
                'id' => $person->id,
                'full_name' => $person->full_name,
                'envelope_number' => $person->envelope_number,
                'is_tither' => (bool) $person->is_tither,
                'tither_since' => $person->tither_since?->toDateString(),
                'notes' => $person->notes,
            ],
            'metrics' => [
                'historical_average' => $historicalAvg,
                'recent_average' => $recentAvg,
                'variation_percentage' => $variationPercentage,
                'trend' => $trend,
                'months_recorded' => $monthCount,
                'zero_contribution_months' => $consolidated->filter(fn ($m) => $m->total_amount == 0)->count(),
            ],
            'chart_data' => $consolidated->map(fn ($c) => [
                'year' => $c->year,
                'month' => $c->month,
                'label' => sprintf('%02d/%d', $c->month, $c->year),
                'total_amount' => (float) $c->total_amount,
                'contribution_count' => $c->contribution_count,
            ]),
        ];
    }

    public function createAcompanhamento(AlertaDizimo $alerta, array $data, User $user): AcompanhamentoDizimo
    {
        $acomp = AcompanhamentoDizimo::create([
            'alerta_id' => $alerta->id,
            'person_id' => $alerta->person_id,
            'responsible_id' => $user->id,
            'date' => $data['date'] ?? now()->toDateString(),
            'type' => $data['type'] ?? 'pastoral',
            'notes' => $data['notes'] ?? null,
            'next_action' => $data['next_action'] ?? null,
            'review_date' => $data['review_date'] ?? null,
            'status' => $data['status'] ?? 'Em andamento',
            'conclusion' => $data['conclusion'] ?? null,
        ]);

        if (! empty($data['alerta_status'])) {
            $alerta->update([
                'status' => $data['alerta_status'],
                'pastor_id' => $user->id,
                'resolved_at' => in_array($data['alerta_status'], ['Resolvido', 'Descartado']) ? now() : null,
            ]);
        } else {
            $alerta->update(['status' => 'Em acompanhamento', 'pastor_id' => $user->id]);
        }

        AuditoriaDizimosService::log('alerta.acompanhar', 'alerta_dizimo', $alerta->id, [
            'alerta_status' => $alerta->status,
            'conclusion' => $acomp->conclusion,
        ], $user);

        return $acomp;
    }

    public function createDiaconatoRequest(array $data, User $user): SolicitacaoDiaconato
    {
        $solicitacao = SolicitacaoDiaconato::create([
            'person_id' => (int) $data['person_id'],
            'pastor_id' => $user->id,
            'pastor_notes' => trim($data['pastor_notes']),
            'status' => 'Pendente',
        ]);

        AuditoriaDizimosService::log('diaconato_solicitacao.criar', 'solicitacao_diaconato', $solicitacao->id, [
            'person_id' => $solicitacao->person_id,
        ], $user);

        return $solicitacao;
    }
}
