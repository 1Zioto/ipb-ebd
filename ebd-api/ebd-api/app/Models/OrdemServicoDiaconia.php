<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrdemServicoDiaconia extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'ordens_servico_diaconia';

    protected $fillable = [
        'institution_id',
        'numero_os',
        'titulo',
        'descricao',
        'tipo_servico',
        'localizacao',
        'prioridade',
        'status',
        'solicitante',
        'diacono_responsavel',
        'data_solicitacao',
        'data_previsao',
        'data_conclusao',
        'custo_estimado',
        'custo_real',
        'observacoes',
    ];

    protected function casts(): array
    {
        return [
            'data_solicitacao' => 'date',
            'data_previsao' => 'date',
            'data_conclusao' => 'date',
            'custo_estimado' => 'decimal:2',
            'custo_real' => 'decimal:2',
        ];
    }
}
