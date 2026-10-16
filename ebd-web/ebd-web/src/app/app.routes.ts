import { Routes } from '@angular/router';
import { authGuard, permissionAnyGuard, permissionGuard, screenGuard, superAdminGuard } from './core/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./pages/login/login').then((m) => m.LoginPage),
  },
  {
    path: '',
    loadComponent: () => import('./layout/component/app.layout').then((m) => m.AppLayout),
    canActivate: [authGuard],
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        canActivate: [screenGuard('dashboard')],
        loadComponent: () => import('./pages/dashboard/dashboard').then((m) => m.EbdDashboardPage),
      },
      // ---- PAINEL SUPER ADMIN (LIBERAÇÃO DE TELAS & TODAS AS IGREJAS) ----
      {
        path: 'admin/super-admin',
        canActivate: [superAdminGuard],
        loadComponent: () => import('./pages/admin/super-admin/super-admin').then((m) => m.SuperAdminPage),
      },
      // ---- Módulo de Instituições & Estrutura Hierárquica ----
      {
        path: 'instituicoes',
        canActivate: [permissionGuard('institution.view')],
        loadComponent: () => import('./pages/institutions/institution-list').then((m) => m.InstitutionListPage),
      },
      {
        path: 'instituicoes/arvore',
        canActivate: [permissionGuard('institution.tree.view')],
        loadComponent: () => import('./pages/institutions/institution-tree').then((m) => m.InstitutionTreePage),
      },
      {
        path: 'instituicoes/:id',
        canActivate: [permissionGuard('institution.view')],
        loadComponent: () => import('./pages/institutions/institution-detail').then((m) => m.InstitutionDetailPage),
      },
      {
        path: 'instituicoes/:id/dashboard',
        canActivate: [permissionGuard('institution.consolidated.view')],
        loadComponent: () => import('./pages/institutions/institution-dashboard').then((m) => m.InstitutionDashboardPage),
      },
      {
        path: 'classes',
        canActivate: [permissionGuard('class.view'), screenGuard('classes')],
        loadComponent: () => import('./pages/classes/classes-list').then((m) => m.ClassesListPage),
      },
      {
        path: 'classes/:id',
        canActivate: [permissionGuard('class.view'), screenGuard('classes')],
        loadComponent: () => import('./pages/classes/class-detail').then((m) => m.ClassDetailPage),
      },
      {
        path: 'calendario',
        canActivate: [permissionGuard('event.view'), screenGuard('calendario')],
        loadComponent: () => import('./pages/calendar/calendar-month').then((m) => m.CalendarMonthPage),
      },
      {
        path: 'escalas',
        canActivate: [permissionGuard('schedule.view'), screenGuard('escalas')],
        loadComponent: () => import('./pages/schedules/schedules').then((m) => m.SchedulesPage),
      },
      {
        path: 'relatorios',
        canActivate: [permissionGuard('report.view'), screenGuard('relatorios_ebd')],
        loadComponent: () => import('./pages/reports/reports').then((m) => m.EbdReportsPage),
      },
      {
        path: 'relatorios/anual',
        canActivate: [permissionGuard('report.view'), screenGuard('relatorio_anual')],
        loadComponent: () => import('./pages/reports/annual-report').then((m) => m.AnnualReportPage),
      },
      {
        path: 'inteligencia',
        canActivate: [screenGuard('inteligencia')],
        loadComponent: () => import('./pages/intelligence/intelligence').then((m) => m.IntelligencePage),
      },
      {
        path: 'eventos/:id',
        canActivate: [permissionGuard('event.view'), screenGuard('calendario')],
        loadComponent: () => import('./pages/calendar/event-detail').then((m) => m.EventDetailPage),
      },
      {
        path: 'chamada/:id',
        canActivate: [permissionGuard('call.view'), screenGuard('classes')],
        loadComponent: () => import('./pages/call/call').then((m) => m.CallPage),
      },
      {
        path: 'pessoas',
        canActivate: [permissionGuard('person.view'), screenGuard('pessoas')],
        loadComponent: () => import('./pages/people/people-list').then((m) => m.PeopleListPage),
      },
      {
        path: 'familias',
        canActivate: [permissionGuard('family.view'), screenGuard('familias')],
        loadComponent: () => import('./pages/families/families-list').then((m) => m.FamiliesListPage),
      },
      { path: 'admin/usuarios', canActivate: [permissionGuard('user.manage'), screenGuard('usuarios')], loadComponent: () => import('./pages/admin/users-admin').then(m => m.UsersAdminPage) },
      { path: 'admin/auditoria', canActivate: [permissionGuard('audit.view'), screenGuard('auditoria')], loadComponent: () => import('./pages/admin/audit').then(m => m.AuditPage) },
      // ---- Módulo de Dízimos ----
      {
        path: 'dizimos/coletas',
        canActivate: [permissionGuard('dizimos.coleta.operar'), screenGuard('dizimos')],
        loadComponent: () => import('./pages/dizimos/coletas-list').then((m) => m.ColetasListPage),
      },
      {
        path: 'dizimos/coletas/:id',
        canActivate: [permissionGuard('dizimos.coleta.operar'), screenGuard('dizimos')],
        loadComponent: () => import('./pages/dizimos/coleta-lancamento').then((m) => m.ColetaLancamentoPage),
      },
      {
        path: 'dizimos/aprovacoes-offline',
        canActivate: [permissionGuard('dizimos.offline_sync.view'), screenGuard('dizimos')],
        loadComponent: () => import('./pages/dizimos/offline-syncs').then((m) => m.OfflineSyncsPage),
      },
      {
        path: 'dizimos/alertas',
        canActivate: [permissionGuard('dizimos.alertas.manage'), screenGuard('alertas_pastorais')],
        loadComponent: () => import('./pages/dizimos/pastoral-alerts').then((m) => m.PastoralAlertsPage),
      },
      {
        path: 'pastoral/acompanhamento',
        redirectTo: 'dizimos/alertas',
        pathMatch: 'full',
      },
      {
        path: 'dizimos/membros/:id/historico',
        canActivate: [permissionGuard('dizimos.historico_individual.view'), screenGuard('dizimos')],
        loadComponent: () => import('./pages/dizimos/membro-historico').then((m) => m.MembroHistoricoPage),
      },
      {
        path: 'dizimos/diaconato',
        canActivate: [permissionGuard('dizimos.diaconato.atender'), screenGuard('diaconato')],
        loadComponent: () => import('./pages/dizimos/diaconato-solicitacoes').then((m) => m.DiaconatoSolicitacoesPage),
      },
      {
        path: 'diaconato/solicitacoes',
        redirectTo: 'dizimos/diaconato',
        pathMatch: 'full',
      },
      {
        path: 'dizimos/config',
        canActivate: [permissionGuard('dizimos.config.manage'), screenGuard('dizimos_config')],
        loadComponent: () => import('./pages/dizimos/dizimos-config').then((m) => m.DizimosConfigPage),
      },
      // ---- Módulo Financeiro & Contábil ----
      {
        path: 'financeiro',
        pathMatch: 'full',
        redirectTo: 'financeiro/transacoes',
      },
      {
        path: 'financeiro/transacoes',
        canActivate: [permissionGuard('financial.view'), screenGuard('financeiro')],
        loadComponent: () => import('./pages/financial/transactions-list').then((m) => m.FinancialTransactionsPage),
      },
      {
        path: 'financeiro/contabilidade',
        canActivate: [permissionGuard('financial.accounting.view'), screenGuard('contabilidade')],
        loadComponent: () => import('./pages/financial/accounting-report').then((m) => m.AccountingReportPage),
      },
      {
        path: 'financeiro/categorias-custos',
        canActivate: [permissionGuard('financial.view'), screenGuard('plano_contas')],
        loadComponent: () => import('./pages/financial/categories-cost-centers').then((m) => m.CategoriesCostCentersPage),
      },
      {
        path: 'financeiro/contas',
        canActivate: [permissionGuard('financial.view'), screenGuard('contas_bancarias')],
        loadComponent: () => import('./pages/financial/accounts-list').then((m) => m.AccountsListPage),
      },
      {
        path: 'financeiro/termo-balancete',
        canActivate: [permissionGuard('financial.accounting.view'), screenGuard('termo_balancete')],
        loadComponent: () => import('./pages/relatorios/termo-balancete').then((m) => m.TermoBalancetePage),
      },
      // ---- Secretaria & Conselho (IPB) ----
      {
        path: 'secretaria/membros',
        canActivate: [permissionGuard('secretaria.rol.view'), screenGuard('membros')],
        loadComponent: () => import('./pages/secretaria/membros-canonico').then((m) => m.MembrosCanonicoPage),
      },
      {
        path: 'secretaria/oficiais-lideranca',
        canActivate: [permissionGuard('person.view'), screenGuard('oficiais')],
        loadComponent: () => import('./pages/secretaria/oficiais-lideranca/oficiais-lideranca').then((m) => m.OficiaisLiderancaPage),
      },
      {
        path: 'secretaria/oficiais',
        redirectTo: 'secretaria/oficiais-lideranca',
        pathMatch: 'full',
      },
      {
        path: 'secretaria/estatistica-presbiterio',
        canActivate: [permissionGuard('presbiterio.consolidated.view'), screenGuard('estatistica_presbiterio')],
        loadComponent: () => import('./pages/secretaria/estatistica-presbiterio').then((m) => m.EstatisticaPresbiterioPage),
      },
      {
        path: 'secretaria/cartas',
        canActivate: [permissionGuard('secretaria.rol.view'), screenGuard('cartas')],
        loadComponent: () => import('./pages/secretaria/cartas-transferencia').then((m) => m.CartasTransferenciaPage),
      },
      {
        path: 'secretaria/atas',
        canActivate: [permissionAnyGuard('secretaria.atas.view', 'conselho.approve'), screenGuard('atas')],
        loadComponent: () => import('./pages/secretaria/atas-conselho').then((m) => m.AtasConselhoPage),
      },
      {
        path: 'secretaria/boletim',
        canActivate: [permissionGuard('person.view'), screenGuard('boletim')],
        loadComponent: () => import('./pages/secretaria/boletim/boletim-elaborador').then((m) => m.BoletimElaboradorPage),
      },
      // ---- Sociedades Internas & Ministérios ----
      {
        path: 'sociedades',
        canActivate: [permissionGuard('person.view'), screenGuard('sociedades')],
        loadComponent: () => import('./pages/sociedades/sociedades').then((m) => m.SociedadesPage),
      },
      // ---- Discipulado & Biblioteca da Igreja ----
      {
        path: 'discipulado-biblioteca',
        canActivate: [permissionGuard('person.view'), screenGuard('discipulado_biblioteca')],
        loadComponent: () => import('./pages/discipulado/discipulado-biblioteca').then((m) => m.DiscipuladoBibliotecaPage),
      },
      // ---- ⚖️ Código de Disciplina & Jurisdição Pastoral ----
      {
        path: 'secretaria/disciplina',
        canActivate: [permissionGuard('person.view'), screenGuard('disciplina')],
        loadComponent: () => import('./pages/secretaria/disciplina-pastoral/disciplina-pastoral').then((m) => m.DisciplinaPastoralPage),
      },
      // ---- 🏢 Junta Diaconal & Gestão Patrimonial ----
      {
        path: 'diaconia/patrimonio',
        canActivate: [permissionGuard('person.view'), screenGuard('patrimonio')],
        loadComponent: () => import('./pages/diaconia/diaconia-patrimonio/diaconia-patrimonio').then((m) => m.DiaconiaPatrimonioPage),
      },
      // ---- 💸 Cotas Conciliares & Orçamento Anual Programa ----
      {
        path: 'financeiro/cotas-orcamento',
        canActivate: [permissionGuard('financial.view'), screenGuard('cotas_orcamento')],
        loadComponent: () => import('./pages/financial/cotas-orcamento/cotas-orcamento').then((m) => m.CotasOrcamentoPage),
      },
      // ---- 📜 Parecer da Comissão de Exame de Contas ----
      {
        path: 'relatorios/parecer-exame-contas',
        canActivate: [permissionGuard('financial.accounting.view'), screenGuard('parecer_exame_contas')],
        loadComponent: () => import('./pages/relatorios/parecer-exame-contas/parecer-exame-contas').then((m) => m.ParecerExameContasPage),
      },
    ],
  },
  {
    path: 'acesso-negado',
    canActivate: [authGuard],
    loadComponent: () => import('./pages/auth/access-denied').then((m) => m.AccessDeniedPage),
  },
  { path: '**', redirectTo: '' },
];
