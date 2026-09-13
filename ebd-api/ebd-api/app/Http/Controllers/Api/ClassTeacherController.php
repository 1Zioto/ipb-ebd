<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AddTeacherRequest;
use App\Http\Resources\ClassTeacherResource;
use App\Models\ClassRoom;
use App\Models\ClassTeacher;
use App\Support\Audit;
use Illuminate\Http\Request;

class ClassTeacherController extends Controller
{
    public function index(Request $request, ClassRoom $class)
    {
        if (! $request->user()->hasPermission('class.view')) abort(403);
        $teachers = ClassTeacher::with('person')->where('class_id', $class->id)
            ->where('is_active', true)->get();
        return ClassTeacherResource::collection($teachers);
    }

    public function store(AddTeacherRequest $request, ClassRoom $class)
    {
        // Reativa se já existir vínculo inativo; senão cria.
        $teacher = ClassTeacher::firstOrNew([
            'class_id' => $class->id,
            'person_id' => $request->person_id,
        ]);
        if ($teacher->exists && $teacher->is_active) {
            return response()->json(['message' => 'Professor já vinculado a esta classe.'], 409);
        }
        $teacher->is_active = true;
        $teacher->save();
        $teacher->load('person');

        Audit::log('class_teacher.added', 'class_teacher', $teacher->id, null, $teacher->toArray());
        return (new ClassTeacherResource($teacher))->response()->setStatusCode(201);
    }

    public function destroy(Request $request, ClassRoom $class, int $personId)
    {
        if (! $request->user()->hasPermission('class.manage')) abort(403);
        $teacher = ClassTeacher::where('class_id', $class->id)
            ->where('person_id', $personId)->where('is_active', true)->first();
        if (! $teacher) return response()->json(['message' => 'Vínculo não encontrado.'], 404);

        $teacher->update(['is_active' => false]);
        Audit::log('class_teacher.removed', 'class_teacher', $teacher->id);
        return response()->json(['message' => 'Professor desvinculado.']);
    }
}
