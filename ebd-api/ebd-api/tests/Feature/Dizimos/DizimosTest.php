<?php

namespace Tests\Feature\Dizimos;

use App\Models\AlertaDizimo;
use App\Models\ColetaDizimo;
use App\Models\ConsolidacaoDizimoMensal;
use App\Models\LancamentoDizimo;
use App\Models\Permission;
use App\Models\Person;
use App\Models\Role;
use App\Models\User;
use App\Services\Dizimos\AlertEngineService;
use App\Support\Permissions;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DizimosTest extends TestCase
{
    use RefreshDatabase;

    protected User $diaconoUser;
    protected User $pastorUser;
    protected Person $titherPerson;

    protected function setUp(): void
    {
        parent::setUp();

        // Seed roles & permissions
        foreach (Permissions::ALL as $slug => $name) {
            Permission::firstOrCreate(['slug' => $slug], ['name' => $name]);
        }
        foreach (Permissions::ROLES as $slug => [$name, $desc]) {
            Role::firstOrCreate(['slug' => $slug], ['name' => $name, 'description' => $desc]);
        }
        foreach (Permissions::ROLE_MATRIX as $roleSlug => $perms) {
            $role = Role::where('slug', $roleSlug)->first();
            if ($role) {
                $ids = $perms === ['*'] ? Permission::pluck('id')->all() : Permission::whereIn('slug', $perms)->pluck('id')->all();
                $role->permissions()->sync($ids);
            }
        }

        // Diácono
        $this->diaconoUser = User::factory()->create(['name' => 'Diácono Carlos']);
        $diaconoRole = Role::where('slug', 'diacono')->first();
        $this->diaconoUser->roles()->attach($diaconoRole);

        // Pastor
        $this->pastorUser = User::factory()->create(['name' => 'Pastor Marcos']);
        $pastorRole = Role::where('slug', 'pastor')->first();
        $this->pastorUser->roles()->attach($pastorRole);

        // Dizimista
        $this->titherPerson = Person::create([
            'full_name' => 'Douglas Zioto',
            'is_tither' => true,
            'envelope_number' => '102',
            'tither_since' => '2025-01-01',
            'is_active' => true,
        ]);
    }

    public function test_diacono_can_open_coleta_and_add_lancamentos(): void
    {
        $response = $this->actingAs($this->diaconoUser)->postJson('/api/v1/dizimos/coletas', [
            'date' => now()->toDateString(),
            'service_meeting' => 'Culto de Domingo',
        ]);

        $response->assertStatus(201);
        $coletaId = $response->json('id');

        // Adicionar lançamento identificado
        $lancRes = $this->actingAs($this->diaconoUser)->postJson("/api/v1/dizimos/coletas/{$coletaId}/lancamentos", [
            'person_id' => $this->titherPerson->id,
            'amount' => 500.00,
            'contribution_type' => 'envelope',
        ]);

        $lancRes->assertStatus(201);
        $this->assertEquals(500.00, $lancRes->json('coleta_summary.total_amount'));

        // Adicionar lançamento não identificado
        $unidentifiedRes = $this->actingAs($this->diaconoUser)->postJson("/api/v1/dizimos/coletas/{$coletaId}/lancamentos", [
            'amount' => 100.00,
            'is_unidentified' => true,
            'notes' => 'Envelope anônimo',
        ]);

        $unidentifiedRes->assertStatus(201);
        $this->assertEquals(600.00, $unidentifiedRes->json('coleta_summary.total_amount'));
    }

    public function test_duplicate_lancamento_warning_and_force(): void
    {
        $coleta = ColetaDizimo::create([
            'date' => now()->toDateString(),
            'service_meeting' => 'Culto da Manhã',
            'status' => 'Aberta',
            'created_by' => $this->diaconoUser->id,
            'opened_at' => now(),
        ]);

        // Primeiro lançamento
        $this->actingAs($this->diaconoUser)->postJson("/api/v1/dizimos/coletas/{$coleta->id}/lancamentos", [
            'person_id' => $this->titherPerson->id,
            'amount' => 300.00,
        ])->assertStatus(201);

        // Tentativa de duplicado sem force -> Retorna 409
        $duplicateRes = $this->actingAs($this->diaconoUser)->postJson("/api/v1/dizimos/coletas/{$coleta->id}/lancamentos", [
            'person_id' => $this->titherPerson->id,
            'amount' => 200.00,
        ]);

        $duplicateRes->assertStatus(409);
        $this->assertTrue($duplicateRes->json('duplicate'));

        // Com force = true -> Sucesso
        $forceRes = $this->actingAs($this->diaconoUser)->postJson("/api/v1/dizimos/coletas/{$coleta->id}/lancamentos", [
            'person_id' => $this->titherPerson->id,
            'amount' => 200.00,
            'force' => true,
        ]);

        $forceRes->assertStatus(201);
        $this->assertEquals(500.00, $forceRes->json('coleta_summary.total_amount'));
    }

    public function test_diacono_cannot_access_individual_member_history(): void
    {
        $response = $this->actingAs($this->diaconoUser)->getJson("/api/v1/dizimos/membros/{$this->titherPerson->id}/historico");
        $response->assertStatus(403);
    }

    public function test_pastor_can_access_individual_member_history(): void
    {
        $response = $this->actingAs($this->pastorUser)->getJson("/api/v1/dizimos/membros/{$this->titherPerson->id}/historico");
        $response->assertStatus(200);
        $response->assertJsonStructure([
            'person' => ['id', 'full_name'],
            'metrics' => ['historical_average', 'recent_average', 'trend'],
            'chart_data',
        ]);
    }

    public function test_alert_engine_triggers_on_two_consecutive_months_drop(): void
    {
        // Criar histórico regular de 3 meses anteriores
        ConsolidacaoDizimoMensal::create(['person_id' => $this->titherPerson->id, 'year' => 2026, 'month' => 1, 'total_amount' => 1000.00, 'contribution_count' => 1]);
        ConsolidacaoDizimoMensal::create(['person_id' => $this->titherPerson->id, 'year' => 2026, 'month' => 2, 'total_amount' => 1050.00, 'contribution_count' => 1]);
        ConsolidacaoDizimoMensal::create(['person_id' => $this->titherPerson->id, 'year' => 2026, 'month' => 3, 'total_amount' => 950.00, 'contribution_count' => 1]);

        // Criar 2 meses consecutivos com queda >= 30% (ex: 350 e 300 contra média de 1000)
        ConsolidacaoDizimoMensal::create(['person_id' => $this->titherPerson->id, 'year' => 2026, 'month' => 4, 'total_amount' => 350.00, 'contribution_count' => 1]);
        ConsolidacaoDizimoMensal::create(['person_id' => $this->titherPerson->id, 'year' => 2026, 'month' => 5, 'total_amount' => 300.00, 'contribution_count' => 1]);

        $engine = new AlertEngineService();
        $result = $engine->runAlertEngine(2026, 5);

        $this->assertEquals(1, $result['alerts_created']);
        $this->assertDatabaseHas('alertas_dizimos', [
            'person_id' => $this->titherPerson->id,
            'alert_type' => 'queda_relevante',
            'status' => 'Novo',
        ]);
    }

    public function test_diaconato_request_has_no_financial_amounts(): void
    {
        // Pastor cria solicitação de acompanhamento para o diaconato
        $reqRes = $this->actingAs($this->pastorUser)->postJson('/api/v1/dizimos/pastoral/solicitar-diaconato', [
            'person_id' => $this->titherPerson->id,
            'pastor_notes' => 'Por favor fazer uma visita de cortesia à família Zioto.',
        ]);

        $reqRes->assertStatus(201);

        // Diácono consulta a lista de solicitações
        $listRes = $this->actingAs($this->diaconoUser)->getJson('/api/v1/dizimos/diaconato/solicitacoes');

        $listRes->assertStatus(200);
        $item = $listRes->json('data.0');
        $this->assertEquals('Douglas Zioto', $item['person']['full_name']);
        $this->assertEquals('Por favor fazer uma visita de cortesia à família Zioto.', $item['pastor_notes']);
        $this->assertArrayNotHasKey('total_amount', $item);
        $this->assertArrayNotHasKey('amount', $item);
    }
}
