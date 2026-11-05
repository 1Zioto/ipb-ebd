<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChurchEvent extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'church_events';

    protected $fillable = [
        'institution_id',
        'created_by_user_id',
        'title',
        'slug',
        'theme',
        'description',
        'event_type',
        'target_audience',
        'location_name',
        'location_address',
        'location_maps_url',
        'departure_meeting_point',
        'departure_time',
        'starts_at',
        'ends_at',
        'registration_starts_at',
        'registration_ends_at',
        'max_capacity',
        'is_paid',
        'price',
        'pix_key',
        'pix_key_type',
        'pix_receiver_name',
        'instructions',
        'contact_phone',
        'contact_email',
        'require_medical_info',
        'allow_non_members',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
            'registration_starts_at' => 'datetime',
            'registration_ends_at' => 'datetime',
            'is_paid' => 'boolean',
            'price' => 'decimal:2',
            'max_capacity' => 'integer',
            'require_medical_info' => 'boolean',
            'allow_non_members' => 'boolean',
        ];
    }

    public function registrations(): HasMany
    {
        return $this->hasMany(ChurchEventRegistration::class, 'church_event_id');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }
}

