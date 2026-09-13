<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

use Illuminate\Support\Facades\Schedule;

// Gera o mês atual todo dia 1 às 00:05 (idempotente).
Schedule::command('ebd:generate-month')->monthlyOn(1, '00:05');
