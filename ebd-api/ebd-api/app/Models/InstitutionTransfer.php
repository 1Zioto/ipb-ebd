<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InstitutionTransfer extends Model
{
    protected $table = 'institution_transfers';

    protected $fillable = [
        'institution_id',
        'old_parent_id',
        'new_parent_id',
        'transferred_by_user_id',
        'reason',
        'transferred_at',
    ];

    protected function casts(): array
    {
        return [
            'transferred_at' => 'datetime',
        ];
    }

    public function institution(): BelongsTo
    {
        return $this->belongsTo(Institution::class, 'institution_id');
    }

    public function oldParent(): BelongsTo
    {
        return $this->belongsTo(Institution::class, 'old_parent_id');
    }

    public function newParent(): BelongsTo
    {
        return $this->belongsTo(Institution::class, 'new_parent_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'transferred_by_user_id');
    }
}
