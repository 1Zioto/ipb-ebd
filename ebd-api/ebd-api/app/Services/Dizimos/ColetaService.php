<?php

namespace App\Services\Dizimos;

use App\Models\ColetaDizimo;
use App\Models\ConferenciaImpressao;
use App\Models\LancamentoDizimo;
use App\Models\Person;
use App\Models\Setting;
use App\Models\User;
use App\Models\Institution;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class ColetaService
{
    public function openColeta(array $data, User $user): ColetaDizimo
    {
        return DB::transaction(function () use ($data, $user) {
            $nowSp = Carbon::now('America/Sao_Paulo');
            $institutionId = $user->institution_id ?: 5;

            $coleta = ColetaDizimo::create([
                'institution_id' => $institutionId,
                'date' => $data['date'] ?? $nowSp->toDateString(),
                'description' => $data['description'] ?? null,
                'service_meeting' => $data['service_meeting'] ?? 'Culto Noturno Dominical',
                'status' => 'Aberta',
                'created_by' => $user->id,
                'opened_at' => $nowSp,
                'entry_count' => 0,
                'total_amount' => 0.00,
                'total_dizimos' => 0.00,
                'oferta_dinheiro' => 0.00,
                'oferta_pix' => 0.00,
                'oferta_transferencia' => 0.00,
                'total_ofertas' => 0.00,
                'total_geral' => 0.00,
                'unidentified_count' => 0,
                'notes' => $data['notes'] ?? null,
            ]);

            $code = 'CONF-' . str_pad((string) $coleta->id, 6, '0', STR_PAD_LEFT);
            $coleta->update(['code' => $code]);

            AuditoriaDizimosService::log('coleta.abrir', 'coleta_dizimo', $coleta->id, [
                'code' => $code,
                'date' => $coleta->date->toDateString(),
                'service_meeting' => $coleta->service_meeting,
            ], $user);

            return $coleta->fresh(['creator:id,name']);
        });
    }

    public function addLancamento(ColetaDizimo $coleta, array $data, User $user, bool $force = false): array
    {
        if (!$coleta->isOpen()) {
            throw new InvalidArgumentException("A conferência {$coleta->code} (#{$coleta->id}) está encerrada para novos lançamentos.");
        }

        $isUnidentified = !empty($data['is_unidentified']) || empty($data['person_id']);
        $personId = $isUnidentified ? null : (int) $data['person_id'];

        $person = $personId ? Person::find($personId) : null;
        $envelopeNumber = $data['envelope_number'] ?? $person?->envelope_number ?? null;
        $contribuinteNome = $data['contribuinte_nome'] ?? ($person ? $person->full_name : ($isUnidentified ? 'Não identificado / Oferta' : null));
        $paymentMethod = strtolower($data['payment_method'] ?? 'dinheiro');
        if (!in_array($paymentMethod, ['dinheiro', 'pix', 'transferencia', 'outros'])) {
            $paymentMethod = 'dinheiro';
        }

        // Checagem de lançamento duplicado do mesmo envelope físico / pessoa
        if (!$isUnidentified && !$force) {
            $existing = LancamentoDizimo::where('coleta_id', $coleta->id)
                ->where(function ($q) use ($personId, $envelopeNumber) {
                    $q->where('person_id', $personId);
                    if ($envelopeNumber) {
                        $q->orWhere('envelope_number', $envelopeNumber);
                    }
                })
                ->first();

            if ($existing) {
                $personName = $person?->full_name ?? 'Membro';
                return [
                    'duplicate' => true,
                    'message' => "Já existe um lançamento registrado para {$personName} nesta conferência.",
                    'existing_id' => $existing->id,
                    'existing_amount' => (float) $existing->amount,
                ];
            }
        }

        return DB::transaction(function () use ($coleta, $data, $user, $isUnidentified, $personId, $envelopeNumber, $contribuinteNome, $paymentMethod) {
            $lancamento = LancamentoDizimo::create([
                'coleta_id' => $coleta->id,
                'institution_id' => $coleta->institution_id,
                'person_id' => $personId,
                'amount' => (float) $data['amount'],
                'contribution_type' => $data['contribution_type'] ?? 'envelope',
                'payment_method' => $paymentMethod,
                'envelope_number' => $envelopeNumber,
                'contribuinte_nome' => $contribuinteNome,
                'is_unidentified' => $isUnidentified,
                'notes' => $data['notes'] ?? null,
                'created_by' => $user->id,
            ]);

            $this->recalculateColetaTotals($coleta);

            AuditoriaDizimosService::log('lancamento.criar', 'lancamento_dizimo', $lancamento->id, [
                'coleta_id' => $coleta->id,
                'amount' => (float) $lancamento->amount,
                'payment_method' => $paymentMethod,
                'envelope_number' => $envelopeNumber,
                'is_unidentified' => $isUnidentified,
                'contribuinte_nome' => $contribuinteNome,
            ], $user);

            return [
                'duplicate' => false,
                'lancamento' => $lancamento->fresh('person:id,full_name,envelope_number'),
                'coleta_summary' => [
                    'entry_count' => $coleta->entry_count,
                    'total_dizimos' => (float) $coleta->total_dizimos,
                    'total_ofertas' => (float) $coleta->total_ofertas,
                    'total_geral' => (float) $coleta->total_geral,
                    'total_amount' => (float) $coleta->total_amount,
                    'unidentified_count' => $coleta->unidentified_count,
                ],
            ];
        });
    }

    public function updateLancamento(LancamentoDizimo $lancamento, array $data, User $user, string $reason): LancamentoDizimo
    {
        $coleta = $lancamento->coleta;

        if ($coleta->isClosed()) {
            throw new InvalidArgumentException('Esta conferência está encerrada. Para alterar lançamentos, reabra a conferência formalmente.');
        }

        return DB::transaction(function () use ($lancamento, $coleta, $data, $user, $reason) {
            $previousAmount = (float) $lancamento->amount;
            $newAmount = isset($data['amount']) ? (float) $data['amount'] : $previousAmount;
            $paymentMethod = isset($data['payment_method']) ? strtolower($data['payment_method']) : $lancamento->payment_method;

            $lancamento->update([
                'amount' => $newAmount,
                'payment_method' => $paymentMethod,
                'contribution_type' => $data['contribution_type'] ?? $lancamento->contribution_type,
                'envelope_number' => $data['envelope_number'] ?? $lancamento->envelope_number,
                'notes' => $data['notes'] ?? $lancamento->notes,
                'updated_by' => $user->id,
            ]);

            $this->recalculateColetaTotals($coleta);

            AuditoriaDizimosService::log('lancamento.corrigir', 'lancamento_dizimo', $lancamento->id, [
                'previous_amount' => $previousAmount,
                'new_amount' => $newAmount,
                'reason' => $reason,
            ], $user);

            return $lancamento->fresh('person:id,full_name,envelope_number');
        });
    }

    public function deleteLancamento(LancamentoDizimo $lancamento, User $user, ?string $reason = null): bool
    {
        $coleta = $lancamento->coleta;

        if ($coleta->isClosed()) {
            throw new InvalidArgumentException('Esta conferência está encerrada. Não é permitido excluir lançamentos de conferência concluída.');
        }

        return DB::transaction(function () use ($lancamento, $coleta, $user, $reason) {
            $id = $lancamento->id;
            $amount = (float) $lancamento->amount;
            $personName = $lancamento->contribuinte_nome ?? $lancamento->person?->full_name ?? 'Envelope';

            $lancamento->delete();
            $this->recalculateColetaTotals($coleta);

            AuditoriaDizimosService::log('lancamento.excluir', 'lancamento_dizimo', $id, [
                'coleta_id' => $coleta->id,
                'person_name' => $personName,
                'amount' => $amount,
                'reason' => $reason ?: 'Exclusão solicitada pelo operador',
            ], $user);

            return true;
        });
    }

    public function saveOfertasAvulsas(ColetaDizimo $coleta, array $ofertas, User $user): ColetaDizimo
    {
        if ($coleta->isClosed()) {
            throw new InvalidArgumentException('Conferência encerrada. Não é possível alterar ofertas avulsas.');
        }

        return DB::transaction(function () use ($coleta, $ofertas, $user) {
            $dinheiro = max(0, (float) ($ofertas['oferta_dinheiro'] ?? $coleta->oferta_dinheiro ?? 0));
            $pix = max(0, (float) ($ofertas['oferta_pix'] ?? $coleta->oferta_pix ?? 0));
            $transf = max(0, (float) ($ofertas['oferta_transferencia'] ?? $coleta->oferta_transferencia ?? 0));

            $totalOfertas = $dinheiro + $pix + $transf;

            $coleta->update([
                'oferta_dinheiro' => $dinheiro,
                'oferta_pix' => $pix,
                'oferta_transferencia' => $transf,
                'total_ofertas' => $totalOfertas,
            ]);

            $this->recalculateColetaTotals($coleta);

            AuditoriaDizimosService::log('ofertas_avulsas.atualizar', 'coleta_dizimo', $coleta->id, [
                'oferta_dinheiro' => $dinheiro,
                'oferta_pix' => $pix,
                'oferta_transferencia' => $transf,
                'total_ofertas' => $totalOfertas,
            ], $user);

            return $coleta->fresh();
        });
    }

    public function closeColeta(ColetaDizimo $coleta, User $user, ?User $verifier = null, array $ofertas = []): ColetaDizimo
    {
        $requireDoubleCheck = (bool) Setting::where('key', 'tithes_require_double_check')->value('value');

        if ($requireDoubleCheck && !$verifier) {
            throw new InvalidArgumentException('As configurações institucionais exigem dupla conferência para encerramento.');
        }

        return DB::transaction(function () use ($coleta, $user, $verifier, $ofertas) {
            // Lock na linha para prevenir encerramentos simultâneos
            $locked = ColetaDizimo::where('id', $coleta->id)->lockForUpdate()->first();
            if ($locked->isClosed()) {
                throw new InvalidArgumentException("A conferência {$locked->code} já foi encerrada anteriormente.");
            }

            if (!empty($ofertas)) {
                $dinheiro = max(0, (float) ($ofertas['oferta_dinheiro'] ?? $locked->oferta_dinheiro ?? 0));
                $pix = max(0, (float) ($ofertas['oferta_pix'] ?? $locked->oferta_pix ?? 0));
                $transf = max(0, (float) ($ofertas['oferta_transferencia'] ?? $locked->oferta_transferencia ?? 0));
                $locked->update([
                    'oferta_dinheiro' => $dinheiro,
                    'oferta_pix' => $pix,
                    'oferta_transferencia' => $transf,
                    'total_ofertas' => $dinheiro + $pix + $transf,
                ]);
            }

            $this->recalculateColetaTotals($locked);

            $nowSp = Carbon::now('America/Sao_Paulo');
            $locked->update([
                'status' => 'Fechada',
                'closed_by' => $user->id,
                'closed_at' => $nowSp,
                'verified_by' => $verifier?->id,
                'verified_at' => $verifier ? $nowSp : null,
            ]);

            // Registrar os jobs iniciais de impressão das DUAS VIAS
            ConferenciaImpressao::create([
                'coleta_id' => $locked->id,
                'via' => '1a_via_tesouraria',
                'tipo' => 'original',
                'status' => 'solicitada',
                'user_id' => $user->id,
                'device_info' => 'Fechamento Automático',
                'created_at' => $nowSp,
            ]);

            ConferenciaImpressao::create([
                'coleta_id' => $locked->id,
                'via' => '2a_via_arquivo',
                'tipo' => 'original',
                'status' => 'solicitada',
                'user_id' => $user->id,
                'device_info' => 'Fechamento Automático',
                'created_at' => $nowSp,
            ]);

            AuditoriaDizimosService::log('coleta.fechar', 'coleta_dizimo', $locked->id, [
                'total_dizimos' => (float) $locked->total_dizimos,
                'total_ofertas' => (float) $locked->total_ofertas,
                'total_geral' => (float) $locked->total_geral,
                'entry_count' => $locked->entry_count,
                'closed_by' => $user->id,
                'closed_at' => $nowSp->toDateTimeString(),
            ], $user);

            // Disparar consolidação do mês automaticamente
            try {
                app(AlertEngineService::class)->consolidateMonth($locked->date->year, $locked->date->month);
            } catch (\Throwable $e) {}

            // Sincronizar receita no Livro Caixa Financeiro
            try {
                app(\App\Services\Financial\FinancialService::class)->syncFromColeta($locked, $user);
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('Erro ao sincronizar coleta no financeiro: ' . $e->getMessage());
            }

            return $locked->fresh(['creator:id,name', 'closer:id,name', 'verifier:id,name']);
        });
    }

    public function reopenColeta(ColetaDizimo $coleta, User $user, string $reason): ColetaDizimo
    {
        if (blank($reason)) {
            throw new InvalidArgumentException('É obrigatório informar a justificativa para reabertura da conferência.');
        }

        return DB::transaction(function () use ($coleta, $user, $reason) {
            $coleta->update([
                'status' => 'Reaberta para correção',
                'notes' => trim($coleta->notes . "\n[Reabertura em " . now('America/Sao_Paulo')->format('d/m/Y H:i') . ' por ' . $user->name . ']: ' . $reason),
            ]);

            try {
                app(\App\Services\Financial\FinancialService::class)->syncFromColeta($coleta, $user);
            } catch (\Throwable $e) {}

            AuditoriaDizimosService::log('coleta.reabrir', 'coleta_dizimo', $coleta->id, [
                'reason' => $reason,
            ], $user);

            return $coleta->fresh(['creator:id,name', 'closer:id,name']);
        });
    }

    public function recalculateColetaTotals(ColetaDizimo $coleta): void
    {
        $lancamentos = LancamentoDizimo::where('coleta_id', $coleta->id)->get();

        $totalEntries = $lancamentos->count();
        $totalDizimos = (float) $lancamentos->sum('amount');
        $unidentifiedCount = $lancamentos->where('is_unidentified', true)->count();

        $ofertaDinheiro = (float) ($coleta->oferta_dinheiro ?? 0);
        $ofertaPix = (float) ($coleta->oferta_pix ?? 0);
        $ofertaTransf = (float) ($coleta->oferta_transferencia ?? 0);
        $totalOfertas = $ofertaDinheiro + $ofertaPix + $ofertaTransf;

        $totalGeral = $totalDizimos + $totalOfertas;

        $coleta->update([
            'entry_count' => $totalEntries,
            'total_dizimos' => $totalDizimos,
            'total_ofertas' => $totalOfertas,
            'total_geral' => $totalGeral,
            'total_amount' => $totalGeral,
            'unidentified_count' => $unidentifiedCount,
        ]);
    }

    public function getComprovanteData(ColetaDizimo $coleta, bool $isReimpressao = false, ?User $solicitante = null): array
    {
        $coleta->load(['creator:id,name', 'closer:id,name', 'verifier:id,name']);

        $institution = Institution::with('parent.parent')->find($coleta->institution_id ?: 5);
        $nomeIgreja = $institution?->name ?: 'Igreja Presbiteriana de Campo Verde';
        $cnpj = $institution?->cnpj ?: '04.839.291/0001-44';
        $presb = $institution?->parent?->name;
        $sinodo = $institution?->parent?->parent?->name;
        $jurisdicao = trim(implode(' • ', array_filter([$presb, $sinodo]))) ?: 'Presbitério Sudeste Espírito Santo (PSES) • Sínodo Central Espíritossantense (SCE)';

        $lancamentos = LancamentoDizimo::where('coleta_id', $coleta->id)
            ->with(['person:id,full_name,envelope_number'])
            ->orderBy('id', 'asc')
            ->get();

        $itensDizimos = $lancamentos->map(function ($l) {
            $contribuinte = $l->person?->full_name ?? $l->contribuinte_nome ?? ($l->is_unidentified ? 'Oferta Identificada' : 'Envelope');
            $env = $l->envelope_number ?? $l->person?->envelope_number;
            return [
                'id' => $l->id,
                'envelope' => $env,
                'contribuinte' => $contribuinte,
                'membro' => $contribuinte,
                'valor' => (float) $l->amount,
                'amount' => (float) $l->amount,
                'forma' => strtoupper($l->payment_method ?: 'DINHEIRO'),
                'payment_method' => strtolower($l->payment_method ?: 'dinheiro'),
                'hora' => $l->created_at ? $l->created_at->format('H:i') : '',
            ];
        })->values()->all();

        $dizimosDinheiro = (float) $lancamentos->where('payment_method', 'dinheiro')->sum('amount');
        $dizimosPix = (float) $lancamentos->where('payment_method', 'pix')->sum('amount');
        $dizimosTransf = (float) $lancamentos->where('payment_method', 'transferencia')->sum('amount');
        $dizimosOutros = (float) $lancamentos->whereNotIn('payment_method', ['dinheiro', 'pix', 'transferencia'])->sum('amount');
        $totalDizimos = (float) $lancamentos->sum('amount');

        $ofertaDinheiro = (float) ($coleta->oferta_dinheiro ?? 0);
        $ofertaPix = (float) ($coleta->oferta_pix ?? 0);
        $ofertaTransf = (float) ($coleta->oferta_transferencia ?? 0);
        $totalOfertas = $ofertaDinheiro + $ofertaPix + $ofertaTransf;

        $totalGeral = $totalDizimos + $totalOfertas;

        $totalConsolidadoDinheiro = $dizimosDinheiro + $ofertaDinheiro;
        $totalConsolidadoPix = $dizimosPix + $ofertaPix;
        $totalConsolidadoTransf = $dizimosTransf + $ofertaTransf + $dizimosOutros;

        $nowSp = Carbon::now('America/Sao_Paulo');

        // Se foi solicitado como reimpressão, registrar no histórico
        if ($isReimpressao && $solicitante) {
            ConferenciaImpressao::create([
                'coleta_id' => $coleta->id,
                'via' => 'reimpressao_completa',
                'tipo' => 'reimpressao',
                'status' => 'sucesso',
                'user_id' => $solicitante->id,
                'device_info' => 'Reimpressão solicitada',
                'created_at' => $nowSp,
            ]);
        }

        return [
            'conferencia' => [
                'id' => $coleta->id,
                'code' => $coleta->code ?: ('CONF-' . str_pad((string) $coleta->id, 6, '0', STR_PAD_LEFT)),
                'date' => $coleta->date ? $coleta->date->format('d/m/Y') : '',
                'culto' => $coleta->service_meeting ?: 'Culto de Domingo',
                'service_meeting' => $coleta->service_meeting ?: 'Culto de Domingo',
                'status' => $coleta->status,
                'entry_count' => count($itensDizimos),
                'opened_at' => $coleta->opened_at ? $coleta->opened_at->format('d/m/Y H:i') : '',
                'closed_at' => $coleta->closed_at ? $coleta->closed_at->format('d/m/Y H:i') : '',
                'responsavel_abertura' => $coleta->creator?->name ?? 'Oficial Autorizado',
                'responsavel_encerramento' => $coleta->closer?->name ?? $coleta->creator?->name ?? 'Diácono Responsável',
                'closer_name' => $coleta->closer?->name ?? $coleta->creator?->name ?? 'Diácono Responsável',
                'creator_name' => $coleta->creator?->name ?? 'Oficial Autorizado',
                'conferente_duplo' => $coleta->verifier?->name,
                'total_dizimos' => $totalDizimos,
                'total_ofertas' => $totalOfertas,
                'total_geral' => $totalGeral,
            ],
            'instituicao' => [
                'nome' => $nomeIgreja,
                'cnpj' => $cnpj,
                'jurisdicao' => $jurisdicao,
            ],
            'church_name' => $nomeIgreja,
            'lancamentos' => $itensDizimos,
            'dizimos' => [
                'itens' => $itensDizimos,
                'quantidade_envelopes' => count($itensDizimos),
                'total_dinheiro' => $dizimosDinheiro,
                'total_pix' => $dizimosPix,
                'total_transferencia' => $dizimosTransf,
                'total' => $totalDizimos,
            ],
            'ofertas_avulsas' => [
                'dinheiro' => $ofertaDinheiro,
                'pix' => $ofertaPix,
                'transferencia' => $ofertaTransf,
                'total' => $totalOfertas,
            ],
            'totais' => [
                'dizimos' => $totalDizimos,
                'ofertas' => $totalOfertas,
                'geral' => $totalGeral,
            ],
            'resumo_geral' => [
                'total_dizimos' => $totalDizimos,
                'total_ofertas' => $totalOfertas,
                'total_geral' => $totalGeral,
            ],
            'por_recebimento' => [
                'dinheiro' => $totalConsolidadoDinheiro,
                'pix' => $totalConsolidadoPix,
                'transferencia' => $totalConsolidadoTransf,
                'geral' => $totalGeral,
            ],
            'consolidado_recebimento' => [
                'dinheiro' => $totalConsolidadoDinheiro,
                'pix' => $totalConsolidadoPix,
                'transferencia' => $totalConsolidadoTransf,
                'total_geral' => $totalGeral,
            ],
            'meta' => [
                'is_reimpressao' => $isReimpressao,
                'reimpressao_texto' => $isReimpressao ? 'REIMPRESSÃO' : null,
                'reimpresso_por' => $isReimpressao && $solicitante ? $solicitante->name : null,
                'reimpresso_em' => $isReimpressao ? $nowSp->format('d/m/Y H:i:s') : null,
                'emitido_em' => $nowSp->format('d/m/Y H:i:s'),
            ],
        ];
    }
}
