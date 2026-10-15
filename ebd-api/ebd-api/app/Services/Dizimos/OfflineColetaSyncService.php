<?php

namespace App\Services\Dizimos;

use App\Models\OfflineColetaSync;
use App\Models\Person;
use App\Models\User;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class OfflineColetaSyncService
{
    public function __construct(private readonly ColetaService $coletaService) {}

    /**
     * Stores a mobile submission once. Repeated requests with the same client
     * operation id return the original row, which makes retries idempotent.
     */
    public function submit(User $user, array $data): OfflineColetaSync
    {
        if (! $user->institution_id) {
            throw ValidationException::withMessages([
                'institution' => ['Seu usuário precisa estar vinculado a uma instituição para enviar uma conferência offline.'],
            ]);
        }

        $payload = [
            'coleta' => Arr::sortRecursive($data['coleta']),
            'entries' => collect($data['entries'])->map(fn (array $entry) => Arr::sortRecursive($entry))->values()->all(),
        ];
        $hash = hash('sha256', json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));

        return DB::transaction(function () use ($user, $data, $payload, $hash) {
            $existing = OfflineColetaSync::where('client_operation_id', $data['client_operation_id'])
                ->lockForUpdate()
                ->first();

            if ($existing) {
                if ($existing->institution_id !== $user->institution_id || $existing->payload_hash !== $hash) {
                    throw ValidationException::withMessages([
                        'client_operation_id' => ['Esta identificação de operação já pertence a outro lote.'],
                    ]);
                }

                return $existing;
            }

            $sync = OfflineColetaSync::create([
                'client_operation_id' => $data['client_operation_id'],
                'institution_id' => $user->institution_id,
                'submitted_by' => $user->id,
                'device_id' => $data['device_id'],
                'captured_at' => $data['captured_at'],
                'payload' => $payload,
                'payload_hash' => $hash,
                'status' => OfflineColetaSync::STATUS_PENDING_REVIEW,
            ]);

            AuditoriaDizimosService::log('offline_sync.submitted', 'offline_coleta_sync', $sync->id, [
                'client_operation_id' => $sync->client_operation_id,
                'device_id' => $sync->device_id,
                'payload_hash' => $sync->payload_hash,
                'entries_count' => count($payload['entries']),
            ], $user);

            return $sync;
        });
    }

    /**
     * Materializes an approved lot into an open collection. Closing remains a
     * separate, permissioned action; offline data can therefore never close a
     * collection automatically.
     */
    public function approve(OfflineColetaSync $sync, User $reviewer, ?string $notes = null): OfflineColetaSync
    {
        return DB::transaction(function () use ($sync, $reviewer, $notes) {
            $locked = OfflineColetaSync::whereKey($sync->id)->lockForUpdate()->firstOrFail();

            if ($locked->status === OfflineColetaSync::STATUS_APPROVED) {
                return $locked;
            }
            if ($locked->status !== OfflineColetaSync::STATUS_PENDING_REVIEW) {
                throw ValidationException::withMessages(['status' => ['Somente lotes pendentes podem ser aprovados.']]);
            }
            if ((int) $locked->submitted_by === (int) $reviewer->id) {
                throw ValidationException::withMessages(['reviewer' => ['A aprovação deve ser realizada por outro usuário autorizado.']]);
            }

            /** @var User $submitter */
            $submitter = User::findOrFail($locked->submitted_by);
            $coletaData = $locked->payload['coleta'];
            $coleta = $this->coletaService->openColeta([
                'date' => $coletaData['date'],
                'service_meeting' => $coletaData['service_meeting'],
                'description' => $coletaData['description'] ?? 'Conferência registrada offline',
                'notes' => trim(($coletaData['notes'] ?? '')."\n[Lote offline aprovado: {$locked->client_operation_id}]"),
            ], $submitter);

            foreach ($locked->payload['entries'] as $entry) {
                $personId = $entry['person_id'] ?? null;
                if ($personId && ! Person::whereKey($personId)->where('institution_id', $locked->institution_id)->exists()) {
                    throw ValidationException::withMessages([
                        'entries' => ["A pessoa #{$personId} não pertence à instituição deste lote."],
                    ]);
                }

                $this->coletaService->addLancamento($coleta, [
                    'person_id' => $personId,
                    'amount' => $entry['amount'],
                    'contribution_type' => $entry['contribution_type'] ?? 'dizimo',
                    'payment_method' => $entry['payment_method'] ?? 'dinheiro',
                    'envelope_number' => $entry['envelope_number'] ?? null,
                    'contribuinte_nome' => $entry['contribuinte_nome'] ?? null,
                    'is_unidentified' => (bool) ($entry['is_unidentified'] ?? ! $personId),
                    'notes' => 'Importado de lote offline '.$locked->client_operation_id,
                ], $submitter, true);
            }

            $this->coletaService->saveOfertasAvulsas($coleta, [
                'oferta_dinheiro' => $coletaData['oferta_dinheiro'] ?? 0,
                'oferta_pix' => $coletaData['oferta_pix'] ?? 0,
                'oferta_transferencia' => $coletaData['oferta_transferencia'] ?? 0,
            ], $submitter);

            $locked->update([
                'status' => OfflineColetaSync::STATUS_APPROVED,
                'reviewed_by' => $reviewer->id,
                'reviewed_at' => now(),
                'review_notes' => $notes,
                'coleta_id' => $coleta->id,
            ]);

            AuditoriaDizimosService::log('offline_sync.approved', 'offline_coleta_sync', $locked->id, [
                'coleta_id' => $coleta->id,
                'entries_count' => count($locked->payload['entries']),
                'review_notes' => $notes,
            ], $reviewer);

            return $locked->fresh(['submitter:id,name', 'reviewer:id,name', 'coleta']);
        });
    }

    public function reject(OfflineColetaSync $sync, User $reviewer, string $notes): OfflineColetaSync
    {
        return DB::transaction(function () use ($sync, $reviewer, $notes) {
            $locked = OfflineColetaSync::whereKey($sync->id)->lockForUpdate()->firstOrFail();
            if ($locked->status !== OfflineColetaSync::STATUS_PENDING_REVIEW) {
                throw ValidationException::withMessages(['status' => ['Somente lotes pendentes podem ser recusados.']]);
            }

            $locked->update([
                'status' => OfflineColetaSync::STATUS_REJECTED,
                'reviewed_by' => $reviewer->id,
                'reviewed_at' => now(),
                'review_notes' => $notes,
            ]);

            AuditoriaDizimosService::log('offline_sync.rejected', 'offline_coleta_sync', $locked->id, [
                'review_notes' => $notes,
            ], $reviewer);

            return $locked->fresh(['submitter:id,name', 'reviewer:id,name']);
        });
    }
}
