<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConsolidacaoDizimoMensal extends Model
{
    use HasFactory;

    protected $table = 'consolidacao_dizimos_mensal';

    protected $fillable = [
        'person_id',
        'year',
        'month',
        'total_amount',
        'contribution_count',
    ];

    protected function casts(): array
    {
        return [
            'year' => 'integer',
            'month' => 'integer',
            'total_amount' => 'decimal:2',
            'contribution_count' => 'integer',
        ];
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
    }
}
