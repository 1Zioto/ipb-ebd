<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Institution extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'institutions';

    protected $fillable = [
        'name',
        'short_name',
        'type',
        'code',
        'cnpj',
        'foundation_date',
        'organization_date',
        'status',
        'parent_institution_id',
        'zipcode',
        'street',
        'number',
        'complement',
        'district',
        'city',
        'state',
        'country',
        'phone',
        'whatsapp',
        'email',
        'website',
        'social_media',
        'logo',
        'photo',
        'fantasy_name',
        'internal_code',
        'denominational_code',
        'share_financials_with_parent',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'foundation_date' => 'date',
            'organization_date' => 'date',
            'social_media' => 'array',
            'share_financials_with_parent' => 'boolean',
        ];
    }

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($institution) {
            if (empty($institution->code)) {
                $code = 'INST-' . strtoupper(\Illuminate\Support\Str::random(6));
                while (static::where('code', $code)->exists()) {
                    $code = 'INST-' . strtoupper(\Illuminate\Support\Str::random(6));
                }
                $institution->code = $code;
            }
        });
    }

    // Relationships
    public function parent(): BelongsTo
    {
        return $this->belongsTo(Institution::class, 'parent_institution_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(Institution::class, 'parent_institution_id');
    }

    public function sentLinkRequests(): HasMany
    {
        return $this->hasMany(InstitutionLinkRequest::class, 'requester_institution_id');
    }

    public function receivedLinkRequests(): HasMany
    {
        return $this->hasMany(InstitutionLinkRequest::class, 'target_institution_id');
    }

    public function people(): HasMany
    {
        return $this->hasMany(Person::class, 'institution_id');
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class, 'institution_id');
    }

    public function classes(): HasMany
    {
        return $this->hasMany(ClassRoom::class, 'institution_id');
    }

    public function transfers(): HasMany
    {
        return $this->hasMany(InstitutionTransfer::class, 'institution_id');
    }

    public function histories(): HasMany
    {
        return $this->hasMany(InstitutionHistory::class, 'institution_id');
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'ativa');
    }

    public function scopeOfType($query, string $type)
    {
        return $query->where('type', $type);
    }
}
