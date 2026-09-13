<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AlertaDizimo extends Model
{
    use HasFactory;

    protected $table = 'alertas_dizimos';

    protected $fillable = [
        'person_id',
        'alert_type',
        'start_date',
        'detection_date',
        'variation_percentage',
        'reference_calculation',
        'status',
        'pastor_id',
        'notes',
        'resolved_at',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'detection_date' => 'date',
            'variation_percentage' => 'decimal:2',
            'reference_calculation' => 'array',
            'resolved_at' => 'datetime',
        ];
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
    }

    public function pastor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'pastor_id');
    }

    public function acompanhamentos(): HasMany
    {
        return $this->hasMany(AcompanhamentoDizimo::class, 'alerta_id');
    }
}
