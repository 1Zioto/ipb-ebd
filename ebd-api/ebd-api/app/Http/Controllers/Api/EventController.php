<?php

namespace App\Http\Controllers\Api;

use App\Domain\Calendar\GenerateMonthlyEventsAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreAdhocEventRequest;
use App\Http\Resources\EbdEventResource;
use App\Models\AttendanceSession;
use App\Models\ClassRoom;
use App\Models\EbdEvent;
use App\Models\Person;
use App\Models\Setting;
use App\Support\Audit;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class EventController extends Controller
{
    public function index(Request $request)
    {
        if (! $request->user()->hasPermission('event.view')) abort(403);

        $q = EbdEvent::query()->withCount('sessions');

        if ($request->filled('year') && $request->filled('month')) {
            $q->whereYear('event_date', $request->integer('year'))
              ->whereMonth('event_date', $request->integer('month'));
        } elseif ($request->filled('from') && $request->filled('to')) {
            $q->whereBetween('event_date', [$request->date('from'), $request->date('to')]);
        }

        $q->orderBy('event_date');
        return EbdEventResource::collection($q->get());
    }

    public function generate(Request $request, GenerateMonthlyEventsAction $action)
    {
        if (! $request->user()->hasPermission('event.generate')) abort(403);
        $data = $request->validate([
            'year' => ['required', 'integer', 'min:2020', 'max:2100'],
            'month' => ['required', 'integer', 'min:1', 'max:12'],
        ]);
        $result = $action->execute($data['year'], $data['month'], $request->user()->id);
        return response()->json($result);
    }

    public function show(Request $request, EbdEvent $event)
    {
        if (! $request->user()->hasPermission('event.view')) abort(403);
        $event->load(['sessions' => fn ($q) => $q->orderBy('class_id')]);
        return new EbdEventResource($event);
    }

    /** RN-08: chamada avulsa em qualquer data. */
    public function storeAdhoc(StoreAdhocEventRequest $request)
    {
        // Impede duplicar encontro na mesma data/tipo.
        $exists = EbdEvent::where('event_date', $request->event_date)
            ->where('type', $request->type)->exists();
        if ($exists) {
            return response()->json(['message' => 'Já existe um encontro nesta data e tipo.'], 409);
        }

        $event = EbdEvent::create([
            'event_date' => $request->event_date,
            'type' => $request->type,
            'status' => 'pendente',
            'is_auto_generated' => false,
            'notes' => $request->notes,
            'created_by' => $request->user()->id,
        ]);

        // Classes participantes: as informadas, ou todas as ativas.
        $classIds = $request->input('class_ids');
        $classes = $classIds
            ? ClassRoom::whereIn('id', $classIds)->get(['id', 'name'])
            : ClassRoom::where('is_active', true)->get(['id', 'name']);

        foreach ($classes as $class) {
            AttendanceSession::firstOrCreate(
                ['ebd_event_id' => $event->id, 'class_id' => $class->id],
                [
                    'status' => 'pendente',
                    'class_name_snapshot' => $class->name,
                    'material_mode' => Setting::get('default_material_mode', 'individual'),
                ]
            );
        }

        Audit::log('event.created_adhoc', 'ebd_event', $event->id, null, $event->toArray());
        $event->load('sessions');
        return (new EbdEventResource($event))->response()->setStatusCode(201);
    }

    public function update(Request $request, EbdEvent $event)
    {
        if (! $request->user()->hasPermission('event.manage')) abort(403);
        $data = $request->validate([
            'status' => ['sometimes', Rule::in(['pendente', 'em_andamento', 'finalizada', 'cancelada'])],
            'notes' => ['sometimes', 'nullable', 'string'],
        ]);
        $old = $event->toArray();
        $event->update($data);
        Audit::log('event.updated', 'ebd_event', $event->id, $old, $event->toArray());
        return new EbdEventResource($event);
    }

    /** Superintendente real do dia (snapshot). */
    public function setSuperintendent(Request $request, EbdEvent $event)
    {
        if (! $request->user()->hasPermission('superintendent.assign')) abort(403);
        $data = $request->validate([
            'person_id' => ['nullable', 'integer', 'exists:people,id'],
        ]);

        $person = $data['person_id'] ? Person::find($data['person_id']) : null;
        if ($person && ! $person->can_superintend) {
            return response()->json([
                'message' => 'Pessoa não habilitada como superintendente.',
                'errors' => ['person_id' => ['Pessoa não habilitada (can_superintend).']],
            ], 422);
        }

        $old = $event->only(['superintendent_person_id', 'superintendent_name_snapshot']);
        $event->update([
            'superintendent_person_id' => $person?->id,
            'superintendent_name_snapshot' => $person?->full_name,
        ]);
        Audit::log('event.superintendent_set', 'ebd_event', $event->id, $old, $event->only(['superintendent_person_id', 'superintendent_name_snapshot']));
        return new EbdEventResource($event);
    }
}
