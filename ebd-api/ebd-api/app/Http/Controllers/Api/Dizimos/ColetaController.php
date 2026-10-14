<?php

namespace App\Http\Controllers\Api\Dizimos;

use App\Http\Controllers\Controller;
use App\Models\ColetaDizimo;
use App\Models\LancamentoDizimo;
use App\Models\ConferenciaImpressao;
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
            $status = $request->query('status');
            if ($status === 'em_andamento' || $status === 'Aberta') {
                $query->whereIn('status', ['Aberta', 'Reaberta para correção']);
            } elseif ($status === 'encerrada' || $status === 'Fechada') {
                $query->where('status', 'Fechada');
            } else {
                $query->where('status', $status);
            }
        }

        if ($request->filled('date_from')) {
            $query->where('date', '>=', $request->query('date_from'));
        }
        if ($request->filled('date_to')) {
            $query->where('date', '<=', $request->query('date_to'));
        }

        if ($request->filled('responsible_id')) {
            $query->where('created_by', (int) $request->query('responsible_id'));
        }

        if ($request->filled('search')) {
            $term = trim($request->query('search'));
            $query->where(function ($q) use ($term) {
                $q->where('code', 'ILIKE', "%{$term}%")
                    ->orWhere('service_meeting', 'ILIKE', "%{$term}%")
                    ->orWhere('description', 'ILIKE', "%{$term}%");
            });
        }

        $coletas = $query->orderBy('created_at', 'desc')->paginate((int) ($request->query('per_page', 25)));

        return response()->json($coletas);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'date' => 'nullable|date',
            'service_meeting' => 'nullable|string|max:100',
            'description' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
        ]);

        $coleta = $this->coletaService->openColeta($validated, $request->user());

        return response()->json($coleta, 201);
    }

    public function show(Request $request, ColetaDizimo $coleta): JsonResponse
    {
        $coleta->load(['creator:id,name', 'closer:id,name', 'verifier:id,name', 'impressoes.user:id,name']);
        $user = $request->user();

        $canSeeIndividual = $coleta->isOpen() || $user->hasPermission('dizimos.historico_individual.view') || $user->hasRole('pastor') || $user->hasRole('admin') || $user->isMasterUser();

        $data = $coleta->toArray();

        if ($canSeeIndividual) {
            $data['lancamentos'] = $coleta->lancamentos()
                ->with(['person:id,full_name,envelope_number', 'creator:id,name'])
                ->orderBy('id', 'desc')
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
            'payment_method' => 'nullable|string|max:30',
            'envelope_number' => 'nullable|string|max:50',
            'contribuinte_nome' => 'nullable|string|max:255',
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

            if (!empty($result['duplicate'])) {
                return response()->json($result, 409);
            }

            return response()->json($result, 201);
        } catch (InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function updateLancamento(Request $request, ColetaDizimo $coleta, LancamentoDizimo $lancamento): JsonResponse
    {
        $validated = $request->validate([
            'amount' => 'nullable|numeric|min:0.01',
            'payment_method' => 'nullable|string|max:30',
            'contribution_type' => 'nullable|string|max:50',
            'envelope_number' => 'nullable|string|max:50',
            'notes' => 'nullable|string',
            'reason' => 'nullable|string|max:500',
        ]);

        try {
            $reason = $validated['reason'] ?? 'Ajuste de valor/forma pelo operador da conferência';
            $updated = $this->coletaService->updateLancamento($lancamento, $validated, $request->user(), $reason);
            return response()->json($updated);
        } catch (InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function destroyLancamento(Request $request, ColetaDizimo $coleta, LancamentoDizimo $lancamento): JsonResponse
    {
        try {
            $reason = $request->input('reason', 'Exclusão solicitada na conferência');
            $this->coletaService->deleteLancamento($lancamento, $request->user(), $reason);
            return response()->json(['message' => 'Lançamento removido com sucesso.', 'coleta' => $coleta->fresh()]);
        } catch (InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function saveOfertas(Request $request, ColetaDizimo $coleta): JsonResponse
    {
        $validated = $request->validate([
            'oferta_dinheiro' => 'nullable|numeric|min:0',
            'oferta_pix' => 'nullable|numeric|min:0',
            'oferta_transferencia' => 'nullable|numeric|min:0',
        ]);

        try {
            $updated = $this->coletaService->saveOfertasAvulsas($coleta, $validated, $request->user());
            return response()->json($updated);
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

        $ofertas = [];
        if ($request->has('oferta_dinheiro') || $request->has('oferta_pix') || $request->has('oferta_transferencia')) {
            $ofertas = [
                'oferta_dinheiro' => $request->input('oferta_dinheiro', 0),
                'oferta_pix' => $request->input('oferta_pix', 0),
                'oferta_transferencia' => $request->input('oferta_transferencia', 0),
            ];
        }

        try {
            $closed = $this->coletaService->closeColeta($coleta, $request->user(), $verifier, $ofertas);
            $comprovante = $this->coletaService->getComprovanteData($closed, false, $request->user());

            return response()->json([
                'coleta' => $closed,
                'comprovante' => $comprovante,
                'message' => 'Conferência encerrada com sucesso.',
            ]);
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

    public function comprovante(Request $request, ColetaDizimo $coleta): JsonResponse
    {
        $data = $this->coletaService->getComprovanteData($coleta, false, $request->user());
        return response()->json($data);
    }

    public function reimprimir(Request $request, ColetaDizimo $coleta): JsonResponse
    {
        $data = $this->coletaService->getComprovanteData($coleta, true, $request->user());
        return response()->json($data);
    }

    public function registrarImpressao(Request $request, ColetaDizimo $coleta): JsonResponse
    {
        $validated = $request->validate([
            'via' => 'required|string|max:50',
            'tipo' => 'nullable|string|max:30',
            'status' => 'nullable|string|max:30',
            'device_info' => 'nullable|string|max:255',
        ]);

        $log = ConferenciaImpressao::create([
            'coleta_id' => $coleta->id,
            'via' => $validated['via'],
            'tipo' => $validated['tipo'] ?? 'original',
            'status' => $validated['status'] ?? 'sucesso',
            'user_id' => $request->user()?->id,
            'device_info' => $validated['device_info'] ?? null,
            'created_at' => now('America/Sao_Paulo'),
        ]);

        return response()->json($log, 201);
    }
}
