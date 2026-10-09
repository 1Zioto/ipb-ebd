<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SociedadeMembro extends Model
{
    use HasFactory;

    protected $table = 'sociedade_membros';

    protected $fillable = [
        'sociedade_id',
        'person_id',
        'tipo_socio',
        'data_admissao',
        'status',
        'cargo_atual',
        'observacoes',
    ];

    protected $casts = [
        'data_admissao' => 'date',
    ];

    public function sociedade(): BelongsTo
    {
        return $this->belongsTo(SociedadeInterna::class, 'sociedade_id');
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
    }
}
