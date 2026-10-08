<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrcamentoAnualLinha extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'orcamento_anual_linhas';

    protected $fillable = [
        'institution_id',
        'ano',
        'departamento_ou_sociedade',
        'financial_category_id',
        'financial_cost_center_id',
        'descricao',
        'valor_previsto_anual',
        'observacoes',
    ];

    protected function casts(): array
    {
        return [
            'ano' => 'integer',
            'valor_previsto_anual' => 'decimal:2',
        ];
    }

    public function financialCategory(): BelongsTo
    {
        return $this->belongsTo(FinancialCategory::class);
    }

    public function financialCostCenter(): BelongsTo
    {
        return $this->belongsTo(FinancialCostCenter::class);
    }
}
