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
        $sessions = AttendanceSession::whereIn('ebd_event_id', $eventIds)->with('classRoom')->get();
        $sessionIds = $sessions->pluck('id')->all();

        $records = AttendanceRecord::whereIn('attendance_session_id', $sessionIds)->get();

        $presentCount = $records->where('present', true)->count();
        $absentCount = $records->where('present', false)->count();
        $biblesCount = $records->where('brought_bible', true)->count() + $sessions->sum('bibles_total');
        $magazinesCount = $records->where('brought_magazine', true)->count() + $sessions->sum('magazines_total');

        $totalCallCount = $presentCount + $absentCount;
        $attendanceRate = $totalCallCount > 0 ? round(($presentCount / $totalCallCount) * 100, 1) : 0.0;

        // Breakdown por domingo
        $bySunday = $events->map(function ($ev) use ($sessions, $records) {
            $evSessions = $sessions->where('ebd_event_id', $ev->id);
            $evSessionIds = $evSessions->pluck('id')->all();
            $evRecords = $records->whereIn('attendance_session_id', $evSessionIds);
            $p = $evRecords->where('present', true)->count();
            $a = $evRecords->where('present', false)->count();
            return [
                'event_id' => $ev->id,
                'date' => $ev->event_date->toDateString(),
                'status' => $ev->status,
                'present' => $p,
                'absent' => $a,
                'total' => $p + $a,
                'rate' => ($p + $a > 0) ? round(($p / ($p + $a)) * 100, 1) : 0.0,
                'bibles' => $evRecords->where('brought_bible', true)->count() + $evSessions->sum('bibles_total'),
                'magazines' => $evRecords->where('brought_magazine', true)->count() + $evSessions->sum('magazines_total'),
            ];
        })->values();

        // Breakdown por classe
        $classesGrouped = $sessions->groupBy('class_id');
        $byClass = [];
        foreach ($classesGrouped as $classId => $clsSessions) {
            $clsSessionIds = $clsSessions->pluck('id')->all();
            $clsRecords = $records->whereIn('attendance_session_id', $clsSessionIds);
            $p = $clsRecords->where('present', true)->count();
            $a = $clsRecords->where('present', false)->count();
            $firstSession = $clsSessions->first();
            $className = $firstSession->classRoom?->name ?? 'Classe ' . $classId;
            $byClass[] = [
                'class_id' => (int) $classId,
                'class_name' => $className,
                'present' => $p,
                'absent' => $a,
                'total' => $p + $a,
                'rate' => ($p + $a > 0) ? round(($p / ($p + $a)) * 100, 1) : 0.0,
                'bibles' => $clsRecords->where('brought_bible', true)->count() + $clsSessions->sum('bibles_total'),
                'magazines' => $clsRecords->where('brought_magazine', true)->count() + $clsSessions->sum('magazines_total'),
            ];
        }

        return response()->json([
            'year' => $year,
            'month' => $month,
            'events_count' => $events->count(),
            'total_present' => $presentCount,
            'total_absent' => $absentCount,
            'total_bibles' => $biblesCount,
            'total_magazines' => $magazinesCount,
            'attendance_rate' => $attendanceRate,
            'by_sunday' => $bySunday,
            'by_class' => $byClass,
            'events' => $events->map(fn ($e) => [
                'id' => $e->id,
                'event_date' => $e->event_date->toDateString(),
                'type' => $e->type,
                'status' => $e->status,
            ]),
        ]);
    }

    public function byClass(Request $request, $class): JsonResponse
    {
        $classModel = $class instanceof ClassRoom ? $class : ClassRoom::findOrFail((int) $class);
        $startDate = $request->query('date_from', now()->subMonths(3)->toDateString());
        $endDate = $request->query('date_to', now()->toDateString());

        $sessions = AttendanceSession::where('class_id', $classModel->id)
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
                'rate' => ($p + $a > 0) ? round(($p / ($p + $a)) * 100, 1) : 0.0,
                'bibles' => $records->where('brought_bible', true)->count() + ($s->bibles_total ?? 0),
                'magazines' => $records->where('brought_magazine', true)->count() + ($s->magazines_total ?? 0),
            ];
        });

        return response()->json([
            'class' => [
                'id' => $classModel->id,
                'name' => $classModel->name,
            ],
            'period' => ['from' => $startDate, 'to' => $endDate],
            'sessions' => $summary,
        ]);
    }

    public function byStudent(Request $request, $person): JsonResponse
    {
        $personModel = $person instanceof Person ? $person : Person::findOrFail((int) $person);
        $startDate = $request->query('date_from', now()->subMonths(6)->toDateString());
        $endDate = $request->query('date_to', now()->toDateString());

        $records = AttendanceRecord::where('person_id', $personModel->id)
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
                'id' => $personModel->id,
                'full_name' => $personModel->full_name,
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
