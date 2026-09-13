<?php

namespace Tests\Feature;

use App\Models\AttendanceRecord;
use App\Models\AttendanceSession;
use App\Models\AuditLog;
use App\Models\ClassRoom;
use App\Models\EbdEvent;
use App\Models\Permission;
use App\Models\Person;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EbdAdministrationTest extends TestCase
{
    use RefreshDatabase;

    private function programmer(): User
    {
        $permission = Permission::create(['name' => 'Gerir usuários', 'slug' => 'user.manage']);
        Permission::create(['name' => 'Gerir papéis', 'slug' => 'role.manage']);
        Permission::create(['name' => 'Ver auditoria', 'slug' => 'audit.view']);
        Permission::create(['name' => 'Ver chamadas', 'slug' => 'call.view']);
        $role = Role::create(['name' => 'Programador', 'slug' => 'programador']);
        $role->permissions()->attach($permission);
        $user = User::factory()->create();
        $user->roles()->attach($role);
        return $user->load('roles.permissions');
    }

    public function test_programmer_can_list_users_roles_permissions_and_audit(): void
    {
        $user = $this->programmer();
        AuditLog::create(['user_id' => $user->id, 'action' => 'test.action', 'entity_type' => 'person', 'entity_id' => 1, 'created_at' => now()]);
        $this->actingAs($user)->getJson('/api/v1/admin/users')->assertOk()->assertJsonPath('data.0.id', $user->id);
        $this->actingAs($user)->getJson('/api/v1/admin/roles')->assertOk();
        $this->actingAs($user)->getJson('/api/v1/admin/permissions')->assertOk();
        $this->actingAs($user)->getJson('/api/v1/audit/logs?entity=person')->assertOk()->assertJsonPath('data.0.user.id', $user->id);
    }

    public function test_live_dashboard_counts_boolean_attendance_and_materials(): void
    {
        $user = $this->programmer();
        $person = Person::create(['full_name' => 'Aluno Teste', 'is_active' => true]);
        $class = ClassRoom::create(['name' => 'Classe Teste', 'is_active' => true]);
        $event = EbdEvent::create(['event_date' => now()->toDateString(), 'type' => 'regular', 'status' => 'em_andamento']);
        $session = AttendanceSession::create(['ebd_event_id' => $event->id, 'class_id' => $class->id, 'status' => 'em_andamento', 'material_mode' => 'individual']);
        AttendanceRecord::create(['attendance_session_id' => $session->id, 'person_id' => $person->id, 'person_name_snapshot' => $person->full_name, 'present' => true, 'brought_bible' => true, 'brought_magazine' => false]);
        $this->actingAs($user)->getJson("/api/v1/dashboard/superintendent-live/{$event->id}")
            ->assertOk()->assertJsonPath('live_summary.present', 1)->assertJsonPath('live_summary.bibles', 1);
    }
}
