<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChurchMemberApplication extends Model
{
    use HasFactory;

    protected $table = 'church_member_applications';

    protected $fillable = [
        'institution_id',
        'full_name',
        'birth_date',
        'gender',
        'marital_status',
        'cpf',
        'rg',
        'email',
        'phone',
        'address',
        'address_number',
        'address_complement',
        'neighborhood',
        'city',
        'state',
        'postal_code',
        'profession',
        'education',
        'father_name',
        'mother_name',
        'spouse_name',
        'is_communicant',
        'ecclesiastical_condition',
        'origin_church',
        'reception_mode',
        'baptism_date',
        'baptism_church',
        'profession_of_faith_date',
        'status',
        'notes',
        'reviewed_by_user_id',
        'reviewed_at',
        'rejection_reason',
        'approved_person_id',
    ];

    protected $casts = [
        'birth_date' => 'date',
        'baptism_date' => 'date',
        'profession_of_faith_date' => 'date',
        'reviewed_at' => 'datetime',
        'is_communicant' => 'boolean',
    ];

    public function institution(): BelongsTo
    {
        return $this->belongsTo(Institution::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by_user_id');
    }

    public function approvedPerson(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'approved_person_id');
    }
}

