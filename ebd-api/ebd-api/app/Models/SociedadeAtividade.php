<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SociedadeAtividade extends Model
{
    use HasFactory;

    protected $table = 'sociedade_atividades';

    protected $fillable = [
        'sociedade_id',
        'titulo',
        'data',
        'horario',
        'tipo',
        'local',
        'descricao',
    ];

    protected function casts(): array
    {
        return [
            'data' => 'date',
        ];
    }

    public function sociedade(): BelongsTo
    {
        return $this->belongsTo(SociedadeInterna::class, 'sociedade_id');
    }
}
