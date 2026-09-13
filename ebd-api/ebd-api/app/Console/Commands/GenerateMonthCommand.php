<?php

namespace App\Console\Commands;

use App\Domain\Calendar\GenerateMonthlyEventsAction;
use Carbon\Carbon;
use Illuminate\Console\Command;

class GenerateMonthCommand extends Command
{
    protected $signature = 'ebd:generate-month {year?} {month?}';
    protected $description = 'Gera (idempotente) os encontros regulares e sessões do mês';

    public function handle(GenerateMonthlyEventsAction $action): int
    {
        $now = Carbon::now(config('app.timezone'));
        $year = (int) ($this->argument('year') ?: $now->year);
        $month = (int) ($this->argument('month') ?: $now->month);

        $r = $action->execute($year, $month);
        $this->info("Mês {$month}/{$year}: +{$r['createdEvents']} encontros (".$r['existingEvents']." já existiam), +{$r['createdSessions']} sessões.");
        return self::SUCCESS;
    }
}
