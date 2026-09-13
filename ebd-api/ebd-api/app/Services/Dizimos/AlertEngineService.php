<?php

namespace App\Services\Dizimos;

use App\Models\AlertaDizimo;
use App\Models\ConsolidacaoDizimoMensal;
use App\Models\ColetaDizimo;
use App\Models\LancamentoDizimo;
use App\Models\Person;
use App\Models\Setting;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class AlertEngineService
{
    public function consolidateMonth(int $year, int $month): void
    {
        $startDate = Carbon::createFromDate($year, $month, 1)->startOfMonth()->toDateString();
        $endDate = Carbon::createFromDate($year, $month, 1)->endOfMonth()->toDateString();

        $consolidations = DB::table('lancamentos_dizimos as l')
            ->join('coletas_dizimos as c', 'c.id', '=', 'l.coleta_id')
            ->whereNull('c.deleted_at')
            ->whereIn('c.status', ['Aberta', 'Fechada', 'Reaberta para correção'])
            ->whereNotNull('l.person_id')
            ->where('l.is_unidentified', false)
            ->whereBetween('c.date', [$startDate, $endDate])
            ->select('l.person_id', DB::raw('SUM(l.amount) as total_amount'), DB::raw('COUNT(l.id) as contribution_count'))
            ->groupBy('l.person_id')
            ->get();

        foreach ($consolidations as $row) {
            ConsolidacaoDizimoMensal::updateOrCreate(
                [
                    'person_id' => $row->person_id,
                    'year' => $year,
                    'month' => $month,
                ],
                [
                    'total_amount' => (float) $row->total_amount,
                    'contribution_count' => (int) $row->contribution_count,
                ]
            );
        }
    }

    public function runAlertEngine(?int $targetYear = null, ?int $targetMonth = null): array
    {
        $enabled = Setting::where('key', 'tithes_alerts_enabled')->value('value');
        if ($enabled === 'false' || $enabled === '0') {
            return ['processed' => 0, 'alerts_created' => 0, 'status' => 'disabled'];
        }

        $minHistoryMonths = (int) (Setting::where('key', 'tithes_min_history_months')->value('value') ?: 3);
        $consecutiveMonths = (int) (Setting::where('key', 'tithes_consecutive_months')->value('value') ?: 2);
        $dropPercentageThreshold = (float) (Setting::where('key', 'tithes_drop_percentage')->value('value') ?: 30.0);
        $noContributionMonths = (int) (Setting::where('key', 'tithes_no_contribution_months')->value('value') ?: 2);

        $now = now();
        $targetYear = $targetYear ?? $now->year;
        $targetMonth = $targetMonth ?? $now->month;

        $tithers = Person::tithers()->get();
        $createdCount = 0;
        $updatedCount = 0;

        foreach ($tithers as $tither) {
            // Obter consolidados ordenados por ano/mês
            $history = ConsolidacaoDizimoMensal::where('person_id', $tither->id)
                ->where(function ($q) use ($targetYear, $targetMonth) {
                    $q->where('year', '<', $targetYear)
                        ->orWhere(function ($sub) use ($targetYear, $targetMonth) {
                            $sub->where('year', $targetYear)->where('month', '<=', $targetMonth);
                        });
                })
                ->orderBy('year', 'desc')
                ->orderBy('month', 'desc')
                ->take(12)
                ->get();

            if ($history->count() < $minHistoryMonths) {
                continue; // Histórico insuficiente para análises automáticas
            }

            // Separar os últimos $consecutiveMonths para avaliação e os 3 anteriores para média de referência
            $recentMonths = $history->take($consecutiveMonths);

            if ($recentMonths->count() < $consecutiveMonths) {
                continue;
            }

            $referenceMonths = $history->slice($consecutiveMonths, 3);
            if ($referenceMonths->isEmpty()) {
                continue;
            }

            $referenceAverage = $referenceMonths->avg('total_amount');
            if ($referenceAverage <= 0) {
                continue;
            }

            // Checagem 1: Ausência de contribuição
            $zeroCount = $recentMonths->filter(fn ($m) => (float) $m->total_amount == 0)->count();
            if ($zeroCount >= $noContributionMonths) {
                $this->triggerOrUpdateAlert(
                    $tither->id,
                    'interrupcao_contribuicao',
                    -100.0,
                    [
                        'reference_average' => round($referenceAverage, 2),
                        'months_evaluated' => $recentMonths->pluck('month')->all(),
                        'message' => 'Foi identificada uma possível interrupção nas contribuições durante dois meses consecutivos.',
                    ],
                    $createdCount,
                    $updatedCount
                );
                continue;
            }

            // Checagem 2: Queda expressiva (ambos os meses com valor <= (1 - threshold)% da média de referência)
            $thresholdAmount = $referenceAverage * (1 - ($dropPercentageThreshold / 100));
            $consecutiveDrop = true;

            foreach ($recentMonths as $m) {
                if ((float) $m->total_amount > $thresholdAmount) {
                    $consecutiveDrop = false;
                    break;
                }
            }

            if ($consecutiveDrop) {
                $recentAverage = $recentMonths->avg('total_amount');
                $variation = round((($recentAverage - $referenceAverage) / $referenceAverage) * 100, 2);

                $this->triggerOrUpdateAlert(
                    $tither->id,
                    'queda_relevante',
                    $variation,
                    [
                        'reference_average' => round($referenceAverage, 2),
                        'recent_average' => round($recentAverage, 2),
                        'threshold_percentage' => $dropPercentageThreshold,
                        'months_evaluated' => $recentMonths->map(fn ($r) => "{$r->month}/{$r->year}")->all(),
                        'message' => 'Foi identificada uma alteração significativa no histórico de contribuições deste membro.',
                    ],
                    $createdCount,
                    $updatedCount
                );
            }
        }

        return [
            'processed' => $tithers->count(),
            'alerts_created' => $createdCount,
            'alerts_updated' => $updatedCount,
        ];
    }

    private function triggerOrUpdateAlert(
        int $personId,
        string $alertType,
        float $variationPercentage,
        array $referenceCalc,
        int &$createdCount,
        int &$updatedCount
    ): void {
        $activeAlert = AlertaDizimo::where('person_id', $personId)
            ->whereIn('status', ['Novo', 'Em análise', 'Em acompanhamento'])
            ->first();

        if ($activeAlert) {
            $activeAlert->update([
                'alert_type' => $alertType,
                'variation_percentage' => $variationPercentage,
                'reference_calculation' => $referenceCalc,
                'detection_date' => now()->toDateString(),
            ]);
            $updatedCount++;
        } else {
            AlertaDizimo::create([
                'person_id' => $personId,
                'alert_type' => $alertType,
                'start_date' => now()->toDateString(),
                'detection_date' => now()->toDateString(),
                'variation_percentage' => $variationPercentage,
                'reference_calculation' => $referenceCalc,
                'status' => 'Novo',
            ]);
            $createdCount++;
        }
    }
}
