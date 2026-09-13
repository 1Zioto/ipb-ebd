<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Family extends Model
{
    use BelongsToInstitution, SoftDeletes;

    protected $fillable = [
        'institution_id', 'name', 'phone', 'whatsapp', 'email', 'zipcode', 'street',
        'number', 'complement', 'district', 'city', 'state', 'notes', 'is_active',
    ];

    protected function casts(): array
    {
        return ['is_active' => 'boolean'];
    }

    public function members(): BelongsToMany
    {
        return $this->belongsToMany(Person::class, 'family_members')
            ->withPivot(['relationship', 'is_head'])->withTimestamps();
    }
}
