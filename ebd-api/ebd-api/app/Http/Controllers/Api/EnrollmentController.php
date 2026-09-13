<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\EnrollStudentRequest;
use App\Http\Resources\EnrollmentResource;
use App\Models\ClassRoom;
use App\Models\ClassStudent;
use App\Support\Audit;
use Illuminate\Http\Request;

class EnrollmentController extends Controller
{
    /** Lista alunos (matrículas). Por padrão só as ativas; ?all=1 traz histórico. */
    public function index(Request $request, ClassRoom $class)
    {
        if (! $request->user()->hasPermission('class.view')) abort(403);

        $q = ClassStudent::with('person')->where('class_students.class_id', $class->id);
        if (! $request->boolean('all')) $q->where('class_students.is_active', true);
        $q->join('people', 'people.id', '=', 'class_students.person_id')
          ->orderBy('people.full_name')
          ->select('class_students.*');

        return EnrollmentResource::collection($q->get());
    }

    /** RN-05: matrícula com vigência. Impede duplicar matrícula ativa. */
    public function store(EnrollStudentRequest $request, ClassRoom $class)
    {
        $exists = ClassStudent::where('class_id', $class->id)
            ->where('person_id', $request->person_id)
            ->where('is_active', true)
            ->exists();

        if ($exists) {
            return response()->json(['message' => 'Pessoa já matriculada e ativa nesta classe.'], 409);
        }

        $enrollment = ClassStudent::create([
            'class_id' => $class->id,
            'person_id' => $request->person_id,
            'enrolled_at' => $request->enrolled_at ?? now()->toDateString(),
            'is_active' => true,
        ])->load('person');

        Audit::log('enrollment.created', 'class_student', $enrollment->id, null, $enrollment->toArray());
        return (new EnrollmentResource($enrollment))->response()->setStatusCode(201);
    }

    /** Encerra a matrícula (não apaga — preserva histórico). */
    public function destroy(Request $request, ClassRoom $class, int $personId)
    {
        if (! $request->user()->hasPermission('enrollment.manage')) abort(403);

        $enrollment = ClassStudent::where('class_id', $class->id)
            ->where('person_id', $personId)
            ->where('is_active', true)
            ->first();

        if (! $enrollment) {
            return response()->json(['message' => 'Matrícula ativa não encontrada.'], 404);
        }

        $old = $enrollment->toArray();
        $enrollment->update([
            'is_active' => false,
            'unenrolled_at' => now()->toDateString(),
        ]);
        Audit::log('enrollment.ended', 'class_student', $enrollment->id, $old, $enrollment->toArray());

        return response()->json(['message' => 'Matrícula encerrada.']);
    }

    /** Transferência: encerra a atual e cria nova na classe destino. */
    public function transfer(Request $request, ClassRoom $class, int $personId)
    {
        if (! $request->user()->hasPermission('enrollment.manage')) abort(403);
        $data = $request->validate(['to_class_id' => ['required', 'integer', 'exists:classes,id']]);

        $current = ClassStudent::where('class_id', $class->id)
            ->where('person_id', $personId)->where('is_active', true)->first();
        if (! $current) return response()->json(['message' => 'Matrícula ativa não encontrada.'], 404);

        $current->update(['is_active' => false, 'unenrolled_at' => now()->toDateString()]);
        $new = ClassStudent::create([
            'class_id' => $data['to_class_id'],
            'person_id' => $personId,
            'enrolled_at' => now()->toDateString(),
            'is_active' => true,
        ])->load('person');

        Audit::log('enrollment.transferred', 'class_student', $new->id, ['from_class' => $class->id], ['to_class' => $data['to_class_id']]);
        return new EnrollmentResource($new);
    }
}
