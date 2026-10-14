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
        'code',
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
        'total_dizimos',
        'oferta_dinheiro',
        'oferta_pix',
        'oferta_transferencia',
        'total_ofertas',
        'total_geral',
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
            'total_amount' => 'float',
            'total_dizimos' => 'float',
            'oferta_dinheiro' => 'float',
            'oferta_pix' => 'float',
            'oferta_transferencia' => 'float',
            'total_ofertas' => 'float',
            'total_geral' => 'float',
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

    public function impressoes(): HasMany
    {
        return $this->hasMany(ConferenciaImpressao::class, 'coleta_id')->orderBy('created_at', 'desc');
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
