<?php

namespace App\Http\Controllers\Api\Dizimos;

use App\Http\Controllers\Controller;
use App\Models\ColetaDizimo;
use App\Models\LancamentoDizimo;
use App\Models\User;
use App\Services\Dizimos\ColetaService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use InvalidArgumentException;

class ColetaController extends Controller
{
    public function __construct(
        protected ColetaService $coletaService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = ColetaDizimo::query()->with(['creator:id,name', 'closer:id,name']);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('date_from')) {
            $query->where('date', '>=', $request->query('date_from'));
        }
        if ($request->filled('date_to')) {
            $query->where('date', '<=', $request->query('date_to'));
        }

        $coletas = $query->orderBy('date', 'desc')->paginate(20);

        return response()->json($coletas);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'service_meeting' => 'nullable|string|max:100',
            'description' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
        ]);

        $coleta = $this->coletaService->openColeta($validated, $request->user());

        return response()->json($coleta, 201);
    }

    public function show(Request $request, ColetaDizimo $coleta): JsonResponse
    {
        $coleta->load(['creator:id,name', 'closer:id,name', 'verifier:id,name']);
        $user = $request->user();

        // Se a coleta estiver FECHADA e o usuário NÃO puder ver dados sensíveis ou não for o pastor/admin autorizado,
        // NÃO retornar a listagem individual dos lançamentos nome->valor!
        $canSeeIndividual = $coleta->isOpen() || $user->hasPermission('dizimos.historico_individual.view') || $user->hasRole('pastor');

        $data = $coleta->toArray();

        if ($canSeeIndividual) {
            $data['lancamentos'] = $coleta->lancamentos()
                ->with(['person:id,full_name,envelope_number', 'creator:id,name'])
                ->latest()
                ->get();
        } else {
            $data['lancamentos'] = [];
            $data['privacy_notice'] = 'Listagem individual oculta conforme regras de privacidade do diaconato para coletas fechadas.';
        }

        return response()->json($data);
    }

    public function storeLancamento(Request $request, ColetaDizimo $coleta): JsonResponse
    {
        $validated = $request->validate([
            'person_id' => 'nullable|exists:people,id',
            'amount' => 'required|numeric|min:0.01',
            'contribution_type' => 'nullable|string|max:50',
            'is_unidentified' => 'nullable|boolean',
            'notes' => 'nullable|string',
            'force' => 'nullable|boolean',
        ]);

        try {
            $result = $this->coletaService->addLancamento(
                $coleta,
                $validated,
                $request->user(),
                (bool) ($validated['force'] ?? false)
            );

            if (! empty($result['duplicate'])) {
                return response()->json($result, 409); // Conflict / Warning
            }

            return response()->json($result, 201);
        } catch (InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function close(Request $request, ColetaDizimo $coleta): JsonResponse
    {
        $verifier = null;
        if ($request->filled('verifier_id')) {
            $verifier = User::find($request->input('verifier_id'));
        }

        try {
            $closed = $this->coletaService->closeColeta($coleta, $request->user(), $verifier);
            return response()->json($closed);
        } catch (InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function reopen(Request $request, ColetaDizimo $coleta): JsonResponse
    {
        $validated = $request->validate([
            'reason' => 'required|string|min:5|max:500',
        ]);

        try {
            $reopened = $this->coletaService->reopenColeta($coleta, $request->user(), $validated['reason']);
            return response()->json($reopened);
        } catch (InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function updateLancamento(Request $request, ColetaDizimo $coleta, LancamentoDizimo $lancamento): JsonResponse
    {
        $validated = $request->validate([
            'amount' => 'nullable|numeric|min:0.01',
            'contribution_type' => 'nullable|string|max:50',
            'notes' => 'nullable|string',
            'reason' => 'required|string|min:3|max:500',
        ]);

        try {
            $updated = $this->coletaService->updateLancamento($lancamento, $validated, $request->user(), $validated['reason']);
            return response()->json($updated);
        } catch (InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }
}
