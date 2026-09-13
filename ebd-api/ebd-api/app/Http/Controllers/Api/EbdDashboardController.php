<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\AttendanceRecord;
use App\Models\AttendanceSession;
use App\Models\ClassRoom;
use App\Models\ClassStudent;
use App\Models\EbdEvent;
use App\Models\Person;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EbdDashboardController extends Controller
{
    public function summary(): JsonResponse
    {
        $totalStudents = ClassStudent::where('is_active', true)->distinct('person_id')->count('person_id');
        $totalTeachers = Person::active()->teachers()->count();
        $totalClasses = ClassRoom::where('is_active', true)->count();

        // Próxima EBD
        $nextEvent = EbdEvent::where('event_date', '>=', now()->toDateString())
            ->where('status', '!=', 'Cancelado')
            ->orderBy('event_date')
            ->first();

        $pendingCalls = $nextEvent
            ? AttendanceSession::where('ebd_event_id', $nextEvent->id)->where('status', 'Pendente')->count()
            : 0;

        // Aniversariantes de hoje
        $birthdaysToday = Person::active()->birthdayToday()->get(['id', 'full_name', 'birth_date']);

        // Aniversariantes da semana
        $startOfWeek = now()->startOfWeek();
        $endOfWeek = now()->endOfWeek();
        $birthdaysWeek = Person::active()
            ->whereNotNull('birth_date')
            ->get()
            ->filter(function ($p) use ($startOfWeek, $endOfWeek) {
                $bday = $p->birth_date->copy()->year(now()->year);
                return $bday->between($startOfWeek, $endOfWeek);
            })
            ->values();

        // Avisos ativos
        $announcements = Announcement::where('is_active', true)->orderBy('created_at', 'desc')->take(5)->get();

        return response()->json([
            'metrics' => [
                'total_students' => $totalStudents,
                'total_teachers' => $totalTeachers,
                'total_classes' => $totalClasses,
                'pending_calls' => $pendingCalls,
            ],
            'next_event' => $nextEvent ? [
                'id' => $nextEvent->id,
                'event_date' => $nextEvent->event_date->toDateString(),
                'type' => $nextEvent->type,
                'status' => $nextEvent->status,
                'superintendent_name' => $nextEvent->superintendent_person_id ? Person::find($nextEvent->superintendent_person_id)?->full_name : null,
            ] : null,
            'birthdays_today' => $birthdaysToday,
            'birthdays_week' => $birthdaysWeek,
            'announcements' => $announcements,
        ]);
    }

    public function superintendentLive(?int $eventId = null): JsonResponse
    {
        $event = $eventId
            ? EbdEvent::find($eventId)
            : EbdEvent::where('event_date', '>=', now()->subDays(2)->toDateString())
                ->orderBy('event_date')
                ->first();

        if (! $event) {
            return response()->json(['message' => 'Nenhum encontro de EBD encontrado para o período.'], 404);
        }

        $sessions = AttendanceSession::where('ebd_event_id', $event->id)
            ->with(['classRoom:id,name,display_order', 'teacher:id,full_name'])
            ->get();

        $sessionIds = $sessions->pluck('id')->all();

        // Totais gerais acumulados
        $attendanceStats = AttendanceRecord::whereIn('attendance_session_id', $sessionIds)
            ->selectRaw('SUM(CASE WHEN present = true THEN 1 ELSE 0 END) as total_present, SUM(CASE WHEN present = false THEN 1 ELSE 0 END) as total_absent, SUM(CASE WHEN brought_bible = true THEN 1 ELSE 0 END) as total_bibles, SUM(CASE WHEN brought_magazine = true THEN 1 ELSE 0 END) as total_magazines')
            ->first();

        // Totais agregados diretos de sessões
        $aggregatedBibles = $sessions->sum('bibles_total');
        $aggregatedMagazines = $sessions->sum('magazines_total');

        $totalPresent = (int) ($attendanceStats->total_present ?? 0);
        $totalAbsent = (int) ($attendanceStats->total_absent ?? 0);
        $totalBibles = max((int) ($attendanceStats->total_bibles ?? 0), (int) $aggregatedBibles);
        $totalMagazines = max((int) ($attendanceStats->total_magazines ?? 0), (int) $aggregatedMagazines);

        return response()->json([
            'event' => [
                'id' => $event->id,
                'event_date' => $event->event_date->toDateString(),
                'type' => $event->type,
                'status' => $event->status,
                'superintendent' => $event->superintendent_person_id ? Person::find($event->superintendent_person_id)?->full_name : null,
            ],
            'live_summary' => [
                'present' => $totalPresent,
                'absent' => $totalAbsent,
                'total_enrolled' => $totalPresent + $totalAbsent,
                'bibles' => $totalBibles,
                'magazines' => $totalMagazines,
            ],
            'sessions' => $sessions->map(fn ($s) => [
                'id' => $s->id,
                'class_name' => $s->classRoom?->name,
                'teacher_name' => $s->teacher?->full_name ?? $s->teacher_name,
                'status' => $s->status,
                'material_mode' => $s->material_mode,
                'bibles_total' => $s->bibles_total,
                'magazines_total' => $s->magazines_total,
                'finalized_at' => $s->finalized_at?->toDateTimeString(),
            ]),
        ]);
    }
}
