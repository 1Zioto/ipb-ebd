<?php

namespace App\Domain\Calendar;

use App\Models\AttendanceSession;
use App\Models\ClassRoom;
use App\Models\EbdEvent;
use App\Models\Setting;
use App\Support\Audit;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use Illuminate\Support\Facades\DB;

class GenerateMonthlyEventsAction
{
    /**
     * Gera (idempotente) os encontros regulares do mês e prepara as sessões
     * de chamada de cada classe ativa. Reexecutar NÃO duplica (RN-06/RN-07).
     *
     * @return array{created_events:int,existing_events:int,created_sessions:int}
     */
    public function execute(int $year, int $month, ?int $userId = null): array
    {
        $weekday = (int) (Setting::get('ebd_default_weekday', 0)); // 0 = domingo
        $tz = (string) (Setting::get('timezone', 'America/Sao_Paulo'));

        $start = Carbon::create($year, $month, 1, 0, 0, 0, $tz)->startOfMonth();
        $end = $start->copy()->endOfMonth();

        // Todas as datas do mês cujo dia da semana == weekday
        $dates = [];
        foreach (CarbonPeriod::create($start, $end) as $day) {
            if ($day->dayOfWeek === $weekday) {
                $dates[] = $day->toDateString();
            }
        }

        $activeClasses = ClassRoom::where('is_active', true)->get(['id', 'name']);

        $createdEvents = 0;
        $existingEvents = 0;
        $createdSessions = 0;

        DB::transaction(function () use ($dates, $activeClasses, $userId, &$createdEvents, &$existingEvents, &$createdSessions) {
            foreach ($dates as $date) {
                $event = EbdEvent::where('event_date', $date)->where('type', 'regular')->first();
                if (! $event) {
                    $event = EbdEvent::create([
                        'event_date' => $date,
                        'type' => 'regular',
                        'status' => 'pendente',
                        'is_auto_generated' => true,
                        'created_by' => $userId,
                    ]);
                    $createdEvents++;
                } else {
                    $existingEvents++;
                }

                foreach ($activeClasses as $class) {
                    $session = AttendanceSession::firstOrCreate(
                        ['ebd_event_id' => $event->id, 'class_id' => $class->id],
                        [
                            'status' => 'pendente',
                            'class_name_snapshot' => $class->name,
                            'material_mode' => Setting::get('default_material_mode', 'individual'),
                        ]
                    );
                    if ($session->wasRecentlyCreated) {
                        $createdSessions++;
                    }
                }
            }
        });

        Audit::log('events.generated', 'ebd_event', null, null, [
            'year' => $year, 'month' => $month,
            'created_events' => $createdEvents, 'existing_events' => $existingEvents,
            'created_sessions' => $createdSessions,
        ]);

        return compact('createdEvents', 'existingEvents', 'createdSessions');
    }
}
