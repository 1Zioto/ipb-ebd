<?php

namespace App\Http\Controllers\Api\Dizimos;

use App\Http\Controllers\Controller;
use App\Models\SolicitacaoDiaconato;
use App\Services\Dizimos\AuditoriaDizimosService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DiaconatoController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = SolicitacaoDiaconato::query()->with([
            'person:id,full_name,envelope_number,notes',
            'person.families:id,name,phone,whatsapp',
            'pastor:id,name',
            'diacono:id,name',
        ]);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        $requests = $query->orderBy('created_at', 'desc')->paginate(15);

        return response()->json($requests);
    }

    public function update(Request $request, SolicitacaoDiaconato $solicitacao): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'required|string|in:Pendente,Em atendimento,Concluído,Cancelado',
            'notes' => 'nullable|string',
        ]);

        $solicitacao->update([
            'status' => $validated['status'],
            'diacono_id' => $request->user()->id,
        ]);

        AuditoriaDizimosService::log('diaconato_solicitacao.atualizar', 'solicitacao_diaconato', $solicitacao->id, [
            'status' => $solicitacao->status,
        ], $request->user());

        return response()->json($solicitacao);
    }
}
