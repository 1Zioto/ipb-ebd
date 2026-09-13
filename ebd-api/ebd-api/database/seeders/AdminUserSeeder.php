<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::firstOrCreate(
            ['username' => 'admin'],
            [
                'name' => 'Administrador',
                'email' => 'admin@ebd.local',
                'password' => Hash::make(env('ADMIN_PASSWORD', 'EbdAdmin@2026')),
                'is_active' => true,
            ]
        );

        $programador = Role::where('slug', 'programador')->first();
        if ($programador) {
            $user->roles()->syncWithoutDetaching([$programador->id]);
        }
    }
}
