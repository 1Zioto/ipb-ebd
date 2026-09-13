<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = [
        'person_id', 'institution_id', 'name', 'username', 'email', 'password', 'is_active', 'last_login_at',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'is_active' => 'boolean',
            'last_login_at' => 'datetime',
        ];
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class);
    }

    public function institution(): BelongsTo
    {
        return $this->belongsTo(Institution::class, 'institution_id');
    }

    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class, 'user_roles');
    }

    /** Todas as permissões (slugs) do usuário, derivadas dos papéis. */
    public function permissionSlugs(): array
    {
        return $this->roles()
            ->with('permissions:id,slug')
            ->get()
            ->flatMap(fn ($role) => $role->permissions->pluck('slug'))
            ->unique()
            ->values()
            ->all();
    }

    public function hasRole(string $slug): bool
    {
        return $this->roles->contains('slug', $slug);
    }

    public function isProgrammer(): bool
    {
        return $this->hasRole('programador');
    }

    /** Programador sem instituição é o único perfil com escopo institucional global. */
    public function hasGlobalInstitutionAccess(): bool
    {
        return $this->isProgrammer() && ! $this->institution_id;
    }

    public function hasPermission(string $slug): bool
    {
        // Regra 29: Dados financeiros individuais exigem concessão explícita do módulo pastoral
        if ($slug === 'dizimos.historico_individual.view') {
            return in_array($slug, $this->permissionSlugs(), true) || $this->hasRole('pastor');
        }

        // Programador tem acesso técnico total.
        if ($this->isProgrammer()) {
            return true;
        }
        return in_array($slug, $this->permissionSlugs(), true);
    }

    /** Verifica se o usuário tem acesso à instituição alvo (igual à dele ou descendente). */
    public function canAccessInstitution(int $targetInstitutionId): bool
    {
        if ($this->hasGlobalInstitutionAccess()) {
            return true;
        }
        if (! $this->institution_id) {
            return false;
        }
        if ($this->institution_id === $targetInstitutionId) {
            return true;
        }

        /** @var \App\Services\InstitutionService $service */
        $service = app(\App\Services\InstitutionService::class);
        $allowedIds = $service->getDescendantIds($this->institution_id, true);

        return in_array($targetInstitutionId, $allowedIds, true);
    }

    /** IDs das classes às quais o usuário está vinculado como professor (via pessoa). */
    public function teachingClassIds(): array
    {
        if (! $this->person_id) {
            return [];
        }
        return ClassTeacher::query()
            ->where('person_id', $this->person_id)
            ->where('is_active', true)
            ->pluck('class_id')
            ->all();
    }
}
