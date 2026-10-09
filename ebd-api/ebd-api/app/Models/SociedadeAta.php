<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SociedadeAta extends Model
{
    use HasFactory;

    protected $table = 'sociedade_atas';

    protected $fillable = [
        'sociedade_id',
        'numero_ata',
        'titulo',
        'tipo_reuniao',
        'data_reuniao',
        'horario',
        'local',
        'presidente_id',
        'secretario_id',
        'pauta',
        'conteudo',
        'presentes_count',
        'status',
        'visto_conselho_data',
        'visto_conselho_relator',
    ];

    protected $casts = [
        'data_reuniao' => 'date',
        'visto_conselho_data' => 'date',
        'presentes_count' => 'integer',
    ];

    public function sociedade(): BelongsTo
    {
        return $this->belongsTo(SociedadeInterna::class, 'sociedade_id');
    }

    public function presidente(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'presidente_id');
    }

    public function secretario(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'secretario_id');
    }
}
