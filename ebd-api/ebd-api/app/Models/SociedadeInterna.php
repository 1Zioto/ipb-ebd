<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SociedadeInterna extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'sociedades_internas';

    protected $fillable = [
        'institution_id',
        'sigla',
        'nome',
        'lema',
        'faixa_etaria',
        'financial_cost_center_id',
        'ano_exercicio',
    ];

    public function diretorias(): HasMany
    {
        return $this->hasMany(SociedadeDiretoria::class, 'sociedade_id');
    }

    public function atividades(): HasMany
    {
        return $this->hasMany(SociedadeAtividade::class, 'sociedade_id');
    }

    public function costCenter(): BelongsTo
    {
        return $this->belongsTo(FinancialCostCenter::class, 'financial_cost_center_id');
    }
}
