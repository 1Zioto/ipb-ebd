<?php

namespace Database\Seeders;

use App\Models\Permission;
use App\Models\Role;
use App\Support\Permissions;
use Illuminate\Database\Seeder;

class RolePermissionSeeder extends Seeder
{
    public function run(): void
    {
        // Permissões
        foreach (Permissions::ALL as $slug => $name) {
            Permission::firstOrCreate(['slug' => $slug], ['name' => $name]);
        }

        // Papéis
        foreach (Permissions::ROLES as $slug => [$name, $desc]) {
            Role::firstOrCreate(['slug' => $slug], ['name' => $name, 'description' => $desc]);
        }

        // Matriz papel -> permissões
        foreach (Permissions::ROLE_MATRIX as $roleSlug => $perms) {
            $role = Role::where('slug', $roleSlug)->first();
            if (! $role) {
                continue;
            }
            if ($perms === ['*']) {
                $ids = Permission::pluck('id')->all();
            } else {
                $ids = Permission::whereIn('slug', $perms)->pluck('id')->all();
            }
            $role->permissions()->sync($ids);
        }
    }
}
