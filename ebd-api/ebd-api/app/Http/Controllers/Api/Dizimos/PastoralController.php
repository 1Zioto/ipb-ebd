<?php

namespace App\Http\Controllers\Api\Dizimos;

use App\Http\Controllers\Controller;
use App\Models\AlertaDizimo;
use App\Models\Person;
use App\Services\Dizimos\AlertEngineService;
use App\Services\Dizimos\PastoralService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PastoralController extends Controller
{
    public function __construct(
        protected PastoralService $pastoralService,
        protected AlertEngineService $alertEngine
    ) {}

    public function dashboard(): JsonResponse
    {
        $stats = $this->pastoralService->getDashboardStats();
        return response()->json($stats);
    }

    public function alerts(Request $request): JsonResponse
    {
        $query = AlertaDizimo::query()->with([
            'person:id,full_name,envelope_number,is_tither',
            'pastor:id,name',
            'acompanhamentos' => fn ($q) => $q->latest()->take(3),
        ]);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('type')) {
            $query->where('alert_type', $request->query('type'));
        }

        $alerts = $query->orderBy('detection_date', 'desc')->paginate(15);

        return response()->json($alerts);
    }

    public function alertShow(AlertaDizimo $alerta): JsonResponse
    {
        $alerta->load([
            'person:id,full_name,envelope_number,is_tither,tither_since,notes',
            'pastor:id,name',
            'acompanhamentos.responsible:id,name',
        ]);

        return response()->json($alerta);
    }

    public function storeAcompanhamento(Request $request, AlertaDizimo $alerta): JsonResponse
    {
        $validated = $request->validate([
            'date' => 'nullable|date',
            'type' => 'nullable|string|max:50',
            'notes' => 'required|string|min:3',
            'next_action' => 'nullable|string',
            'review_date' => 'nullable|date',
            'status' => 'nullable|string|max:40',
            'conclusion' => 'nullable|string|max:100',
            'alerta_status' => 'nullable|string|max:40',
        ]);

        $acomp = $this->pastoralService->createAcompanhamento($alerta, $validated, $request->user());

        return response()->json($acomp, 201);
    }

    public function memberHistory(Request $request, Person $person): JsonResponse
    {
        try {
            $history = $this->pastoralService->getMemberFinancialHistory($person, $request->user());
            return response()->json($history);
        } catch (AuthorizationException $e) {
            return response()->json(['message' => $e->getMessage()], 403);
        }
    }

    public function createDiaconatoRequest(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'person_id' => 'required|exists:people,id',
            'pastor_notes' => 'required|string|min:5',
        ]);

        $solicitacao = $this->pastoralService->createDiaconatoRequest($validated, $request->user());

        return response()->json($solicitacao, 201);
    }

    public function triggerAlertEngine(Request $request): JsonResponse
    {
        $result = $this->alertEngine->runAlertEngine(
            $request->query('year') ? (int) $request->query('year') : null,
            $request->query('month') ? (int) $request->query('month') : null
        );

        return response()->json($result);
    }
}
