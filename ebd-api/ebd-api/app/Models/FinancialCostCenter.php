<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class FinancialCostCenter extends Model
{
    use BelongsToInstitution, HasFactory, SoftDeletes;

    protected $table = 'financial_cost_centers';

    protected $fillable = [
        'institution_id',
        'code',
        'name',
        'description',
        'budget_limit',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'budget_limit' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(FinancialTransaction::class, 'financial_cost_center_id');
    }
}
