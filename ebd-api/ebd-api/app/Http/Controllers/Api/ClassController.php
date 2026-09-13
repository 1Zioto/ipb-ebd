<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreClassRequest;
use App\Http\Requests\UpdateClassRequest;
use App\Http\Resources\ClassResource;
use App\Models\ClassRoom;
use App\Models\AttendanceSession;
use App\Support\Audit;
use Illuminate\Http\Request;

class ClassController extends Controller
{
    public function index(Request $request)
    {
        if (! $request->user()->hasPermission('class.view')) abort(403);

        $q = ClassRoom::query()->withCount(['students' => fn ($s) => $s->where('is_active', true), 'teachers' => fn ($t) => $t->where('is_active', true)]);

        // Professor só enxerga suas classes vinculadas.
        if ($request->user()->hasRole('professor') && ! $request->user()->isProgrammer()
            && ! $request->user()->hasPermission('class.manage')) {
            $ids = $request->user()->teachingClassIds();
            $q->whereIn('id', $ids ?: [0]);
        }

        if ($request->has('is_active')) $q->where('is_active', $request->boolean('is_active'));

        $q->orderBy('display_order')->orderBy('name');

        return ClassResource::collection($q->get());
    }

    public function store(StoreClassRequest $request)
    {
        $class = ClassRoom::create($request->validated())->refresh();
        Audit::log('class.created', 'class', $class->id, null, $class->toArray());
        return (new ClassResource($class))->response()->setStatusCode(201);
    }

    public function show(Request $request, ClassRoom $class)
    {
        if (! $request->user()->hasPermission('class.view')) abort(403);
        $class->loadCount(['students' => fn ($s) => $s->where('is_active', true), 'teachers' => fn ($t) => $t->where('is_active', true)]);
        return new ClassResource($class);
    }

    /** Histórico de chamadas da classe, com acesso direto à sessão. */
    public function sessions(Request $request, ClassRoom $class)
    {
        if (! $request->user()->hasPermission('call.view')) abort(403);

        $user = $request->user();
        if ($user->hasRole('professor') && ! $user->isProgrammer()
            && ! $user->hasPermission('event.manage')
            && ! in_array($class->id, $user->teachingClassIds(), true)) {
            abort(403, 'Você não está vinculado a esta classe.');
        }

        $sessions = AttendanceSession::query()
            ->where('class_id', $class->id)
            ->with('event:id,event_date,type,status')
            ->withCount([
                'records',
                'records as present_count' => fn ($query) => $query->where('present', true),
            ])
            ->get()
            ->sortByDesc(fn ($session) => $session->event?->event_date?->format('Y-m-d'))
            ->values()
            ->map(fn ($session) => [
                'id' => $session->id,
                'event_id' => $session->ebd_event_id,
                'event_date' => $session->event?->event_date?->format('Y-m-d'),
                'event_type' => $session->event?->type,
                'status' => $session->status,
                'teacher_name' => $session->teacher_name_snapshot,
                'present' => $session->present_count,
                'absent' => max(0, $session->records_count - $session->present_count),
                'total' => $session->records_count,
                'bibles' => $session->bibles_total,
                'magazines' => $session->magazines_total,
            ]);

        return response()->json(['data' => $sessions]);
    }

    public function update(UpdateClassRequest $request, ClassRoom $class)
    {
        $old = $class->toArray();
        $class->update($request->validated());
        Audit::log('class.updated', 'class', $class->id, $old, $class->toArray());
        return new ClassResource($class);
    }

    public function destroy(Request $request, ClassRoom $class)
    {
        if (! $request->user()->hasPermission('class.manage')) abort(403);
        $class->update(['is_active' => false]);
        $class->delete(); // soft delete
        Audit::log('class.deleted', 'class', $class->id);
        return response()->json(['message' => 'Classe inativada.']);
    }
}
