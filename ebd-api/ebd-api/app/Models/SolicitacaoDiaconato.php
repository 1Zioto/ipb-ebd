<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SolicitacaoDiaconato extends Model
{
    use HasFactory;

    protected $table = 'solicitacoes_diaconato';

    protected $fillable = [
        'person_id',
        'pastor_id',
        'diacono_id',
        'pastor_notes',
        'status',
    ];

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
    }

    public function pastor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'pastor_id');
    }

    public function diacono(): BelongsTo
    {
        return $this->belongsTo(User::class, 'diacono_id');
    }
}
