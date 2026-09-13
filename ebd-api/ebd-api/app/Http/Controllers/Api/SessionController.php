<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\SessionResource;
use App\Models\AttendanceSession;
use App\Support\Audit;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SessionController extends Controller
{
    public function show(Request $request, AttendanceSession $session)
    {
        if (! $request->user()->hasPermission('call.view')) abort(403);
        return new SessionResource($session);
    }

    /**
     * RN-09: registrar que a classe não funcionou no dia (sem excluir).
     * Estados de "não funcionamento" nesta fase. A chamada em si (finalização,
     * presenças) vem na Fase 5.
     */
    public function setStatus(Request $request, AttendanceSession $session)
    {
        if (! $request->user()->hasPermission('call.edit')) abort(403);

        $data = $request->validate([
            'status' => ['required', Rule::in([
                'pendente', 'cancelada', 'classe_unificada', 'nao_realizada', 'evento_especial',
            ])],
            'status_reason' => ['nullable', 'string', 'max:255'],
            'merged_into_class_id' => ['nullable', 'integer', 'exists:classes,id'],
        ]);

        if ($session->status === 'finalizada' && ! $request->user()->hasPermission('call.reopen')) {
            return response()->json(['message' => 'Chamada finalizada. Requer permissão de reabertura.'], 403);
        }

        $old = $session->only(['status', 'status_reason', 'merged_into_class_id']);
        $session->update([
            'status' => $data['status'],
            'status_reason' => $data['status_reason'] ?? null,
            'merged_into_class_id' => $data['status'] === 'classe_unificada' ? ($data['merged_into_class_id'] ?? null) : null,
            'updated_by' => $request->user()->id,
        ]);

        Audit::log('session.status_changed', 'attendance_session', $session->id, $old, $session->only(['status', 'status_reason', 'merged_into_class_id']));
        return new SessionResource($session);
    }
}
