<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EscalaDiacono extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'escalas_diaconos';

    protected $fillable = [
        'institution_id',
        'data_culto',
        'periodo',
        'recepcao_porta',
        'recolhimento_ofertas',
        'apoio_pulpito_ceia',
        'seguranca_patio',
        'diacono_coordenador',
        'observacoes',
    ];

    protected function casts(): array
    {
        return [
            'data_culto' => 'date',
        ];
    }
}
