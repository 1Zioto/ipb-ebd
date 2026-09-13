<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Person extends Model
{
    use BelongsToInstitution, HasFactory, SoftDeletes;

    protected $table = 'people';

    protected $fillable = [
        'institution_id', 'full_name', 'birth_date', 'is_active', 'can_teach', 'can_superintend', 'notes',
        'is_tither', 'tither_since', 'envelope_number',
    ];

    protected function casts(): array
    {
        return [
            'birth_date' => 'date',
            'tither_since' => 'date',
            'is_active' => 'boolean',
            'can_teach' => 'boolean',
            'can_superintend' => 'boolean',
            'is_tither' => 'boolean',
        ];
    }

    protected $appends = ['age'];

    /** Idade calculada — nunca armazenada. */
    public function getAgeAttribute(): ?int
    {
        return $this->birth_date?->age;
    }

    public function enrollments(): HasMany
    {
        return $this->hasMany(ClassStudent::class);
    }

    public function teachingClasses(): HasMany
    {
        return $this->hasMany(ClassTeacher::class);
    }

    public function tithes(): HasMany
    {
        return $this->hasMany(LancamentoDizimo::class, 'person_id');
    }

    public function titheAlerts(): HasMany
    {
        return $this->hasMany(AlertaDizimo::class, 'person_id');
    }

    public function families(): BelongsToMany
    {
        return $this->belongsToMany(Family::class, 'family_members')
            ->withPivot(['relationship', 'is_head'])->withTimestamps();
    }

    // ----- Scopes úteis -----
    public function scopeActive($q) { return $q->where('is_active', true); }
    public function scopeTeachers($q) { return $q->where('can_teach', true); }
    public function scopeTithers($q) { return $q->where('is_active', true)->where('is_tither', true); }

    public function scopeSearchTither($q, ?string $term)
    {
        if (blank($term)) {
            return $q;
        }
        $term = trim($term);
        return $q->where(function ($sub) use ($term) {
            $sub->where('full_name', 'like', "%{$term}%")
                ->orWhere('envelope_number', 'like', "%{$term}%");
        });
    }

    /** Aniversariantes de hoje (dia/mês), ignorando o ano. */
    public function scopeBirthdayToday($q)
    {
        return $q->whereNotNull('birth_date')
            ->whereRaw('EXTRACT(MONTH FROM birth_date) = EXTRACT(MONTH FROM CURRENT_DATE)')
            ->whereRaw('EXTRACT(DAY FROM birth_date) = EXTRACT(DAY FROM CURRENT_DATE)');
    }
}
