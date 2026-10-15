<?php

namespace App\Http\Controllers\Api\Dizimos;

use App\Http\Controllers\Controller;
use App\Models\OfflineColetaSync;
use App\Services\Dizimos\OfflineColetaSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class OfflineColetaSyncController extends Controller
{
    public function __construct(private readonly OfflineColetaSyncService $service) {}

    public function index(Request $request): JsonResponse
    {
        $query = OfflineColetaSync::query()
            ->with(['submitter:id,name', 'reviewer:id,name', 'coleta:id,code,status'])
            ->where('institution_id', $request->user()->institution_id)
            ->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if (! $request->user()->hasPermission('dizimos.coleta.approve')) {
            $query->where('submitted_by', $request->user()->id);
        }

        return response()->json($query->paginate($request->integer('per_page', 25)));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'client_operation_id' => ['required', 'uuid'],
            'device_id' => ['required', 'string', 'min:16', 'max:128'],
            'captured_at' => ['required', 'date'],
            'coleta' => ['required', 'array'],
            'coleta.date' => ['required', 'date'],
            'coleta.service_meeting' => ['required', 'string', 'max:100'],
            'coleta.description' => ['nullable', 'string', 'max:255'],
            'coleta.notes' => ['nullable', 'string', 'max:4000'],
            'coleta.oferta_dinheiro' => ['nullable', 'numeric', 'min:0'],
            'coleta.oferta_pix' => ['nullable', 'numeric', 'min:0'],
            'coleta.oferta_transferencia' => ['nullable', 'numeric', 'min:0'],
            'entries' => ['required', 'array', 'min:1', 'max:1000'],
            'entries.*.person_id' => ['nullable', 'integer'],
            'entries.*.amount' => ['required', 'numeric', 'min:0.01'],
            'entries.*.contribution_type' => ['nullable', 'string', 'max:50'],
            'entries.*.payment_method' => ['nullable', Rule::in(['dinheiro', 'pix', 'transferencia', 'outros'])],
            'entries.*.envelope_number' => ['nullable', 'string', 'max:50'],
            'entries.*.contribuinte_nome' => ['nullable', 'string', 'max:255'],
            'entries.*.is_unidentified' => ['nullable', 'boolean'],
        ]);

        $sync = $this->service->submit($request->user(), $validated);

        return response()->json([
            'data' => $sync->load(['submitter:id,name', 'reviewer:id,name', 'coleta:id,code,status']),
            'message' => $sync->wasRecentlyCreated
                ? 'Lote offline recebido e aguardando aprovação.'
                : 'Este lote já havia sido recebido anteriormente.',
        ], $sync->wasRecentlyCreated ? 201 : 200);
    }

    public function approve(Request $request, OfflineColetaSync $offlineSync): JsonResponse
    {
        $this->ensureInstitution($request, $offlineSync);
        $notes = $request->validate(['review_notes' => ['nullable', 'string', 'max:2000']]);
        $sync = $this->service->approve($offlineSync, $request->user(), $notes['review_notes'] ?? null);

        return response()->json([
            'data' => $sync,
            'message' => 'Lote aprovado. A coleta foi aberta e aguarda o fechamento regular.',
        ]);
    }

    public function reject(Request $request, OfflineColetaSync $offlineSync): JsonResponse
    {
        $this->ensureInstitution($request, $offlineSync);
        $data = $request->validate(['review_notes' => ['required', 'string', 'min:5', 'max:2000']]);
        $sync = $this->service->reject($offlineSync, $request->user(), $data['review_notes']);

        return response()->json(['data' => $sync, 'message' => 'Lote recusado com justificativa registrada.']);
    }

    private function ensureInstitution(Request $request, OfflineColetaSync $sync): void
    {
        if ((int) $request->user()->institution_id !== (int) $sync->institution_id) {
            throw ValidationException::withMessages(['offline_sync' => ['Lote não pertence à sua instituição.']]);
        }
    }
}
