<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FinancialMonthClosing extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'financial_month_closings';

    protected $fillable = [
        'institution_id',
        'year',
        'month',
        'status',
        'opening_balance',
        'total_income',
        'total_expense',
        'closing_balance',
        'closed_by',
        'closed_at',
        'accounting_notes',
    ];

    protected function casts(): array
    {
        return [
            'year' => 'integer',
            'month' => 'integer',
            'opening_balance' => 'decimal:2',
            'total_income' => 'decimal:2',
            'total_expense' => 'decimal:2',
            'closing_balance' => 'decimal:2',
            'closed_at' => 'datetime',
        ];
    }

    public function closer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'closed_by');
    }
}
