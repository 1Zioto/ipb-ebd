<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            InstitutionSeeder::class,
            RolePermissionSeeder::class,
            SettingSeeder::class,
            AdminUserSeeder::class,
        ]);
    }
}
