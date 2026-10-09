<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CallController;
use App\Http\Controllers\Api\ClassController;
use App\Http\Controllers\Api\ClassTeacherController;
use App\Http\Controllers\Api\EnrollmentController;
use App\Http\Controllers\Api\Dizimos\AuditoriaController;
use App\Http\Controllers\Api\Dizimos\ColetaController;
use App\Http\Controllers\Api\Dizimos\DiaconatoController;
use App\Http\Controllers\Api\Dizimos\PastoralController;
use App\Http\Controllers\Api\Dizimos\TithesReportController;
use App\Http\Controllers\Api\Dizimos\TithesSettingsController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\InstitutionController;
use App\Http\Controllers\Api\PersonController;
use App\Http\Controllers\Api\FamilyController;
use App\Http\Controllers\Api\Financial\FinancialAccountController;
use App\Http\Controllers\Api\Financial\FinancialAccountingController;
use App\Http\Controllers\Api\Financial\FinancialCategoryController;
use App\Http\Controllers\Api\Financial\FinancialCostCenterController;
use App\Http\Controllers\Api\Financial\FinancialTransactionController;
use App\Http\Controllers\Api\SessionController;
use App\Http\Controllers\Api\SystemAdminController;
use App\Http\Controllers\Api\SecretariaController;
use App\Http\Controllers\Api\SociedadesController;
use App\Http\Controllers\Api\DiscipuladoBibliotecaController;
use App\Http\Controllers\Api\RelatoriosOficiaisController;
use App\Http\Controllers\Api\DisciplinaController;
use App\Http\Controllers\Api\DiaconiaPatrimonioController;
use App\Http\Controllers\Api\CotasOrcamentoController;
use App\Http\Controllers\Api\ExameContasController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {

    // ---- Público ----
    Route::post('auth/login', [AuthController::class, 'login']);
    Route::post('auth/register-church', [AuthController::class, 'registerChurch']);



    // ---- Autenticado ----
    Route::middleware('auth:sanctum')->group(function () {

        Route::get('auth/me', [AuthController::class, 'me']);
        Route::post('auth/logout', [AuthController::class, 'logout']);

        Route::get('admin/users', [SystemAdminController::class, 'users'])->middleware('permission:user.manage');
        Route::post('admin/users', [SystemAdminController::class, 'storeUser'])->middleware('permission:user.manage');
        Route::match(['put', 'patch'], 'admin/users/{user}', [SystemAdminController::class, 'updateUser'])->middleware('permission:user.manage');
        Route::delete('admin/users/{user}', [SystemAdminController::class, 'destroyUser'])->middleware('permission:user.manage');
        Route::get('admin/roles', [SystemAdminController::class, 'roles'])->middleware('permission:role.manage');
        Route::put('admin/roles/{role}', [SystemAdminController::class, 'updateRole'])->middleware('permission:role.manage');
        Route::get('admin/permissions', [SystemAdminController::class, 'permissions'])->middleware('permission:role.manage');

        // Pessoas (autorização fina via PersonPolicy nos métodos;
        // 'permission' garante a checagem também a nível de rota)
        Route::get('people/birthdays', [PersonController::class, 'birthdays'])
            ->middleware('permission:person.view');
        Route::get('people', [PersonController::class, 'index'])
            ->middleware('permission:person.view');
        Route::get('people/{person}', [PersonController::class, 'show'])
            ->middleware('permission:person.view');
        Route::post('people', [PersonController::class, 'store'])
            ->middleware('permission:person.manage');
        Route::match(['put', 'patch'], 'people/{person}', [PersonController::class, 'update'])
            ->middleware('permission:person.manage');
        Route::delete('people/{person}', [PersonController::class, 'destroy'])
            ->middleware('permission:person.manage');

        Route::apiResource('families', FamilyController::class);

        // ---- Fase 2: Classes ----
        Route::get('classes', [ClassController::class, 'index'])->middleware('permission:class.view');
        Route::get('classes/{class}/sessions', [ClassController::class, 'sessions'])->middleware('permission:call.view');
        Route::get('classes/{class}', [ClassController::class, 'show'])->middleware('permission:class.view');
        Route::post('classes', [ClassController::class, 'store'])->middleware('permission:class.manage');
        Route::match(['put', 'patch'], 'classes/{class}', [ClassController::class, 'update'])->middleware('permission:class.manage');
        Route::delete('classes/{class}', [ClassController::class, 'destroy'])->middleware('permission:class.manage');

        // Matrículas (alunos por classe) — vigência preservada
        Route::get('classes/{class}/students', [EnrollmentController::class, 'index'])->middleware('permission:class.view');
        Route::post('classes/{class}/students', [EnrollmentController::class, 'store'])->middleware('permission:enrollment.manage');
        Route::delete('classes/{class}/students/{personId}', [EnrollmentController::class, 'destroy'])->middleware('permission:enrollment.manage');
        Route::post('classes/{class}/students/{personId}/transfer', [EnrollmentController::class, 'transfer'])->middleware('permission:enrollment.manage');

        // Professores habilitados por classe (só can_teach)
        Route::get('classes/{class}/teachers', [ClassTeacherController::class, 'index'])->middleware('permission:class.view');
        Route::post('classes/{class}/teachers', [ClassTeacherController::class, 'store'])->middleware('permission:class.manage');
        Route::delete('classes/{class}/teachers/{personId}', [ClassTeacherController::class, 'destroy'])->middleware('permission:class.manage');

        // ---- Fase 3: Calendário / Encontros ----
        Route::get('events', [EventController::class, 'index'])->middleware('permission:event.view');
        Route::post('events/generate', [EventController::class, 'generate'])->middleware('permission:event.generate');
        Route::post('events', [EventController::class, 'storeAdhoc'])->middleware('permission:event.create_adhoc');
        Route::get('events/{event}', [EventController::class, 'show'])->middleware('permission:event.view');
        Route::match(['put', 'patch'], 'events/{event}', [EventController::class, 'update'])->middleware('permission:event.manage');
        Route::put('events/{event}/superintendent', [EventController::class, 'setSuperintendent'])->middleware('permission:superintendent.assign');

        // Sessões (status de não-funcionamento nesta fase; chamada completa na Fase 5)
        Route::get('sessions/{session}', [SessionController::class, 'show'])->middleware('permission:call.view');
        Route::put('sessions/{session}/status', [SessionController::class, 'setStatus'])->middleware('permission:call.edit');

        // ---- Fase 4: Escalas ----
        Route::get('schedules/teachers', [\App\Http\Controllers\Api\ScheduleController::class, 'teacherSchedules'])->middleware('permission:schedule.view');
        Route::post('schedules/teachers', [\App\Http\Controllers\Api\ScheduleController::class, 'setTeacherSchedule'])->middleware('permission:schedule.manage');
        Route::get('schedules/superintendents', [\App\Http\Controllers\Api\ScheduleController::class, 'superintendentSchedules'])->middleware('permission:schedule.view');
        Route::post('schedules/superintendents', [\App\Http\Controllers\Api\ScheduleController::class, 'setSuperintendentSchedule'])->middleware('permission:schedule.manage');
        Route::post('schedules/seed-fictional', [\App\Http\Controllers\Api\ScheduleController::class, 'seedFictional'])->middleware('permission:schedule.manage');

        // ---- Fase 5: Chamada ----
        Route::get('sessions/{session}/records', [CallController::class, 'records'])->middleware('permission:call.view');
        Route::post('sessions/{session}/open', [CallController::class, 'open'])->middleware('permission:call.perform');
        Route::put('sessions/{session}/attendance', [CallController::class, 'attendance'])->middleware('permission:call.perform');
        Route::put('sessions/{session}/teacher', [CallController::class, 'setTeacher'])->middleware('permission:call.edit');
        Route::put('sessions/{session}/materials', [CallController::class, 'materials'])->middleware('permission:call.edit');
        Route::post('sessions/{session}/finalize', [CallController::class, 'finalize'])->middleware('permission:call.finalize');
        Route::post('sessions/{session}/reopen', [CallController::class, 'reopen'])->middleware('permission:call.reopen');

        // ---- Fase 6: Dashboard & Painel do Superintendente em Tempo Real ----
        Route::get('dashboard/summary', [\App\Http\Controllers\Api\EbdDashboardController::class, 'summary']);
        Route::get('dashboard/superintendent-live/{eventId?}', [\App\Http\Controllers\Api\EbdDashboardController::class, 'superintendentLive'])->middleware('permission:call.view');

        // ---- Fase 7: Relatórios EBD & Assembleia Geral ----
        Route::get('reports/ebd/monthly', [\App\Http\Controllers\Api\EbdReportController::class, 'monthly'])->middleware('permission:report.view');
        Route::get('reports/ebd/class/{class}', [\App\Http\Controllers\Api\EbdReportController::class, 'byClass'])->middleware('permission:report.view');
        Route::get('reports/ebd/student/{person}', [\App\Http\Controllers\Api\EbdReportController::class, 'byStudent'])->middleware('permission:report.view');
        Route::get('reports/annual', [\App\Http\Controllers\Api\AnnualReportController::class, 'summary'])->middleware('permission:report.view');

        // ---- Fase 8: Auditoria Geral EBD ----
        Route::get('audit/logs', [\App\Http\Controllers\Api\EbdAuditController::class, 'index'])->middleware('permission:audit.view');

        // ---- Módulo de Instituições & Estrutura Hierárquica ----
        Route::prefix('institutions')->group(function () {
            Route::get('tree', [InstitutionController::class, 'tree'])->middleware('permission:institution.tree.view');
            Route::get('by-code/{code}', [InstitutionController::class, 'lookupCode'])->middleware('permission:institution.view');
            Route::get('link-requests/list', [InstitutionController::class, 'indexLinkRequests'])->middleware('permission:institution.view');
            Route::post('link-requests', [InstitutionController::class, 'storeLinkRequest'])->middleware('permission:institution.manage');
            Route::post('link-requests/{linkRequest}/accept', [InstitutionController::class, 'acceptLinkRequest'])->middleware('permission:institution.manage');
            Route::post('link-requests/{linkRequest}/reject', [InstitutionController::class, 'rejectLinkRequest'])->middleware('permission:institution.manage');
            Route::post('link-requests/{linkRequest}/cancel', [InstitutionController::class, 'cancelLinkRequest'])->middleware('permission:institution.manage');

            Route::get('/', [InstitutionController::class, 'index'])->middleware('permission:institution.view');
            Route::post('/', [InstitutionController::class, 'store'])->middleware('permission:institution.manage');
            Route::get('{institution}', [InstitutionController::class, 'show'])->middleware('permission:institution.view');
            Route::match(['put', 'patch'], '{institution}', [InstitutionController::class, 'update'])->middleware('permission:institution.manage');
            Route::delete('{institution}', [InstitutionController::class, 'destroy'])->middleware('permission:institution.manage');

            Route::get('{institution}/subordinates', [InstitutionController::class, 'subordinates'])->middleware('permission:institution.subordinate.view');
            Route::get('{institution}/breadcrumbs', [InstitutionController::class, 'breadcrumbs'])->middleware('permission:institution.view');
            Route::post('{institution}/transfer', [InstitutionController::class, 'transfer'])->middleware('permission:institution.transfer');
            Route::get('{institution}/history', [InstitutionController::class, 'history'])->middleware('permission:institution.view');
            
            // Dashboard e estatísticas consolidadas
            Route::get('{institution}/dashboard/summary', [InstitutionController::class, 'dashboardSummary'])->middleware('permission:institution.consolidated.view');
            Route::get('{institution}/dashboard/drilldown', [InstitutionController::class, 'dashboardDrilldown'])->middleware('permission:institution.consolidated.view');
            Route::get('{institution}/dashboard/cults', [InstitutionController::class, 'cultByCult'])->middleware('permission:institution.consolidated.view');
        });

        // ---- Módulo de Dízimos ----
        Route::prefix('dizimos')->group(function () {
            // Coletas & Lançamentos Rápido
            Route::get('coletas', [ColetaController::class, 'index'])->middleware('permission:dizimos.coleta.operar');
            Route::post('coletas', [ColetaController::class, 'store'])->middleware('permission:dizimos.coleta.operar');
            Route::get('coletas/{coleta}', [ColetaController::class, 'show'])->middleware('permission:dizimos.coleta.operar');
            Route::post('coletas/{coleta}/lancamentos', [ColetaController::class, 'storeLancamento'])->middleware('permission:dizimos.coleta.operar');
            Route::post('coletas/{coleta}/fechar', [ColetaController::class, 'close'])->middleware('permission:dizimos.coleta.fechar');
            Route::post('coletas/{coleta}/reabrir', [ColetaController::class, 'reopen'])->middleware('permission:dizimos.coleta.reabrir');
            Route::put('coletas/{coleta}/lancamentos/{lancamento}', [ColetaController::class, 'updateLancamento'])->middleware('permission:dizimos.coleta.reabrir');

            // Pastoral & Alertas & Ficha Individual
            Route::get('pastoral/dashboard', [PastoralController::class, 'dashboard'])->middleware('permission:dizimos.alertas.manage');
            Route::get('pastoral/alertas', [PastoralController::class, 'alerts'])->middleware('permission:dizimos.alertas.manage');
            Route::get('pastoral/alertas/{alerta}', [PastoralController::class, 'alertShow'])->middleware('permission:dizimos.alertas.manage');
            Route::post('pastoral/alertas/{alerta}/acompanhamentos', [PastoralController::class, 'storeAcompanhamento'])->middleware('permission:dizimos.alertas.manage');
            Route::post('pastoral/solicitar-diaconato', [PastoralController::class, 'createDiaconatoRequest'])->middleware('permission:dizimos.alertas.manage');
            Route::post('pastoral/run-engine', [PastoralController::class, 'triggerAlertEngine'])->middleware('permission:dizimos.alertas.manage');

            // Histórico Financeiro Individual do Membro (Restrição Estrita)
            Route::get('membros/{person}/historico', [PastoralController::class, 'memberHistory'])->middleware('permission:dizimos.historico_individual.view');

            // Fila de Atendimento do Diaconato (Sem dados financeiros)
            Route::get('diaconato/solicitacoes', [DiaconatoController::class, 'index'])->middleware('permission:dizimos.diaconato.atender');
            Route::post('diaconato/solicitacoes', [DiaconatoController::class, 'store'])->middleware('permission:dizimos.diaconato.atender');
            Route::put('diaconato/solicitacoes/{solicitacao}', [DiaconatoController::class, 'update'])->middleware('permission:dizimos.diaconato.atender');

            // Relatórios Agregados & Exportação
            Route::get('relatorios/geral', [TithesReportController::class, 'general'])->middleware('permission:dizimos.relatorios.view');
            Route::get('relatorios/exportar', [TithesReportController::class, 'export'])->middleware('permission:dizimos.relatorios.export');

            // Configurações
            Route::get('settings', [TithesSettingsController::class, 'show'])->middleware('permission:dizimos.config.manage');
            Route::put('settings', [TithesSettingsController::class, 'update'])->middleware('permission:dizimos.config.manage');

            // Auditoria
            Route::get('auditoria', [AuditoriaController::class, 'index'])->middleware('permission:audit.view');
        });

        // ---- Módulo Financeiro & Contábil ----
        Route::prefix('financial')->group(function () {
            // Lançamentos / Livro Caixa
            Route::get('transactions/summary', [FinancialTransactionController::class, 'summary'])->middleware('permission:financial.view');
            Route::get('transactions', [FinancialTransactionController::class, 'index'])->middleware('permission:financial.view');
            Route::post('transactions', [FinancialTransactionController::class, 'store'])->middleware('permission:financial.manage');
            Route::get('transactions/{transaction}', [FinancialTransactionController::class, 'show'])->middleware('permission:financial.view');
            Route::match(['put', 'patch'], 'transactions/{transaction}', [FinancialTransactionController::class, 'update'])->middleware('permission:financial.manage');
            Route::delete('transactions/{transaction}', [FinancialTransactionController::class, 'destroy'])->middleware('permission:financial.manage');

            // Contas Bancárias & Caixas
            Route::get('accounts', [FinancialAccountController::class, 'index'])->middleware('permission:financial.view');
            Route::post('accounts', [FinancialAccountController::class, 'store'])->middleware('permission:financial.accounts.manage');
            Route::get('accounts/{account}', [FinancialAccountController::class, 'show'])->middleware('permission:financial.view');
            Route::match(['put', 'patch'], 'accounts/{account}', [FinancialAccountController::class, 'update'])->middleware('permission:financial.accounts.manage');
            Route::delete('accounts/{account}', [FinancialAccountController::class, 'destroy'])->middleware('permission:financial.accounts.manage');
            Route::post('accounts/{account}/recalculate', [FinancialAccountController::class, 'recalculate'])->middleware('permission:financial.accounts.manage');

            // Categorias / Plano de Contas
            Route::get('categories', [FinancialCategoryController::class, 'index'])->middleware('permission:financial.view');
            Route::post('categories', [FinancialCategoryController::class, 'store'])->middleware('permission:financial.categories.manage');
            Route::get('categories/{category}', [FinancialCategoryController::class, 'show'])->middleware('permission:financial.view');
            Route::match(['put', 'patch'], 'categories/{category}', [FinancialCategoryController::class, 'update'])->middleware('permission:financial.categories.manage');
            Route::delete('categories/{category}', [FinancialCategoryController::class, 'destroy'])->middleware('permission:financial.categories.manage');

            // Centros de Custo
            Route::get('cost-centers', [FinancialCostCenterController::class, 'index'])->middleware('permission:financial.view');
            Route::post('cost-centers', [FinancialCostCenterController::class, 'store'])->middleware('permission:financial.categories.manage');
            Route::get('cost-centers/{costCenter}', [FinancialCostCenterController::class, 'show'])->middleware('permission:financial.view');
            Route::match(['put', 'patch'], 'cost-centers/{costCenter}', [FinancialCostCenterController::class, 'update'])->middleware('permission:financial.categories.manage');
            Route::delete('cost-centers/{costCenter}', [FinancialCostCenterController::class, 'destroy'])->middleware('permission:financial.categories.manage');

            // Contabilidade & Fechamento
            Route::get('accounting/ledger', [FinancialAccountingController::class, 'ledger'])->middleware('permission:financial.accounting.view');
            Route::get('accounting/trial-balance', [FinancialAccountingController::class, 'trialBalance'])->middleware('permission:financial.accounting.view');
            Route::get('accounting/export-csv', [FinancialAccountingController::class, 'exportCsv'])->middleware('permission:financial.accounting.view');
            Route::post('accounting/close-month', [FinancialAccountingController::class, 'closeMonth'])->middleware('permission:financial.accounting.close');
            Route::post('accounting/reopen-month', [FinancialAccountingController::class, 'reopenMonth'])->middleware('permission:financial.accounting.close');
        });

        // ---- 🏛️ 1. Secretaria & Conselho da Igreja (Canônico IPB) ----
        Route::prefix('secretaria')->group(function () {
            Route::get('membros', [SecretariaController::class, 'membros']);
            Route::get('membros/{person}', [SecretariaController::class, 'showMembro']);
            Route::put('membros/{person}', [SecretariaController::class, 'updateMembro']);
            Route::get('estatistica-presbiterio', [SecretariaController::class, 'estatisticaPresbiterio']);
            Route::get('cartas', [SecretariaController::class, 'cartas']);
            Route::post('cartas', [SecretariaController::class, 'storeCarta']);
            Route::get('cartas/{carta}', [SecretariaController::class, 'showCarta']);
            Route::get('atas', [SecretariaController::class, 'atas']);
            Route::post('atas', [SecretariaController::class, 'storeAta']);
            Route::get('atas/{ata}', [SecretariaController::class, 'showAta']);
            Route::put('atas/{ata}', [SecretariaController::class, 'updateAta']);
            Route::patch('atas/{ata}/aprovar', [SecretariaController::class, 'aprovarAta']);
        });

        // ---- 👥 2. Sociedades Internas & Ministérios (SAF, UPH, UMP, UPA, UCP) ----
        Route::prefix('sociedades')->group(function () {
            Route::get('/', [SociedadesController::class, 'index']);
            Route::post('/', [SociedadesController::class, 'store']);
            Route::get('{sociedade}', [SociedadesController::class, 'show']);
            Route::put('{sociedade}', [SociedadesController::class, 'update']);
            Route::delete('{sociedade}', [SociedadesController::class, 'destroy']);
            Route::post('{sociedade}/diretoria', [SociedadesController::class, 'storeDiretoria']);
            Route::post('{sociedade}/atividades', [SociedadesController::class, 'storeAtividade']);

            // Membros / Rol de Sócios
            Route::get('{sociedade}/membros', [SociedadesController::class, 'getMembros']);
            Route::post('{sociedade}/membros', [SociedadesController::class, 'storeMembro']);
            Route::post('{sociedade}/membros/em-lote', [SociedadesController::class, 'arrolarEmLote']);
            Route::delete('{sociedade}/membros/{membro}', [SociedadesController::class, 'deleteMembro']);

            // Livro de Atas da Sociedade
            Route::get('{sociedade}/atas', [SociedadesController::class, 'getAtas']);
            Route::post('{sociedade}/atas', [SociedadesController::class, 'storeAta']);
            Route::put('{sociedade}/atas/{ata}', [SociedadesController::class, 'updateAta']);
            Route::delete('{sociedade}/atas/{ata}', [SociedadesController::class, 'deleteAta']);
        });

        // ---- 📖 5. Discipulado & Biblioteca da Igreja ----
        Route::prefix('discipulado-biblioteca')->group(function () {
            Route::get('discipulado', [DiscipuladoBibliotecaController::class, 'discipulado']);
            Route::post('discipulado', [DiscipuladoBibliotecaController::class, 'storeCatecumeno']);
            Route::put('discipulado/{item}', [DiscipuladoBibliotecaController::class, 'updateCatecumeno']);
            Route::get('livros', [DiscipuladoBibliotecaController::class, 'livros']);
            Route::post('livros', [DiscipuladoBibliotecaController::class, 'storeLivro']);
            Route::get('emprestimos', [DiscipuladoBibliotecaController::class, 'emprestimos']);
            Route::post('emprestimos', [DiscipuladoBibliotecaController::class, 'storeEmprestimo']);
            Route::post('emprestimos/{emprestimo}/devolver', [DiscipuladoBibliotecaController::class, 'devolverEmprestimo']);
        });

        // ---- 📊 6. Relatórios Oficiais com Assinaturas ----
        Route::prefix('relatorios-oficiais')->group(function () {
            Route::get('termo-balancete', [RelatoriosOficiaisController::class, 'termoBalancete']);
            Route::get('ficha-ministerial/{person}', [RelatoriosOficiaisController::class, 'fichaMinisterial']);
        });

        // ---- ⚖️ 3. Código de Disciplina & Jurisdição Pastoral (CD/IPB) ----
        Route::prefix('disciplina')->group(function () {
            Route::get('processos', [DisciplinaController::class, 'index']);
            Route::post('processos', [DisciplinaController::class, 'store']);
            Route::get('processos/{processo}', [DisciplinaController::class, 'show']);
            Route::put('processos/{processo}', [DisciplinaController::class, 'update']);
            Route::post('processos/{processo}/restaurar', [DisciplinaController::class, 'restaurar']);
            Route::get('alertas-abandono', [DisciplinaController::class, 'alertasAbandono']);
        });

        // ---- 🏢 4. Junta Diaconal & Gestão Patrimonial (Zeladoria e Bens) ----
        Route::prefix('diaconia')->group(function () {
            // Livro Tombo / Patrimônio
            Route::get('bens', [DiaconiaPatrimonioController::class, 'listarBens']);
            Route::post('bens', [DiaconiaPatrimonioController::class, 'storeBem']);
            Route::get('bens/{bem}', [DiaconiaPatrimonioController::class, 'showBem']);
            Route::put('bens/{bem}', [DiaconiaPatrimonioController::class, 'updateBem']);
            Route::delete('bens/{bem}', [DiaconiaPatrimonioController::class, 'destroyBem']);

            // Ordens de Serviço & Zeladoria
            Route::get('ordens-servico', [DiaconiaPatrimonioController::class, 'listarOS']);
            Route::post('ordens-servico', [DiaconiaPatrimonioController::class, 'storeOS']);
            Route::put('ordens-servico/{os}', [DiaconiaPatrimonioController::class, 'updateOS']);
            Route::post('ordens-servico/{os}/concluir', [DiaconiaPatrimonioController::class, 'concluirOS']);

            // Escala de Diáconos do Culto
            Route::get('escalas', [DiaconiaPatrimonioController::class, 'listarEscalas']);
            Route::post('escalas', [DiaconiaPatrimonioController::class, 'storeEscala']);
            Route::put('escalas/{escala}', [DiaconiaPatrimonioController::class, 'updateEscala']);
        });

        // ---- 💸 5. Cotas Conciliares & Orçamento Anual Programa ----
        Route::prefix('cotas-orcamento')->group(function () {
            // Cotas Conciliares (Presbitério e SC)
            Route::get('cotas', [CotasOrcamentoController::class, 'listarCotas']);
            Route::post('cotas/calcular', [CotasOrcamentoController::class, 'calcularCotaMes']);
            Route::put('cotas/{cota}/pagamento', [CotasOrcamentoController::class, 'atualizarPagamento']);

            // Orçamento Anual (Orçado vs Realizado)
            Route::get('orcamento/comparativo', [CotasOrcamentoController::class, 'comparativoOrcamento']);
            Route::post('orcamento/linhas', [CotasOrcamentoController::class, 'storeLinha']);
            Route::put('orcamento/linhas/{linha}', [CotasOrcamentoController::class, 'updateLinha']);
            Route::delete('orcamento/linhas/{linha}', [CotasOrcamentoController::class, 'destroyLinha']);
        });

        // ---- 📜 6. Parecer da Comissão de Exame de Contas ----
        Route::prefix('exame-contas')->group(function () {
            Route::get('pareceres', [ExameContasController::class, 'index']);
            Route::get('auditar-periodo', [ExameContasController::class, 'auditarPeriodo']);
            Route::post('pareceres', [ExameContasController::class, 'store']);
            Route::get('pareceres/{parecer}', [ExameContasController::class, 'show']);
            Route::put('pareceres/{parecer}', [ExameContasController::class, 'update']);
        });
    });
});

