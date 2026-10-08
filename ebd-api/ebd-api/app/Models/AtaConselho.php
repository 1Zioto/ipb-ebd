<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AtaConselho extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'atas_conselho';

    protected $fillable = [
        'institution_id',
        'numero_ata',
        'tipo',
        'data_reuniao',
        'horario',
        'local',
        'pastor_presidente',
        'secretario_conselho',
        'presbiters_presentes',
        'abertura',
        'pauta',
        'deliberacoes',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'data_reuniao' => 'date',
            'presbiters_presentes' => 'array',
        ];
    }
}
