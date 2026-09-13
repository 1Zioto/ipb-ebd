<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AcompanhamentoDizimo extends Model
{
    use HasFactory;

    protected $table = 'acompanhamento_dizimos';

    protected $fillable = [
        'alerta_id',
        'person_id',
        'responsible_id',
        'date',
        'type',
        'notes',
        'next_action',
        'review_date',
        'status',
        'conclusion',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'review_date' => 'date',
        ];
    }

    public function alerta(): BelongsTo
    {
        return $this->belongsTo(AlertaDizimo::class, 'alerta_id');
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
    }

    public function responsible(): BelongsTo
    {
        return $this->belongsTo(User::class, 'responsible_id');
    }
}
