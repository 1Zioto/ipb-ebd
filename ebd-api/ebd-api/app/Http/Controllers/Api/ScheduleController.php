<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SuperintendentSchedule;
use App\Models\TeacherSchedule;
use App\Models\EbdEvent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    // Escala de Professores
    public function teacherSchedules(Request $request): JsonResponse
    {
        $year = (int) ($request->query('year') ?: now()->year);
        $month = (int) ($request->query('month') ?: now()->month);

        $schedules = TeacherSchedule::query()
            ->with(['event:id,event_date', 'classRoom:id,name', 'person:id,full_name'])
            ->whereHas('event', fn ($query) => $query
                ->whereYear('event_date', $year)
                ->whereMonth('event_date', $month))
            ->get()
            ->sortBy('event.event_date')
            ->values()
            ->map(fn (TeacherSchedule $schedule) => [
                'id' => $schedule->id,
                'date' => $schedule->event?->event_date?->toDateString(),
                'class_id' => $schedule->class_id,
                'class_room' => $schedule->classRoom,
                'teacher_person_id' => $schedule->scheduled_person_id,
                'teacher' => $schedule->person,
            ]);

        return response()->json($schedules);
    }

    public function setTeacherSchedule(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'class_id' => 'required|exists:classes,id',
            'teacher_person_id' => 'required|exists:people,id',
        ]);

        $event = EbdEvent::firstOrCreate(
            ['event_date' => $validated['date'], 'type' => 'regular'],
            ['status' => 'pendente', 'is_auto_generated' => false, 'created_by' => $request->user()->id],
        );

        $schedule = TeacherSchedule::updateOrCreate(
            [
                'ebd_event_id' => $event->id,
                'class_id' => $validated['class_id'],
            ],
            [
                'scheduled_person_id' => $validated['teacher_person_id'],
            ]
        );

        $schedule->load(['event:id,event_date', 'classRoom:id,name', 'person:id,full_name']);

        return response()->json([
            'id' => $schedule->id,
            'date' => $schedule->event?->event_date?->toDateString(),
            'class_id' => $schedule->class_id,
            'class_room' => $schedule->classRoom,
            'teacher_person_id' => $schedule->scheduled_person_id,
            'teacher' => $schedule->person,
        ]);
    }

    // Escala de Superintendentes
    public function superintendentSchedules(Request $request): JsonResponse
    {
        $year = (int) ($request->query('year') ?: now()->year);
        $month = (int) ($request->query('month') ?: now()->month);

        $schedules = SuperintendentSchedule::query()
            ->with(['event:id,event_date', 'person:id,full_name'])
            ->whereHas('event', fn ($query) => $query
                ->whereYear('event_date', $year)
                ->whereMonth('event_date', $month))
            ->get()
            ->sortBy('event.event_date')
            ->values()
            ->map(fn (SuperintendentSchedule $schedule) => [
                'id' => $schedule->id,
                'date' => $schedule->event?->event_date?->toDateString(),
                'superintendent_person_id' => $schedule->scheduled_person_id,
                'superintendent' => $schedule->person,
            ]);

        return response()->json($schedules);
    }

    public function setSuperintendentSchedule(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'superintendent_person_id' => 'required|exists:people,id',
        ]);

        $event = EbdEvent::firstOrCreate(
            ['event_date' => $validated['date'], 'type' => 'regular'],
            ['status' => 'pendente', 'is_auto_generated' => false, 'created_by' => $request->user()->id],
        );

        $schedule = SuperintendentSchedule::updateOrCreate(
            [
                'ebd_event_id' => $event->id,
            ],
            [
                'scheduled_person_id' => $validated['superintendent_person_id'],
            ]
        );

        $schedule->load(['event:id,event_date', 'person:id,full_name']);

        return response()->json([
            'id' => $schedule->id,
            'date' => $schedule->event?->event_date?->toDateString(),
            'superintendent_person_id' => $schedule->scheduled_person_id,
            'superintendent' => $schedule->person,
        ]);
    }
}
