<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChurchEventRegistration extends Model
{
    use HasFactory;

    protected $table = 'church_event_registrations';

    protected $fillable = [
        'church_event_id',
        'person_id',
        'registration_code',
        'full_name',
        'phone',
        'email',
        'cpf',
        'birth_date',
        'gender',
        'is_member',
        'church_name',
        'is_minor',
        'guardian_name',
        'guardian_phone',
        'dietary_restrictions',
        'medical_notes',
        'emergency_contact_name',
        'emergency_contact_phone',
        'payment_status',
        'payment_amount',
        'payment_proof_path',
        'payment_notes',
        'checked_in',
        'checked_in_at',
        'status',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'birth_date' => 'date',
            'is_member' => 'boolean',
            'is_minor' => 'boolean',
            'payment_amount' => 'decimal:2',
            'checked_in' => 'boolean',
            'checked_in_at' => 'datetime',
        ];
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(ChurchEvent::class, 'church_event_id');
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
    }
}

