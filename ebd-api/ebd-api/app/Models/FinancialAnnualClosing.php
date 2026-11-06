<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FinancialAnnualClosing extends Model
{
    use HasFactory;

    protected $table = 'financial_annual_closings';

    protected $fillable = [
        'institution_id',
        'year',
        'closing_date',
        'initial_balance',
        'total_revenues',
        'total_expenses',
        'final_balance',
        'surplus_deficit',
        'summary_snapshot',
        'status',
        'conselho_parecer',
        'closed_by_user_id',
        'approved_by_user_id',
        'published_at',
    ];

    protected $casts = [
        'closing_date' => 'date',
        'published_at' => 'datetime',
        'summary_snapshot' => 'array',
        'initial_balance' => 'float',
        'total_revenues' => 'float',
        'total_expenses' => 'float',
        'final_balance' => 'float',
        'surplus_deficit' => 'float',
    ];

    public function institution(): BelongsTo
    {
        return $this->belongsTo(Institution::class);
    }

    public function closedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'closed_by_user_id');
    }

    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by_user_id');
    }
}

