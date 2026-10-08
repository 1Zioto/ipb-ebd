<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PatrimonioBem extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'patrimonio_bens';

    protected $fillable = [
        'institution_id',
        'numero_tombamento',
        'nome',
        'categoria',
        'localizacao',
        'data_aquisicao',
        'valor_aquisicao',
        'valor_atual',
        'estado_conservacao',
        'status',
        'nota_fiscal',
        'descricao',
        'responsavel_diacono',
    ];

    protected function casts(): array
    {
        return [
            'data_aquisicao' => 'date',
            'valor_aquisicao' => 'decimal:2',
            'valor_atual' => 'decimal:2',
        ];
    }
}
