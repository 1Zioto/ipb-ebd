<?php

namespace Tests\Feature;

use App\Models\Institution;
use App\Models\InstitutionLinkRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class InstitutionLinkTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
    }

    public function test_institution_gets_auto_generated_code_on_creation(): void
    {
        $user = User::factory()->create(['is_programmer' => true]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/institutions', [
            'name' => 'Igreja Teste Código',
            'short_name' => 'IP Código',
            'type' => 'igreja',
            'status' => 'ativa',
        ]);

        $response->assertStatus(201);
        $this->assertNotEmpty($response->json('data.code'));
        $this->assertStringStartsWith('INST-', $response->json('data.code'));
    }

    public function test_can_lookup_institution_by_code(): void
    {
        $programmer = User::factory()->create(['is_programmer' => true]);
        $inst = Institution::create([
            'name' => 'Presbitério Teste Lookup',
            'short_name' => 'Presb Lookup',
            'type' => 'presbiterio',
            'status' => 'ativa',
            'code' => 'INST-LKPTST',
        ]);

        $response = $this->actingAs($programmer, 'sanctum')->getJson('/api/v1/institutions/by-code/INST-LKPTST');
        $response->assertStatus(200);
        $response->assertJsonPath('data.name', 'Presbitério Teste Lookup');
    }

    public function test_link_request_flow_superior_accept(): void
    {
        $programmer = User::factory()->create(['is_programmer' => true]);

        $presbiterio = Institution::create([
            'name' => 'Presbitério Central Teste',
            'short_name' => 'Presb Central',
            'type' => 'presbiterio',
            'status' => 'ativa',
            'code' => 'INST-PRSB01',
        ]);

        $igreja = Institution::create([
            'name' => 'Igreja Local Teste',
            'short_name' => 'IP Local',
            'type' => 'igreja',
            'status' => 'ativa',
            'code' => 'INST-IGRJ01',
            'parent_institution_id' => null,
        ]);

        $userIgreja = User::factory()->create([
            'institution_id' => $igreja->id,
            'is_programmer' => false,
        ]);

        $userPresbiterio = User::factory()->create([
            'institution_id' => $presbiterio->id,
            'is_programmer' => false,
        ]);

        // 1. Igreja envia solicitação de vinculo_superior com o código do Presbitério
        $responseSend = $this->actingAs($userIgreja, 'sanctum')->postJson('/api/v1/institutions/link-requests', [
            'requester_institution_id' => $igreja->id,
            'target_code' => 'INST-PRSB01',
            'type' => 'vinculo_superior',
            'reason' => 'Queremos vincular esta igreja ao Presbitério Central.',
        ]);

        $responseSend->assertStatus(201);
        $reqId = $responseSend->json('data.id');

        // 2. Presbitério verifica solicitações recebidas
        $responseList = $this->actingAs($userPresbiterio, 'sanctum')->getJson("/api/v1/institutions/link-requests/list?institution_id={$presbiterio->id}");
        $responseList->assertStatus(200);
        $this->assertCount(1, $responseList->json('received'));
        $this->assertEquals($reqId, $responseList->json('received.0.id'));

        // 3. Presbitério Aceita a solicitação
        $responseAccept = $this->actingAs($userPresbiterio, 'sanctum')->postJson("/api/v1/institutions/link-requests/{$reqId}/accept", [
            'action_notes' => 'Aprovado em reunião do Presbitério.',
        ]);

        $responseAccept->assertStatus(200);
        $this->assertEquals('aceita', $responseAccept->json('data.status'));

        // Verificação no banco: Igreja agora tem parent_institution_id = Presbitério
        $this->assertEquals($presbiterio->id, $igreja->fresh()->parent_institution_id);
    }

    public function test_unlink_request_flow_accept(): void
    {
        $presbiterio = Institution::create([
            'name' => 'Presbitério Desvínculo Teste',
            'short_name' => 'Presb Desv',
            'type' => 'presbiterio',
            'status' => 'ativa',
            'code' => 'INST-PRSB02',
        ]);

        $igreja = Institution::create([
            'name' => 'Igreja Desvínculo Teste',
            'short_name' => 'IP Desv',
            'type' => 'igreja',
            'status' => 'ativa',
            'code' => 'INST-IGRJ02',
            'parent_institution_id' => $presbiterio->id,
        ]);

        $userIgreja = User::factory()->create([
            'institution_id' => $igreja->id,
        ]);

        $userPresbiterio = User::factory()->create([
            'institution_id' => $presbiterio->id,
        ]);

        // Solicitação de desvínculo iniciada pela igreja
        $responseSend = $this->actingAs($userIgreja, 'sanctum')->postJson('/api/v1/institutions/link-requests', [
            'requester_institution_id' => $igreja->id,
            'target_code' => 'INST-PRSB02',
            'type' => 'desvinculo',
            'reason' => 'Mudança de presbitério.',
        ]);

        $responseSend->assertStatus(201);
        $reqId = $responseSend->json('data.id');

        // Presbitério aceita o desvínculo
        $responseAccept = $this->actingAs($userPresbiterio, 'sanctum')->postJson("/api/v1/institutions/link-requests/{$reqId}/accept");
        $responseAccept->assertStatus(200);

        // Vínculo removido
        $this->assertNull($igreja->fresh()->parent_institution_id);
    }

    public function test_register_church_from_login_screen(): void
    {
        $response = $this->postJson('/api/v1/auth/register-church', [
            'church_name' => 'Igreja Presbiteriana em Vila Nova',
            'short_name' => 'IP Vila Nova',
            'type' => 'igreja',
            'city' => 'Cariacica',
            'state' => 'ES',
            'admin_name' => 'Admin Igreja Teste',
            'admin_username' => 'admin_vilanova',
            'admin_email' => 'admin@ipvilanova.org',
            'password' => 'senha123456',
        ]);

        $response->assertStatus(201);
        $this->assertNotEmpty($response->json('token'));
        $this->assertNotEmpty($response->json('institution.code'));
        $this->assertEquals('Igreja Presbiteriana em Vila Nova', $response->json('institution.name'));

        // Verifica no banco de dados se a instituição e usuário foram salvos corretamente
        $this->assertDatabaseHas('institutions', [
            'name' => 'Igreja Presbiteriana em Vila Nova',
            'short_name' => 'IP Vila Nova',
        ]);

        $this->assertDatabaseHas('users', [
            'username' => 'admin_vilanova',
            'name' => 'Admin Igreja Teste',
        ]);
    }
}
