<?php

use App\Models\Permission;
use App\Models\Role;
use App\Support\Permissions;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * Make the new role areas available on existing installations as well as
     * fresh installations. syncWithoutDetaching preserves any local grants.
     */
    public function up(): void
    {
        foreach (Permissions::ALL as $slug => $name) {
            Permission::updateOrCreate(['slug' => $slug], ['name' => $name]);
        }

        foreach (Permissions::ROLES as $slug => [$name, $description]) {
            Role::updateOrCreate(['slug' => $slug], ['name' => $name, 'description' => $description]);
        }

        foreach (Permissions::ROLE_MATRIX as $roleSlug => $permissionSlugs) {
            $role = Role::where('slug', $roleSlug)->firstOrFail();
            $permissionIds = $permissionSlugs === ['*']
                ? Permission::pluck('id')->all()
                : Permission::whereIn('slug', $permissionSlugs)->pluck('id')->all();

            $role->permissions()->syncWithoutDetaching($permissionIds);
        }
    }

    public function down(): void
    {
        // Role grants are historical authorization data; do not remove them
        // during rollback because installations may have added local grants.
    }
};
