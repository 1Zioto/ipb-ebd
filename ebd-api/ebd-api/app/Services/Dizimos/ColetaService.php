<?php

namespace App\Services\Dizimos;

use App\Models\ColetaDizimo;
use App\Models\LancamentoDizimo;
use App\Models\Person;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class ColetaService
{
    public function openColeta(array $data, User $user): ColetaDizimo
    {
        return DB::transaction(function () use ($data, $user) {
            $coleta = ColetaDizimo::create([
                'date' => $data['date'] ?? now()->toDateString(),
                'description' => $data['description'] ?? null,
                'service_meeting' => $data['service_meeting'] ?? 'Culto de Domingo',
                'status' => 'Aberta',
                'created_by' => $user->id,
                'opened_at' => now(),
                'entry_count' => 0,
                'total_amount' => 0.00,
                'unidentified_count' => 0,
                'notes' => $data['notes'] ?? null,
            ]);

            AuditoriaDizimosService::log('coleta.abrir', 'coleta_dizimo', $coleta->id, [
                'date' => $coleta->date->toDateString(),
                'service_meeting' => $coleta->service_meeting,
            ], $user);

            return $coleta;
        });
    }

    public function addLancamento(ColetaDizimo $coleta, array $data, User $user, bool $force = false): array
    {
        if (! $coleta->isOpen()) {
            throw new InvalidArgumentException("A coleta #{$coleta->id} está fechada para novos lançamentos.");
        }

        $isUnidentified = ! empty($data['is_unidentified']) || empty($data['person_id']);
        $personId = $isUnidentified ? null : (int) $data['person_id'];

        // Checagem de lançamento duplicado para o mesmo membro nesta coleta
        if (! $isUnidentified && ! $force) {
            $existing = LancamentoDizimo::where('coleta_id', $coleta->id)
                ->where('person_id', $personId)
                ->first();

            if ($existing) {
                $personName = Person::find($personId)?->full_name ?? 'Membro';
                return [
                    'duplicate' => true,
                    'message' => "Já existe uma contribuição registrada para {$personName} nesta coleta.",
                    'existing_id' => $existing->id,
                    'existing_amount' => (float) $existing->amount,
                ];
            }
        }

        return DB::transaction(function () use ($coleta, $data, $user, $isUnidentified, $personId) {
            $lancamento = LancamentoDizimo::create([
                'coleta_id' => $coleta->id,
                'person_id' => $personId,
                'amount' => (float) $data['amount'],
                'contribution_type' => $data['contribution_type'] ?? 'envelope',
                'is_unidentified' => $isUnidentified,
                'notes' => $data['notes'] ?? null,
                'created_by' => $user->id,
            ]);

            $this->recalculateColetaTotals($coleta);

            AuditoriaDizimosService::log('lancamento.criar', 'lancamento_dizimo', $lancamento->id, [
                'coleta_id' => $coleta->id,
                'is_unidentified' => $isUnidentified,
                'has_person' => ! $isUnidentified,
            ], $user);

            return [
                'duplicate' => false,
                'lancamento' => $lancamento->fresh('person:id,full_name,envelope_number'),
                'coleta_summary' => [
                    'entry_count' => $coleta->entry_count,
                    'total_amount' => (float) $coleta->total_amount,
                    'unidentified_count' => $coleta->unidentified_count,
                ],
            ];
        });
    }

    public function closeColeta(ColetaDizimo $coleta, User $user, ?User $verifier = null): ColetaDizimo
    {
        $requireDoubleCheck = (bool) Setting::where('key', 'tithes_require_double_check')->value('value');

        if ($requireDoubleCheck && ! $verifier) {
            throw new InvalidArgumentException('As configurações exigem uma dupla conferência para fechar a coleta.');
        }

        return DB::transaction(function () use ($coleta, $user, $verifier) {
            $this->recalculateColetaTotals($coleta);

            $coleta->update([
                'status' => 'Fechada',
                'closed_by' => $user->id,
                'closed_at' => now(),
                'verified_by' => $verifier?->id,
                'verified_at' => $verifier ? now() : null,
            ]);

            AuditoriaDizimosService::log('coleta.fechar', 'coleta_dizimo', $coleta->id, [
                'total_amount' => (float) $coleta->total_amount,
                'entry_count' => $coleta->entry_count,
                'verified_by' => $verifier?->id,
            ], $user);

            // Disparar consolidação do mês automaticamente
            app(AlertEngineService::class)->consolidateMonth($coleta->date->year, $coleta->date->month);

            return $coleta;
        });
    }

    public function reopenColeta(ColetaDizimo $coleta, User $user, string $reason): ColetaDizimo
    {
        if (blank($reason)) {
            throw new InvalidArgumentException('É obrigatório informar o motivo para reabrir a coleta.');
        }

        return DB::transaction(function () use ($coleta, $user, $reason) {
            $coleta->update([
                'status' => 'Reaberta para correção',
                'notes' => trim($coleta->notes . "\n[Reabertura em " . now()->format('d/m/Y H:i') . ' por ' . $user->name . ']: ' . $reason),
            ]);

            AuditoriaDizimosService::log('coleta.reabrir', 'coleta_dizimo', $coleta->id, [
                'reason' => $reason,
            ], $user);

            return $coleta;
        });
    }

    public function updateLancamento(LancamentoDizimo $lancamento, array $data, User $user, string $reason): LancamentoDizimo
    {
        $coleta = $lancamento->coleta;

        if ($coleta->isClosed()) {
            throw new InvalidArgumentException('Para alterar um lançamento em coleta fechada, reabra a coleta primeiro.');
        }

        return DB::transaction(function () use ($lancamento, $coleta, $data, $user, $reason) {
            $previousAmount = (float) $lancamento->amount;
            $newAmount = isset($data['amount']) ? (float) $data['amount'] : $previousAmount;

            $lancamento->update([
                'amount' => $newAmount,
                'contribution_type' => $data['contribution_type'] ?? $lancamento->contribution_type,
                'notes' => $data['notes'] ?? $lancamento->notes,
                'updated_by' => $user->id,
            ]);

            $this->recalculateColetaTotals($coleta);

            AuditoriaDizimosService::log('lancamento.corrigir', 'lancamento_dizimo', $lancamento->id, [
                'previous_amount' => $previousAmount,
                'new_amount' => $newAmount,
                'reason' => $reason,
            ], $user);

            return $lancamento;
        });
    }

    public function recalculateColetaTotals(ColetaDizimo $coleta): void
    {
        $totals = LancamentoDizimo::where('coleta_id', $coleta->id)
            ->selectRaw('COUNT(*) as total_entries, SUM(amount) as total_sum, SUM(CASE WHEN is_unidentified = 1 THEN 1 ELSE 0 END) as total_unidentified')
            ->first();

        $coleta->update([
            'entry_count' => (int) ($totals->total_entries ?? 0),
            'total_amount' => (float) ($totals->total_sum ?? 0),
            'unidentified_count' => (int) ($totals->total_unidentified ?? 0),
        ]);
    }
}
