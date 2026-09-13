<?php

namespace App\Policies;

use App\Models\Family;
use App\Models\User;

class FamilyPolicy
{
    public function viewAny(User $user): bool { return $user->hasPermission('family.view'); }
    public function view(User $user, Family $family): bool { return $user->hasPermission('family.view') && $this->sameInstitution($user, $family); }
    public function create(User $user): bool { return $user->hasPermission('family.manage'); }
    public function update(User $user, Family $family): bool { return $user->hasPermission('family.manage') && $this->sameInstitution($user, $family); }
    public function delete(User $user, Family $family): bool { return $user->hasPermission('family.manage') && $this->sameInstitution($user, $family); }

    private function sameInstitution(User $user, Family $family): bool
    {
        return $user->hasGlobalInstitutionAccess() || (int) $user->institution_id === (int) $family->institution_id;
    }
}
