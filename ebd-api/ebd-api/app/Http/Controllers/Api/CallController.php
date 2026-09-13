<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AttendanceRecordResource;
use App\Http\Resources\SessionResource;
use App\Models\AttendanceRecord;
use App\Models\AttendanceSession;
use App\Models\ClassStudent;
use App\Models\Person;
use App\Support\Audit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class CallController extends Controller
{
    /** Professor só acessa chamadas de classes às quais está vinculado. */
    private function authorizeClass(Request $request, AttendanceSession $session, string $perm): void
    {
        if (! $request->user()->hasPermission($perm)) abort(403);

        $u = $request->user();
        if ($u->isProgrammer() || $u->hasPermission('call.edit') && $u->hasRole('superintendencia')) {
            return;
        }
        if ($u->hasRole('professor') && ! $u->hasPermission('event.manage')) {
            $ids = $u->teachingClassIds();
            if (! in_array($session->class_id, $ids, true)) {
                abort(403, 'Você não está vinculado a esta classe.');
            }
        }
    }

    /** Sessão + registros de presença (alunos). */
    public function records(Request $request, AttendanceSession $session)
    {
        $this->authorizeClass($request, $session, 'call.view');
        $records = AttendanceRecord::where('attendance_session_id', $session->id)
            ->orderBy('person_name_snapshot')->get();

        return response()->json([
            'session' => new SessionResource($session),
            'records' => AttendanceRecordResource::collection($records),
            'summary' => $this->summary($session),
        ]);
    }

    /** Abre a chamada: cria os records dos alunos matriculados ativos (present=false). Idempotente. */
    public function open(Request $request, AttendanceSession $session)
    {
        $this->authorizeClass($request, $session, 'call.perform');

        if ($session->status === 'finalizada') {
            return response()->json(['message' => 'Chamada já finalizada.'], 409);
        }

        DB::transaction(function () use ($session, $request) {
            $enrollments = ClassStudent::with('person')
                ->where('class_id', $session->class_id)
                ->where('is_active', true)->get();

            foreach ($enrollments as $en) {
                AttendanceRecord::firstOrCreate(
                    ['attendance_session_id' => $session->id, 'person_id' => $en->person_id],
                    ['person_name_snapshot' => $en->person->full_name, 'present' => false]
                );
            }

            if ($session->status === 'pendente') {
                $session->update(['status' => 'em_andamento', 'created_by' => $session->created_by ?? $request->user()->id]);
            }
        });

        Audit::log('call.opened', 'attendance_session', $session->id);
        $session->refresh();
        return $this->records($request, $session);
    }

    /** Marca presenças em lote (rápido). [{person_id, present, brought_bible?, brought_magazine?}] */
    public function attendance(Request $request, AttendanceSession $session)
    {
        $this->authorizeClass($request, $session, 'call.perform');

        if ($session->status === 'finalizada' && ! $request->user()->hasPermission('call.reopen')) {
            return response()->json(['message' => 'Chamada finalizada. Requer reabertura.'], 403);
        }

        $data = $request->validate([
            'records' => ['required', 'array'],
            'records.*.person_id' => ['required', 'integer'],
            'records.*.present' => ['required', 'boolean'],
            'records.*.brought_bible' => ['nullable', 'boolean'],
            'records.*.brought_magazine' => ['nullable', 'boolean'],
        ]);

        DB::transaction(function () use ($data, $session) {
            foreach ($data['records'] as $r) {
                AttendanceRecord::where('attendance_session_id', $session->id)
                    ->where('person_id', $r['person_id'])
                    ->update([
                        'present' => $r['present'],
                        'brought_bible' => $r['brought_bible'] ?? null,
                        'brought_magazine' => $r['brought_magazine'] ?? null,
                    ]);
            }
            $session->update(['updated_by' => request()->user()->id]);
        });

        Audit::log('call.attendance_saved', 'attendance_session', $session->id, null, ['count' => count($data['records'])]);
        return $this->records($request, $session);
    }

    /** Professor do dia (RN-04/RN-14). Valida can_teach. */
    public function setTeacher(Request $request, AttendanceSession $session)
    {
        $this->authorizeClass($request, $session, 'call.edit');
        $data = $request->validate(['person_id' => ['nullable', 'integer', 'exists:people,id']]);

        $person = $data['person_id'] ? Person::find($data['person_id']) : null;
        if ($person && ! $person->can_teach) {
            return response()->json([
                'message' => 'Pessoa não habilitada como professora.',
                'errors' => ['person_id' => ['Pessoa não habilitada (can_teach).']],
            ], 422);
        }

        $old = $session->only(['teacher_person_id', 'teacher_name_snapshot']);
        $session->update([
            'teacher_person_id' => $person?->id,
            'teacher_name_snapshot' => $person?->full_name,
            'updated_by' => $request->user()->id,
        ]);
        Audit::log('call.teacher_set', 'attendance_session', $session->id, $old, $session->only(['teacher_person_id', 'teacher_name_snapshot']));
        return new SessionResource($session);
    }

    /** Materiais: modo individual (calculado) ou agregado (digitado) — RN-11. */
    public function materials(Request $request, AttendanceSession $session)
    {
        $this->authorizeClass($request, $session, 'call.edit');
        $data = $request->validate([
            'material_mode' => ['required', Rule::in(['individual', 'agregado'])],
            'bibles_total' => ['nullable', 'integer', 'min:0'],
            'magazines_total' => ['nullable', 'integer', 'min:0'],
        ]);

        $update = ['material_mode' => $data['material_mode'], 'updated_by' => $request->user()->id];
        if ($data['material_mode'] === 'agregado') {
            $update['bibles_total'] = $data['bibles_total'] ?? 0;
            $update['magazines_total'] = $data['magazines_total'] ?? 0;
        } else {
            // No individual, os totais são derivados na finalização; limpa digitação manual.
            $update['bibles_total'] = null;
            $update['magazines_total'] = null;
        }
        $session->update($update);
        Audit::log('call.materials_set', 'attendance_session', $session->id, null, $update);
        return new SessionResource($session);
    }

    /** Finaliza a chamada. Calcula totais no modo individual. */
    public function finalize(Request $request, AttendanceSession $session)
    {
        $this->authorizeClass($request, $session, 'call.finalize');

        if ($session->status === 'finalizada') {
            return response()->json(['message' => 'Chamada já finalizada.'], 409);
        }
        if (! in_array($session->status, ['pendente', 'em_andamento'], true)) {
            return response()->json(['message' => 'Estado inválido para finalizar.'], 422);
        }

        if ($session->material_mode === 'individual') {
            $bibles = AttendanceRecord::where('attendance_session_id', $session->id)->where('brought_bible', true)->count();
            $mags = AttendanceRecord::where('attendance_session_id', $session->id)->where('brought_magazine', true)->count();
            $session->bibles_total = $bibles;
            $session->magazines_total = $mags;
        }

        $session->status = 'finalizada';
        $session->finalized_by = $request->user()->id;
        $session->finalized_at = now();
        $session->save();

        Audit::log('call.finalized', 'attendance_session', $session->id, null, $this->summary($session));
        return response()->json([
            'session' => new SessionResource($session),
            'summary' => $this->summary($session),
        ]);
    }

    /** Reabre chamada finalizada (RN-15) — exige call.reopen. */
    public function reopen(Request $request, AttendanceSession $session)
    {
        if (! $request->user()->hasPermission('call.reopen')) abort(403);
        if ($session->status !== 'finalizada') {
            return response()->json(['message' => 'A chamada não está finalizada.'], 422);
        }
        $session->update(['status' => 'em_andamento', 'updated_by' => $request->user()->id]);
        Audit::log('call.reopened', 'attendance_session', $session->id);
        return new SessionResource($session);
    }

    private function summary(AttendanceSession $session): array
    {
        $present = AttendanceRecord::where('attendance_session_id', $session->id)->where('present', true)->count();
        $total = AttendanceRecord::where('attendance_session_id', $session->id)->count();
        return [
            'present' => $present,
            'absent' => $total - $present,
            'total' => $total,
            'bibles' => $session->material_mode === 'individual'
                ? AttendanceRecord::where('attendance_session_id', $session->id)->where('brought_bible', true)->count()
                : $session->bibles_total,
            'magazines' => $session->material_mode === 'individual'
                ? AttendanceRecord::where('attendance_session_id', $session->id)->where('brought_magazine', true)->count()
                : $session->magazines_total,
        ];
    }
}
