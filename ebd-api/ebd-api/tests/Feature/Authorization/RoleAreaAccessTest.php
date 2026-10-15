<?php

namespace Tests\Feature\Authorization;

use App\Models\ClassRoom;
use App\Models\ClassTeacher;
use App\Models\Institution;
use App\Models\Permission;
use App\Models\Person;
use App\Models\Role;
use App\Models\User;
use App\Support\Permissions;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RoleAreaAccessTest extends TestCase
{
    use RefreshDatabase;

    private Institution $institution;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedPermissions();
        $this->institution = Institution::create([
            'name' => 'IPB Teste',
            'short_name' => 'IPB Teste',
            'type' => 'igreja',
            'status' => 'ativa',
        ]);
    }

    public function test_professor_sees_only_classes_assigned_to_him(): void
    {
        $teacher = Person::create([
            'institution_id' => $this->institution->id,
            'full_name' => 'Professor Vinculado',
            'is_active' => true,
            'can_teach' => true,
        ]);
        $user = $this->userWithRole('professor', $teacher->id);
        $ownClass = ClassRoom::create(['institution_id' => $this->institution->id, 'name' => 'Adultos', 'is_active' => true]);
        $otherClass = ClassRoom::create(['institution_id' => $this->institution->id, 'name' => 'Jovens', 'is_active' => true]);
        ClassTeacher::create(['class_id' => $ownClass->id, 'person_id' => $teacher->id, 'is_active' => true]);

        $this->actingAs($user)
            ->getJson('/api/v1/classes')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $ownClass->id);

        $this->actingAs($user)->getJson("/api/v1/classes/{$otherClass->id}")->assertForbidden();
    }

    public function test_secretary_can_access_roll_and_deacon_cannot(): void
    {
        $secretary = $this->userWithRole('secretario');
        $deacon = $this->userWithRole('diacono');

        $this->actingAs($secretary)->getJson('/api/v1/secretaria/membros')->assertOk();
        $this->actingAs($deacon)->getJson('/api/v1/secretaria/membros')->assertForbidden();
    }

    private function userWithRole(string $roleSlug, ?int $personId = null): User
    {
        $user = User::factory()->create([
            'institution_id' => $this->institution->id,
            'person_id' => $personId,
        ]);
        $user->roles()->attach(Role::where('slug', $roleSlug)->firstOrFail());

        return $user;
    }

    private function seedPermissions(): void
    {
        foreach (Permissions::ALL as $slug => $name) {
            Permission::firstOrCreate(['slug' => $slug], ['name' => $name]);
        }
        foreach (Permissions::ROLES as $slug => [$name, $description]) {
            Role::firstOrCreate(['slug' => $slug], ['name' => $name, 'description' => $description]);
        }
        foreach (Permissions::ROLE_MATRIX as $roleSlug => $permissionSlugs) {
            $role = Role::where('slug', $roleSlug)->firstOrFail();
            $ids = $permissionSlugs === ['*']
                ? Permission::pluck('id')->all()
                : Permission::whereIn('slug', $permissionSlugs)->pluck('id')->all();
            $role->permissions()->sync($ids);
        }
    }
}
