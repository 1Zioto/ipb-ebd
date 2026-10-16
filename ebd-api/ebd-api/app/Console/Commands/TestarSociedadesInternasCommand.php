<?php

namespace App\Console\Commands;

use App\Models\Institution;
use App\Models\Person;
use App\Models\SociedadeInterna;
use App\Models\SociedadeMembro;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\SociedadesController;
use Illuminate\Support\Facades\DB;

class TestarSociedadesInternasCommand extends Command
{
    protected $signature = 'test:sociedades-internas';
    protected $description = 'Executa a suíte de testes obrigatórios do módulo de Sociedades Internas e Arrolamento IPB';

    public function handle(): int
    {
        $this->info('===============================================================');
        $this->info('🧪 SUÍTE DE TESTES OBRIGATÓRIOS — SOCIEDADES INTERNAS DA IPB');
        $this->info('===============================================================');

        $instituicao = Institution::firstOrCreate(
            ['id' => 5],
            ['name' => 'Primeira Igreja Presbiteriana', 'slug' => 'pipb']
        );

        $user = User::first() ?? User::create([
            'username' => 'admin_test',
            'email' => 'admin.test@ipb.org.br',
            'name' => 'Pastor Administrador Teste',
            'password' => bcrypt('secret'),
            'institution_id' => $instituicao->id,
        ]);

        $sociedade = SociedadeInterna::firstOrCreate(
            ['institution_id' => $instituicao->id, 'sigla' => 'UMP_AUTOMATED_TEST'],
            [
                'nome' => 'União de Mocidade Presbiteriana Teste',
                'target_gender' => 'Ambos',
                'min_age' => 18,
                'max_age' => 32,
                'is_active' => true,
                'ano_exercicio' => 2026,
            ]
        );

        $controller = app(SociedadesController::class);
        $passed = 0;
        $total = 10;

        // -------------------------------------------------------------
        // TESTE 1: Filtrar automaticamente pessoas de 18 a 32 anos para a UMP
        // -------------------------------------------------------------
        $this->line("\n[1/10] Testando: Filtrar automaticamente pessoas de 18 a 32 anos para a UMP...");
        $p18 = Person::create([
            'institution_id' => $instituicao->id,
            'full_name' => 'Jovem 22 Anos ' . uniqid(),
            'gender' => 'Masculino',
            'birth_date' => Carbon::now()->subYears(22)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);
        $p40 = Person::create([
            'institution_id' => $instituicao->id,
            'full_name' => 'Adulto 40 Anos ' . uniqid(),
            'gender' => 'Masculino',
            'birth_date' => Carbon::now()->subYears(40)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        $req = Request::create("/api/sociedades/{$sociedade->id}/candidatos-arrolamento", 'GET');
        $req->setUserResolver(fn () => $user);
        $res = $controller->candidatosArrolamento($req, $sociedade);
        $dados = collect($res->getData(true)['data']);

        $achou22 = $dados->firstWhere('id', $p18->id);
        $achou40 = $dados->firstWhere('id', $p40->id);

        if ($achou22 && $achou22['elegibilidade']['is_eligible'] && !$achou40) {
            $this->info("  ✅ APROVADO: Jovem de 22 anos incluído na faixa e adulto de 40 anos omitido pelo filtro automático.");
            $passed++;
        } else {
            $this->error("  ❌ FALHOU: Falha no filtro automático de 18 a 32 anos.");
        }
        $p18->delete();
        $p40->delete();

        // -------------------------------------------------------------
        // TESTE 2: Permitir incluir manualmente pessoa de 35 anos na UMP
        // -------------------------------------------------------------
        $this->line("\n[2/10] Testando: Permitir inclusão manual de pessoa com 35 anos na UMP...");
        $p35 = Person::create([
            'institution_id' => $instituicao->id,
            'full_name' => 'Adulto 35 Anos ' . uniqid(),
            'gender' => 'Feminino',
            'birth_date' => Carbon::now()->subYears(35)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        $req = Request::create("/api/sociedades/{$sociedade->id}/membros", 'POST', [
            'person_id' => $p35->id,
            'tipo_socio' => 'efetivo',
            'data_admissao' => now()->toDateString(),
        ]);
        $req->setUserResolver(fn () => $user);
        $res = $controller->storeMembro($req, $sociedade);
        $status = $res->getStatusCode();
        $payload = $res->getData(true);

        if ($status === 201 && !empty($payload['aviso'])) {
            $this->info("  ✅ APROVADO: Pessoa de 35 anos arrolada com sucesso com aviso de elegibilidade informativa.");
            $passed++;
        } else {
            $this->error("  ❌ FALHOU: Inclusão manual bloqueada ou sem aviso.");
        }
        SociedadeMembro::where('person_id', $p35->id)->delete();
        $p35->delete();

        // -------------------------------------------------------------
        // TESTE 3: Alterar temporariamente filtro máximo para 35 sem salvar na sociedade
        // -------------------------------------------------------------
        $this->line("\n[3/10] Testando: Alterar temporariamente filtro máximo para 35 anos sem modificar a sociedade...");
        $p34 = Person::create([
            'institution_id' => $instituicao->id,
            'full_name' => 'Jovem Adulto 34 Anos ' . uniqid(),
            'gender' => 'Masculino',
            'birth_date' => Carbon::now()->subYears(34)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        $req = Request::create("/api/sociedades/{$sociedade->id}/candidatos-arrolamento", 'GET', [
            'max_age' => 35,
        ]);
        $req->setUserResolver(fn () => $user);
        $res = $controller->candidatosArrolamento($req, $sociedade);
        $dados = collect($res->getData(true)['data']);
        $achou34 = $dados->firstWhere('id', $p34->id);

        $sociedade->refresh();
        if ($achou34 && $sociedade->max_age === 32) {
            $this->info("  ✅ APROVADO: Pessoa de 34 anos localizada no filtro temporário e a sociedade manteve max_age = 32.");
            $passed++;
        } else {
            $this->error("  ❌ FALHOU: Filtro temporário não respeitou os parâmetros ou alterou o cadastro da sociedade.");
        }
        $p34->delete();

        // -------------------------------------------------------------
        // TESTE 4: Preservar sócio que completou 33 anos
        // -------------------------------------------------------------
        $this->line("\n[4/10] Testando: Preservar sócio que completou 33 anos (nunca desliga automaticamente)...");
        $p33 = Person::create([
            'institution_id' => $instituicao->id,
            'full_name' => 'Sócio Veterano 33 Anos ' . uniqid(),
            'gender' => 'Masculino',
            'birth_date' => Carbon::now()->subYears(33)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);
        $m33 = SociedadeMembro::create([
            'institution_id' => $instituicao->id,
            'sociedade_id' => $sociedade->id,
            'person_id' => $p33->id,
            'tipo_socio' => 'efetivo',
            'data_admissao' => Carbon::now()->subYears(2)->toDateString(),
            'status' => 'ativo',
            'created_by' => $user->id,
        ]);

        $res = $controller->getMembros($sociedade);
        $membros = collect($res->getData(true)['data']);
        $socio = $membros->firstWhere('person_id', $p33->id);

        if ($socio && $socio['status'] === 'ativo' && $socio['elegibilidade']['status'] === 'acima_faixa') {
            $this->info("  ✅ APROVADO: Sócio de 33 anos permanece ativo e etiquetado como 'acima_faixa' de forma não obstrutiva.");
            $passed++;
        } else {
            $this->error("  ❌ FALHOU: Sócio foi inativado ou status incorreto.");
        }
        $m33->delete();
        $p33->delete();

        // -------------------------------------------------------------
        // TESTE 5: Impedir arrolamento duplicado
        // -------------------------------------------------------------
        $this->line("\n[5/10] Testando: Impedir arrolamento duplicado ativo...");
        $pUnico = Person::create([
            'institution_id' => $instituicao->id,
            'full_name' => 'Sócio Único ' . uniqid(),
            'gender' => 'Feminino',
            'birth_date' => Carbon::now()->subYears(20)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);
        // Primeiro arrolamento
        SociedadeMembro::create([
            'institution_id' => $instituicao->id,
            'sociedade_id' => $sociedade->id,
            'person_id' => $pUnico->id,
            'tipo_socio' => 'efetivo',
            'status' => 'ativo',
            'created_by' => $user->id,
        ]);

        // Tentativa de duplicar
        $req = Request::create("/api/sociedades/{$sociedade->id}/membros", 'POST', [
            'person_id' => $pUnico->id,
            'tipo_socio' => 'efetivo',
        ]);
        $req->setUserResolver(fn () => $user);
        $res = $controller->storeMembro($req, $sociedade);

        if ($res->getStatusCode() === 422) {
            $this->info("  ✅ APROVADO: Bloqueio correto com 422 contra duplicidade de vínculo ativo.");
            $passed++;
        } else {
            $this->error("  ❌ FALHOU: Permitiu arrolamento duplicado.");
        }
        SociedadeMembro::where('person_id', $pUnico->id)->delete();
        $pUnico->delete();

        // -------------------------------------------------------------
        // TESTE 6: Processar seleção em lote de múltiplos membros
        // -------------------------------------------------------------
        $this->line("\n[6/10] Testando: Processar seleção em lote de múltiplos membros...");
        $lotePessoas = [];
        for ($i = 0; $i < 5; $i++) {
            $lotePessoas[] = Person::create([
                'institution_id' => $instituicao->id,
                'full_name' => "Candidato Lote {$i} " . uniqid(),
                'gender' => 'Masculino',
                'birth_date' => Carbon::now()->subYears(20 + $i)->toDateString(),
                'is_active' => true,
                'canonical_status' => 'comungante',
            ]);
        }
        $ids = array_map(fn ($p) => $p->id, $lotePessoas);

        $req = Request::create("/api/sociedades/{$sociedade->id}/membros/em-lote", 'POST', [
            'person_ids' => $ids,
            'tipo_socio' => 'efetivo',
        ]);
        $req->setUserResolver(fn () => $user);
        $res = $controller->arrolarEmLote($req, $sociedade);
        $r = $res->getData(true)['resumo'];

        if ($res->getStatusCode() === 200 && $r['novos_arrolados'] === 5 && $r['ja_arrolados'] === 0) {
            $this->info("  ✅ APROVADO: Arrolamento em lote de 5 pessoas processado com sucesso transacional.");
            $passed++;
        } else {
            $this->error("  ❌ FALHOU: Erro no lote.");
        }
        SociedadeMembro::whereIn('person_id', $ids)->delete();
        Person::whereIn('id', $ids)->delete();

        // -------------------------------------------------------------
        // TESTE 7: Preservar sócios após mudança da faixa da sociedade
        // -------------------------------------------------------------
        $this->line("\n[7/10] Testando: Preservar sócios após mudança da faixa da sociedade...");
        $p20 = Person::create([
            'institution_id' => $instituicao->id,
            'full_name' => 'Sócio Faixa Mudada ' . uniqid(),
            'gender' => 'Masculino',
            'birth_date' => Carbon::now()->subYears(20)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);
        $m20 = SociedadeMembro::create([
            'institution_id' => $instituicao->id,
            'sociedade_id' => $sociedade->id,
            'person_id' => $p20->id,
            'tipo_socio' => 'efetivo',
            'status' => 'ativo',
            'created_by' => $user->id,
        ]);

        // Altera a faixa da sociedade para 25 a 35 anos
        $req = Request::create("/api/sociedades/{$sociedade->id}", 'PUT', [
            'min_age' => 25,
            'max_age' => 35,
        ]);
        $req->setUserResolver(fn () => $user);
        $controller->update($req, $sociedade);

        // O membro de 20 anos deve continuar existindo e ativo
        $m20->refresh();
        if ($m20->status === 'ativo') {
            $this->info("  ✅ APROVADO: Vínculo ativo do sócio foi 100% preservado após alteração da faixa da sociedade.");
            $passed++;
        } else {
            $this->error("  ❌ FALHOU: Vínculo do sócio foi corrompido.");
        }

        // Restaura
        $sociedade->update(['min_age' => 18, 'max_age' => 32]);
        $m20->delete();
        $p20->delete();

        // -------------------------------------------------------------
        // TESTE 8: Tratar pessoa sem data de nascimento
        // -------------------------------------------------------------
        $this->line("\n[8/10] Testando: Tratar pessoa sem data de nascimento...");
        $pSemData = Person::create([
            'institution_id' => $instituicao->id,
            'full_name' => 'Membro Sem Data Nasc ' . uniqid(),
            'gender' => 'Feminino',
            'birth_date' => null,
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        $eval = $sociedade->evaluateEligibility($pSemData);
        if ($eval['status'] === 'sem_nascimento' && in_array('Data de nascimento não informada', $eval['reasons'])) {
            $this->info("  ✅ APROVADO: Pessoa sem data de nascimento avaliada corretamente como 'sem_nascimento'.");
            $passed++;
        } else {
            $this->error("  ❌ FALHOU: Elegibilidade para sem data de nascimento incorreta.");
        }
        $pSemData->delete();

        // -------------------------------------------------------------
        // TESTE 9: Garantir isolamento entre instituições
        // -------------------------------------------------------------
        $this->line("\n[9/10] Testando: Garantir isolamento rigoroso entre instituições...");
        $outraIgreja = Institution::create([
            'name' => 'Outra Igreja Presbiteriana ' . uniqid(),
            'short_name' => 'Outra IPB',
            'slug' => 'outra-' . uniqid(),
        ]);
        $pOutra = Person::create([
            'institution_id' => $outraIgreja->id,
            'full_name' => 'Membro de Outra Congregação ' . uniqid(),
            'gender' => 'Masculino',
            'birth_date' => Carbon::now()->subYears(25)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        $req = Request::create("/api/sociedades/{$sociedade->id}/membros/em-lote", 'POST', [
            'person_ids' => [$pOutra->id],
            'tipo_socio' => 'efetivo',
        ]);
        $req->setUserResolver(fn () => $user);
        $res = $controller->arrolarEmLote($req, $sociedade);

        if ($res->getStatusCode() === 422) {
            $this->info("  ✅ APROVADO: Tentativa de arrolamento de membro de outra instituição bloqueada.");
            $passed++;
        } else {
            $this->error("  ❌ FALHOU: Isolamento de instituição quebrado.");
        }
        $pOutra->delete();
        $outraIgreja->delete();

        // -------------------------------------------------------------
        // TESTE 10: Validar idempotência e concorrência no arrolamento em lote
        // -------------------------------------------------------------
        $this->line("\n[10/10] Testando: Idempotência de arrolamento em lote (reexecução segura)...");
        $pConcorrencia = Person::create([
            'institution_id' => $instituicao->id,
            'full_name' => 'Candidato Idempotência ' . uniqid(),
            'gender' => 'Feminino',
            'birth_date' => Carbon::now()->subYears(21)->toDateString(),
            'is_active' => true,
            'canonical_status' => 'comungante',
        ]);

        $req1 = Request::create("/api/sociedades/{$sociedade->id}/membros/em-lote", 'POST', [
            'person_ids' => [$pConcorrencia->id],
            'tipo_socio' => 'efetivo',
        ]);
        $req1->setUserResolver(fn () => $user);
        $res1 = $controller->arrolarEmLote($req1, $sociedade);
        $r1 = $res1->getData(true)['resumo'];

        $req2 = Request::create("/api/sociedades/{$sociedade->id}/membros/em-lote", 'POST', [
            'person_ids' => [$pConcorrencia->id],
            'tipo_socio' => 'efetivo',
        ]);
        $req2->setUserResolver(fn () => $user);
        $res2 = $controller->arrolarEmLote($req2, $sociedade);
        $r2 = $res2->getData(true)['resumo'];

        $totalRegistros = SociedadeMembro::where('sociedade_id', $sociedade->id)
            ->where('person_id', $pConcorrencia->id)
            ->count();

        if ($r1['novos_arrolados'] === 1 && $r2['novos_arrolados'] === 0 && $r2['ja_arrolados'] === 1 && $totalRegistros === 1) {
            $this->info("  ✅ APROVADO: Idempotência validada: segunda tentativa identificou sócio ativo e manteve registro único.");
            $passed++;
        } else {
            $this->error("  ❌ FALHOU: Idempotência violada.");
        }
        SociedadeMembro::where('person_id', $pConcorrencia->id)->delete();
        $pConcorrencia->delete();

        // Limpeza final da sociedade de teste
        SociedadeMembro::where('sociedade_id', $sociedade->id)->delete();
        $sociedade->delete();

        $this->info('===============================================================');
        $this->info("🎯 RESULTADO: {$passed} de {$total} testes aprovados com sucesso!");
        $this->info('===============================================================');

        return $passed === $total ? 0 : 1;
    }
}
