<?php

namespace Tests\Feature;

use App\Models\Institution;
use App\Models\Person;
use App\Models\SociedadeInterna;
use App\Models\SociedadeMembro;
use App\Models\User;
use Carbon\Carbon;
use Tests\TestCase;

class SociedadesInternasArrolamentoTest extends TestCase
{
    private User $user;
    private Institution $instituicao;
    private SociedadeInterna $ump;

    protected function setUp(): void
    {
        parent::setUp();

        $this->instituicao = Institution::firstOrCreate(
            ['id' => 5],
            ['name' => 'Primeira Igreja Presbiteriana', 'slug' => 'pipb']
        );

        $this->user = User::firstOrCreate(
            ['email' => 'admin.test@ipb.org.br'],
            [
                'name' => 'Pastor Administrador Teste',
                'password' => bcrypt('secret'),
                'institution_id' => $this->instituicao->id,
            ]
        );

        $this->ump = SociedadeInterna::firstOrCreate(
            ['institution_id' => $this->instituicao->id, 'sigla' => 'UMP_TEST'],
            [
                'nome' => 'União de Mocidade Presbiteriana Teste',
                'target_gender' => 'Ambos',
                'min_age' => 18,
                'max_age' => 32,
                'is_active' => true,
                'ano_exercicio' => 2026,
            ]
        );
    }

