<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class ColetaDizimo extends Model
{
    use BelongsToInstitution, HasFactory, SoftDeletes;

    protected $table = 'coletas_dizimos';

    protected $fillable = [
        'institution_id',
        'date',
        'description',
        'service_meeting',
        'status',
        'created_by',
        'opened_at',
        'closed_by',
        'closed_at',
        'verified_by',
        'verified_at',
        'entry_count',
        'total_amount',
        'unidentified_count',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'opened_at' => 'datetime',
            'closed_at' => 'datetime',
            'verified_at' => 'datetime',
            'total_amount' => 'decimal:2',
            'entry_count' => 'integer',
            'unidentified_count' => 'integer',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function closer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'closed_by');
    }

    public function verifier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    public function lancamentos(): HasMany
    {
        return $this->hasMany(LancamentoDizimo::class, 'coleta_id');
    }

    public function isOpen(): bool
    {
        return in_array($this->status, ['Aberta', 'Reaberta para correção'], true);
    }

    public function isClosed(): bool
    {
        return $this->status === 'Fechada';
    }
}
