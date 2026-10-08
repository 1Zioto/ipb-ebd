<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CotaConciliar extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'cotas_conciliares';

    protected $fillable = [
        'institution_id',
        'ano',
        'mes',
        'base_calculo',
        'aliquota_presbiterio_pct',
        'aliquota_supremo_concilio_pct',
        'valor_presbiterio',
        'valor_supremo_concilio',
        'status_presbiterio',
        'status_supremo_concilio',
        'data_pagamento_presbiterio',
        'data_pagamento_sc',
        'comprovante_presbiterio',
        'comprovante_sc',
        'observacoes',
    ];

    protected function casts(): array
    {
        return [
            'ano' => 'integer',
            'mes' => 'integer',
            'base_calculo' => 'decimal:2',
            'aliquota_presbiterio_pct' => 'decimal:2',
            'aliquota_supremo_concilio_pct' => 'decimal:2',
            'valor_presbiterio' => 'decimal:2',
            'valor_supremo_concilio' => 'decimal:2',
            'data_pagamento_presbiterio' => 'date',
            'data_pagamento_sc' => 'date',
        ];
    }
}
