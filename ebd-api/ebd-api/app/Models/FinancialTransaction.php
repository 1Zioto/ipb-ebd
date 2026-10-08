<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class FinancialTransaction extends Model
{
    use BelongsToInstitution, HasFactory, SoftDeletes;

    protected $table = 'financial_transactions';

    protected $fillable = [
        'institution_id',
        'financial_account_id',
        'financial_category_id',
        'financial_cost_center_id',
        'type',
        'date',
        'competency_date',
        'amount',
        'description',
        'entity_name',
        'document_number',
        'payment_method',
        'status',
        'paid_at',
        'coleta_id',
        'destination_account_id',
        'attachment_url',
        'notes',
        'created_by',
        'updated_by',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'competency_date' => 'date',
            'amount' => 'decimal:2',
            'paid_at' => 'datetime',
        ];
    }

    public function account(): BelongsTo
    {
        return $this->belongsTo(FinancialAccount::class, 'financial_account_id');
    }

    public function destinationAccount(): BelongsTo
    {
        return $this->belongsTo(FinancialAccount::class, 'destination_account_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(FinancialCategory::class, 'financial_category_id');
    }

    public function costCenter(): BelongsTo
    {
        return $this->belongsTo(FinancialCostCenter::class, 'financial_cost_center_id');
    }

    public function coleta(): BelongsTo
    {
        return $this->belongsTo(ColetaDizimo::class, 'coleta_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }
}
