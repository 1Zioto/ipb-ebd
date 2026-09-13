<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AttendanceRecord;
use App\Models\AttendanceSession;
use App\Models\ClassRoom;
use App\Models\EbdEvent;
use App\Models\Person;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EbdReportController extends Controller
{
    public function monthly(Request $request): JsonResponse
    {
        $year = (int) ($request->query('year') ?: now()->year);
        $month = (int) ($request->query('month') ?: now()->month);

        $events = EbdEvent::whereYear('event_date', $year)
            ->whereMonth('event_date', $month)
            ->orderBy('event_date')
            ->get();

        $eventIds = $events->pluck('id')->all();
        $sessions = AttendanceSession::whereIn('ebd_event_id', $eventIds)->get();
        $sessionIds = $sessions->pluck('id')->all();

        $records = AttendanceRecord::whereIn('attendance_session_id', $sessionIds)->get();

        $presentCount = $records->where('present', true)->count();
        $absentCount = $records->where('present', false)->count();
        $biblesCount = $records->where('brought_bible', true)->count() + $sessions->sum('bibles_total');
        $magazinesCount = $records->where('brought_magazine', true)->count() + $sessions->sum('magazines_total');

        return response()->json([
            'year' => $year,
            'month' => $month,
            'events_count' => $events->count(),
            'total_present' => $presentCount,
            'total_absent' => $absentCount,
            'total_bibles' => $biblesCount,
            'total_magazines' => $magazinesCount,
            'events' => $events->map(fn ($e) => [
                'id' => $e->id,
                'event_date' => $e->event_date->toDateString(),
                'type' => $e->type,
                'status' => $e->status,
            ]),
        ]);
    }

    public function byClass(Request $request, ClassRoom $class): JsonResponse
    {
        $startDate = $request->query('date_from', now()->subMonths(3)->toDateString());
        $endDate = $request->query('date_to', now()->toDateString());

        $sessions = AttendanceSession::where('class_id', $class->id)
            ->whereHas('event', function ($q) use ($startDate, $endDate) {
                $q->whereBetween('event_date', [$startDate, $endDate]);
            })
            ->with(['event:id,event_date,type', 'teacher:id,full_name'])
            ->get();

        $summary = $sessions->map(function ($s) {
            $records = AttendanceRecord::where('attendance_session_id', $s->id)->get();
            $p = $records->where('present', true)->count();
            $a = $records->where('present', false)->count();
            return [
                'session_id' => $s->id,
                'date' => $s->event?->event_date?->toDateString(),
                'teacher' => $s->teacher?->full_name ?? $s->teacher_name,
                'status' => $s->status,
                'present' => $p,
                'absent' => $a,
                'bibles' => $records->where('brought_bible', true)->count() + ($s->bibles_total ?? 0),
                'magazines' => $records->where('brought_magazine', true)->count() + ($s->magazines_total ?? 0),
            ];
        });

        return response()->json([
            'class' => [
                'id' => $class->id,
                'name' => $class->name,
            ],
            'period' => ['from' => $startDate, 'to' => $endDate],
            'sessions' => $summary,
        ]);
    }

    public function byStudent(Request $request, Person $person): JsonResponse
    {
        $startDate = $request->query('date_from', now()->subMonths(6)->toDateString());
        $endDate = $request->query('date_to', now()->toDateString());

        $records = AttendanceRecord::where('person_id', $person->id)
            ->whereHas('session.event', function ($q) use ($startDate, $endDate) {
                $q->whereBetween('event_date', [$startDate, $endDate]);
            })
            ->with(['session.classRoom:id,name', 'session.event:id,event_date'])
            ->get();

        $totalPresent = $records->where('present', true)->count();
        $totalAbsent = $records->where('present', false)->count();
        $totalEvents = $records->count();

        $percentage = $totalEvents > 0 ? round(($totalPresent / $totalEvents) * 100, 1) : 0.0;

        return response()->json([
            'person' => [
                'id' => $person->id,
                'full_name' => $person->full_name,
            ],
            'summary' => [
                'total_events' => $totalEvents,
                'present' => $totalPresent,
                'absent' => $totalAbsent,
                'attendance_percentage' => $percentage,
            ],
            'history' => $records->map(fn ($r) => [
                'date' => $r->session?->event?->event_date?->toDateString(),
                'class_name' => $r->session?->classRoom?->name,
                'present' => (bool) $r->present,
                'brought_bible' => $r->brought_bible,
                'brought_magazine' => $r->brought_magazine,
            ]),
        ]);
    }
}