    /**
     * Teste 1: Filtrar automaticamente pessoas de 18 a 32 anos para a UMP.
     */
    public function test_filtra_automaticamente_pessoas_de_18_a_32_anos_para_ump(): void
    {
        // Cria pessoa jovem (25 anos) e outra com 40 anos
        $jovem = Person::create([
            'institution_id' => $this->instituicao->id,
            'full_name' => 'Jovem UMP Teste ' . uniqid(),
            'gender' => 'Masculino',
            'birth_date' => Carbon::now()->subYears(25)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        $adulto = Person::create([
            'institution_id' => $this->instituicao->id,
            'full_name' => 'Adulto Fora UMP ' . uniqid(),
            'gender' => 'Masculino',
            'birth_date' => Carbon::now()->subYears(40)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        $response = $this->actingAs($this->user)
            ->getJson("/api/sociedades/{$this->ump->id}/candidatos-arrolamento");

        $response->assertOk();
        $candidatos = collect($response->json('data'));

        // O jovem de 25 deve estar na listagem e na faixa
        $candJovem = $candidatos->firstWhere('id', $jovem->id);
        $this->assertNotNull($candJovem);
        $this->assertTrue($candJovem['elegibilidade']['is_eligible']);
        $this->assertEquals('dentro', $candJovem['elegibilidade']['status']);

        // O adulto de 40 não deve entrar no filtro automático de 18-32 anos
        $candAdulto = $candidatos->firstWhere('id', $adulto->id);
        $this->assertNull($candAdulto);

        // Limpa
        $jovem->delete();
        $adulto->delete();
    }

    /**
     * Teste 2: Permitir incluir manualmente pessoa de 35 anos na UMP com aviso sem bloqueio.
     */
    public function test_permite_incluir_manualmente_pessoa_de_35_anos_com_aviso(): void
    {
        $pessoa35 = Person::create([
            'institution_id' => $this->instituicao->id,
            'full_name' => 'Membro 35 Anos ' . uniqid(),
            'gender' => 'Feminino',
            'birth_date' => Carbon::now()->subYears(35)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        $response = $this->actingAs($this->user)
            ->postJson("/api/sociedades/{$this->ump->id}/membros", [
                'person_id' => $pessoa35->id,
                'tipo_socio' => 'efetivo',
                'data_admissao' => now()->toDateString(),
            ]);

        $response->assertCreated();
        $response->assertJsonPath('membro.person_id', $pessoa35->id);
        $this->assertNotNull($response->json('aviso'));
        $this->assertStringContainsString('35 anos', $response->json('aviso'));

        // Limpa
        SociedadeMembro::where('person_id', $pessoa35->id)->delete();
        $pessoa35->delete();
    }

    /**
     * Teste 3: Alterar temporariamente filtro máximo para 35 sem salvar na sociedade.
     */
    public function test_alterar_temporariamente_filtro_maximo_para_35_sem_modificar_sociedade(): void
    {
        $pessoa34 = Person::create([
            'institution_id' => $this->instituicao->id,
            'full_name' => 'Membro 34 Anos ' . uniqid(),
            'gender' => 'Feminino',
            'birth_date' => Carbon::now()->subYears(34)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        // Consulta com filtro temporário max_age = 35
        $response = $this->actingAs($this->user)
            ->getJson("/api/sociedades/{$this->ump->id}/candidatos-arrolamento?max_age=35");

        $response->assertOk();
        $candidatos = collect($response->json('data'));

        // A pessoa de 34 anos agora aparece na busca
        $cand = $candidatos->firstWhere('id', $pessoa34->id);
        $this->assertNotNull($cand);

        // Verifica que o cadastro original da sociedade permanece intocado (max_age = 32)
        $this->ump->refresh();
        $this->assertEquals(32, $this->ump->max_age);

        // Limpa
        $pessoa34->delete();
    }

    /**
     * Teste 4: Preservar sócio que completou 33 anos (nunca desliga automaticamente).
     */
    public function test_preservar_socio_que_completou_33_anos(): void
    {
        $pessoa33 = Person::create([
            'institution_id' => $this->instituicao->id,
            'full_name' => 'Socio Veterano 33 Anos ' . uniqid(),
            'gender' => 'Masculino',
            'birth_date' => Carbon::now()->subYears(33)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        $membro = SociedadeMembro::create([
            'institution_id' => $this->instituicao->id,
            'sociedade_id' => $this->ump->id,
            'person_id' => $pessoa33->id,
            'tipo_socio' => 'efetivo',
            'data_admissao' => Carbon::now()->subYears(3)->toDateString(),
            'status' => 'ativo',
            'created_by' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user)
            ->getJson("/api/sociedades/{$this->ump->id}/membros");

        $response->assertOk();
        $membros = collect($response->json('data'));
        $socioEncontrado = $membros->firstWhere('person_id', $pessoa33->id);

        $this->assertNotNull($socioEncontrado);
        $this->assertEquals('ativo', $socioEncontrado['status']);
        $this->assertEquals('acima_faixa', $socioEncontrado['elegibilidade']['status']);

        // Limpa
        $membro->delete();
        $pessoa33->delete();
    }

    /**
     * Teste 5: Impedir arrolamento duplicado de sócio ativo.
     */
    public function test_impede_arrolamento_duplicado_ativo(): void
    {
        $pessoa = Person::create([
            'institution_id' => $this->instituicao->id,
            'full_name' => 'Membro Unico ' . uniqid(),
            'gender' => 'Feminino',
            'birth_date' => Carbon::now()->subYears(22)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        // Primeiro arrolamento
        $this->actingAs($this->user)
            ->postJson("/api/sociedades/{$this->ump->id}/membros", [
                'person_id' => $pessoa->id,
                'tipo_socio' => 'efetivo',
            ])->assertCreated();

        // Tentativa de segundo arrolamento ativo duplicado
        $response = $this->actingAs($this->user)
            ->postJson("/api/sociedades/{$this->ump->id}/membros", [
                'person_id' => $pessoa->id,
                'tipo_socio' => 'efetivo',
            ]);

        $response->assertStatus(422);
        $this->assertStringContainsString('já possui vínculo ativo', $response->json('message'));

        // Limpa
        SociedadeMembro::where('person_id', $pessoa->id)->delete();
        $pessoa->delete();
    }

    /**
     * Teste 6: Processar seleção em lote de múltiplos membros de forma transacional.
     */
    public function test_processar_arrolamento_em_lote(): void
    {
        $pessoas = [];
        for ($i = 0; $i < 5; $i++) {
            $pessoas[] = Person::create([
                'institution_id' => $this->instituicao->id,
                'full_name' => "Candidato Lote {$i} " . uniqid(),
                'gender' => 'Masculino',
                'birth_date' => Carbon::now()->subYears(20 + $i)->toDateString(),
                'is_active' => true,
                'canonical_status' => 'comungante',
            ]);
        }

        $ids = array_map(fn ($p) => $p->id, $pessoas);

        $response = $this->actingAs($this->user)
            ->postJson("/api/sociedades/{$this->ump->id}/membros/em-lote", [
                'person_ids' => $ids,
                'tipo_socio' => 'efetivo',
            ]);

        $response->assertOk();
        $this->assertEquals(5, $response->json('resumo.novos_arrolados'));

        // Se chamar novamente com os mesmos IDs, deve detectar 5 já arrolados e 0 novos
        $response2 = $this->actingAs($this->user)
            ->postJson("/api/sociedades/{$this->ump->id}/membros/em-lote", [
                'person_ids' => $ids,
                'tipo_socio' => 'efetivo',
            ]);

        $response2->assertOk();
        $this->assertEquals(0, $response2->json('resumo.novos_arrolados'));
        $this->assertEquals(5, $response2->json('resumo.ja_arrolados'));

        // Limpa
        SociedadeMembro::whereIn('person_id', $ids)->delete();
        Person::whereIn('id', $ids)->delete();
    }

    /**
     * Teste 7: Tratar pessoa sem data de nascimento.
     */
    public function test_pessoa_sem_data_nascimento_nao_entra_em_filtro_etario_estrito_mas_pode_ser_arrolada_manualmente(): void
    {
        $pessoaSemNascimento = Person::create([
            'institution_id' => $this->instituicao->id,
            'full_name' => 'Sem Nascimento ' . uniqid(),
            'gender' => 'Feminino',
            'birth_date' => null,
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        // Não deve vir no filtro automático etário (18 a 32 anos)
        $response = $this->actingAs($this->user)
            ->getJson("/api/sociedades/{$this->ump->id}/candidatos-arrolamento");

        $candidatos = collect($response->json('data'));
        $this->assertNull($candidatos->firstWhere('id', $pessoaSemNascimento->id));

        // Mas pela busca por nome ela pode ser localizada
        $responseBusca = $this->actingAs($this->user)
            ->getJson("/api/sociedades/{$this->ump->id}/candidatos-arrolamento?search=" . urlencode($pessoaSemNascimento->full_name));

        $candBusca = collect($responseBusca->json('data'))->firstWhere('id', $pessoaSemNascimento->id);
        $this->assertNotNull($candBusca);
        $this->assertEquals('sem_nascimento', $candBusca['elegibilidade']['status']);

        // E pode ser arrolada manualmente
        $responseArrolar = $this->actingAs($this->user)
            ->postJson("/api/sociedades/{$this->ump->id}/membros", [
                'person_id' => $pessoaSemNascimento->id,
                'tipo_socio' => 'cooperador',
            ]);

        $responseArrolar->assertCreated();

        // Limpa
        SociedadeMembro::where('person_id', $pessoaSemNascimento->id)->delete();
        $pessoaSemNascimento->delete();
    }

    /**
     * Teste 8: Garantir isolamento entre instituições.
     */
    public function test_garantir_isolamento_entre_instituicoes(): void
    {
        $outraInstituicao = Institution::create([
            'name' => 'Outra Igreja Presbiteriana ' . uniqid(),
            'slug' => 'outra-' . uniqid(),
        ]);

        $pessoaOutraIgreja = Person::create([
            'institution_id' => $outraInstituicao->id,
            'full_name' => 'Membro de Outra Igreja ' . uniqid(),
            'gender' => 'Masculino',
            'birth_date' => Carbon::now()->subYears(25)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        // Arrolamento individual deve falhar com 404 (instituição diferente)
        $this->actingAs($this->user)
            ->postJson("/api/sociedades/{$this->ump->id}/membros", [
                'person_id' => $pessoaOutraIgreja->id,
                'tipo_socio' => 'efetivo',
            ])->assertStatus(404);

        // Arrolamento em lote deve rejeitar
        $this->actingAs($this->user)
            ->postJson("/api/sociedades/{$this->ump->id}/membros/em-lote", [
                'person_ids' => [$pessoaOutraIgreja->id],
                'tipo_socio' => 'efetivo',
            ])->assertStatus(422);

        // Limpa
        $pessoaOutraIgreja->delete();
        $outraInstituicao->delete();
    }

    protected function tearDown(): void
    {
        SociedadeMembro::where('sociedade_id', $this->ump->id)->delete();
        $this->ump->delete();
        parent::tearDown();
    }
}
