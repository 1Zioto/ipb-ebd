<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LancamentoDizimo extends Model
{
    use HasFactory;

    protected $table = 'lancamentos_dizimos';

    protected $fillable = [
        'coleta_id',
        'person_id',
        'amount',
        'contribution_type',
        'is_unidentified',
        'notes',
        'created_by',
        'updated_by',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'is_unidentified' => 'boolean',
        ];
    }

    public function coleta(): BelongsTo
    {
        return $this->belongsTo(ColetaDizimo::class, 'coleta_id');
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
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
