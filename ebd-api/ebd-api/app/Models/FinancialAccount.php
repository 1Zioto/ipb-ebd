<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class FinancialAccount extends Model
{
    use BelongsToInstitution, HasFactory, SoftDeletes;

    protected $table = 'financial_accounts';

    protected $fillable = [
        'institution_id',
        'name',
        'account_type',
        'bank_name',
        'agency',
        'account_number',
        'initial_balance',
        'current_balance',
        'is_active',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'initial_balance' => 'decimal:2',
            'current_balance' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(FinancialTransaction::class, 'financial_account_id');
    }

    /**
     * Recalcula o saldo da conta com base no saldo inicial e transações confirmadas/pagas.
     */
    public function recalculateBalance(): float
    {
        $incomes = (float) $this->transactions()
            ->where('status', 'pago')
            ->where(function ($q) {
                $q->where('type', 'receita')
                  ->orWhere(function ($sub) {
                      $sub->where('type', 'transferencia')
                          ->where('destination_account_id', $this->id);
                  });
            })
            ->sum('amount');

        $expenses = (float) $this->transactions()
            ->where('status', 'pago')
            ->where(function ($q) {
                $q->where('type', 'despesa')
                  ->orWhere(function ($sub) {
                      $sub->where('type', 'transferencia')
                          ->where('financial_account_id', $this->id);
                  });
            })
            ->sum('amount');

        $newBalance = round((float) $this->initial_balance + $incomes - $expenses, 2);
        $this->update(['current_balance' => $newBalance]);

        return $newBalance;
    }
}
