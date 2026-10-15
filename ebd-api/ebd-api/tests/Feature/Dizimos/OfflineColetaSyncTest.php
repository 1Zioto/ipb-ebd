<?php

namespace Tests\Feature\Dizimos;

use App\Models\ColetaDizimo;
use App\Models\Institution;
use App\Models\Permission;
use App\Models\Person;
use App\Models\Role;
use App\Models\User;
use App\Support\Permissions;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OfflineColetaSyncTest extends TestCase
{
    use RefreshDatabase;

    private Institution $institution;

    private User $deacon;

    private User $council;

    private Person $person;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedPermissions();
        $this->institution = Institution::create([
            'name' => 'IPB Contingência',
            'short_name' => 'IPB Contingência',
            'type' => 'igreja',
            'status' => 'ativa',
        ]);
        $this->deacon = $this->userWithRole('diacono');
        $this->council = $this->userWithRole('conselho');
        $this->person = Person::create([
            'institution_id' => $this->institution->id,
            'full_name' => 'Membro do Lote',
            'is_active' => true,
            'is_tither' => true,
            'envelope_number' => '42',
        ]);
    }

    public function test_lot_is_idempotent_immutable_and_only_opens_collection_after_approval(): void
    {
        $payload = [
            'client_operation_id' => 'dda89e5f-bf64-4f43-9c40-c30fae5f2da1',
            'device_id' => '8f12c4a9-3f70-48d0-9d7d-e12af4d89761',
            'captured_at' => '2026-10-15T13:30:00Z',
            'coleta' => [
                'date' => '2026-10-15',
                'service_meeting' => 'Culto Noturno',
                'description' => 'Registro em contingência',
                'oferta_dinheiro' => 12.50,
            ],
            'entries' => [[
                'person_id' => $this->person->id,
                'amount' => 100.00,
                'contribution_type' => 'dizimo',
                'payment_method' => 'dinheiro',
                'envelope_number' => '42',
                'contribuinte_nome' => 'Membro do Lote',
            ]],
        ];

        $first = $this->actingAs($this->deacon)->postJson('/api/v1/dizimos/offline-syncs', $payload);
        $first->assertCreated()->assertJsonPath('data.status', 'pending_review');
        $syncId = $first->json('data.id');
        $this->assertDatabaseCount('offline_coleta_syncs', 1);
        $this->assertDatabaseCount('coleta_dizimos', 0);

        $second = $this->actingAs($this->deacon)->postJson('/api/v1/dizimos/offline-syncs', $payload);
        $second->assertOk()->assertJsonPath('data.id', $syncId);
        $this->assertDatabaseCount('offline_coleta_syncs', 1);

        $this->actingAs($this->council)
            ->postJson("/api/v1/dizimos/offline-syncs/{$syncId}/approve", ['review_notes' => 'Conferido com os envelopes físicos.'])
            ->assertOk()
            ->assertJsonPath('data.status', 'approved');

        $coleta = ColetaDizimo::firstOrFail();
        $this->assertSame('Aberta', $coleta->status);
        $this->assertNull($coleta->closed_at);
        $this->assertSame(1, $coleta->entry_count);
        $this->assertSame(112.5, (float) $coleta->total_geral);
        $this->assertDatabaseHas('offline_coleta_syncs', [
            'id' => $syncId,
            'status' => 'approved',
            'coleta_id' => $coleta->id,
            'reviewed_by' => $this->council->id,
        ]);
    }

    private function userWithRole(string $roleSlug): User
    {
        $user = User::factory()->create(['institution_id' => $this->institution->id]);
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
