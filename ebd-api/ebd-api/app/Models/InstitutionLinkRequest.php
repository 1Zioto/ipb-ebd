<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InstitutionLinkRequest extends Model
{
    use HasFactory;

    protected $table = 'institution_link_requests';

    protected $fillable = [
        'requester_institution_id',
        'target_institution_id',
        'type',
        'status',
        'requested_by_user_id',
        'actioned_by_user_id',
        'reason',
        'action_notes',
        'actioned_at',
    ];

    protected function casts(): array
    {
        return [
            'actioned_at' => 'datetime',
        ];
    }

    public function requesterInstitution(): BelongsTo
    {
        return $this->belongsTo(Institution::class, 'requester_institution_id');
    }

    public function targetInstitution(): BelongsTo
    {
        return $this->belongsTo(Institution::class, 'target_institution_id');
    }

    public function requestedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by_user_id');
    }

    public function actionedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actioned_by_user_id');
    }
}
