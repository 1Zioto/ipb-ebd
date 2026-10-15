<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use LogicException;

/**
 * Append-only record submitted by the mobile conference app while it was
 * offline. The financial collection is created only after an authorized
 * reviewer approves this record.
 */
class OfflineColetaSync extends Model
{
    public const STATUS_PENDING_REVIEW = 'pending_review';

    public const STATUS_APPROVED = 'approved';

    public const STATUS_REJECTED = 'rejected';

    protected $table = 'offline_coleta_syncs';

    protected $fillable = [
        'client_operation_id',
        'institution_id',
        'submitted_by',
        'device_id',
        'captured_at',
        'payload',
        'payload_hash',
        'status',
        'reviewed_by',
        'reviewed_at',
        'review_notes',
        'coleta_id',
    ];

    protected function casts(): array
    {
        return [
            'captured_at' => 'datetime',
            'payload' => 'array',
            'reviewed_at' => 'datetime',
        ];
    }

    protected static function booted(): void
    {
        static::updating(function (self $sync): void {
            $immutable = [
                'client_operation_id',
                'institution_id',
                'submitted_by',
                'device_id',
                'captured_at',
                'payload',
                'payload_hash',
            ];

            if ($sync->isDirty($immutable)) {
                throw new LogicException('O lote offline é imutável após o envio. Envie um novo lote para corrigir os dados.');
            }
        });
    }

    public function submitter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'submitted_by');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function coleta(): BelongsTo
    {
        return $this->belongsTo(ColetaDizimo::class, 'coleta_id');
    }
}
