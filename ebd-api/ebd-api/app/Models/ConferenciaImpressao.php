<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConferenciaImpressao extends Model
{
    protected $table = 'conferencia_impressoes';
    public $timestamps = false;

    protected $fillable = [
        'coleta_id',
        'via',
        'tipo',
        'status',
        'user_id',
        'device_info',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }

    public function coleta(): BelongsTo
    {
        return $this->belongsTo(ColetaDizimo::class, 'coleta_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
