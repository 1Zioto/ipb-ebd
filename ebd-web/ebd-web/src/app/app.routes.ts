import { Routes } from '@angular/router';
import { authGuard, permissionGuard } from './core/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./pages/login/login').then((m) => m.LoginPage),
  },
  {
    path: '',
    loadComponent: () => import('./layout/shell').then((m) => m.Shell),
    canActivate: [authGuard],
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        loadComponent: () => import('./pages/dashboard/dashboard').then((m) => m.EbdDashboardPage),
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
        canActivate: [permissionGuard('class.view')],
        loadComponent: () => import('./pages/classes/classes-list').then((m) => m.ClassesListPage),
      },
      {
        path: 'classes/:id',
        canActivate: [permissionGuard('class.view')],
        loadComponent: () => import('./pages/classes/class-detail').then((m) => m.ClassDetailPage),
      },
      {
        path: 'calendario',
        canActivate: [permissionGuard('event.view')],
        loadComponent: () => import('./pages/calendar/calendar-month').then((m) => m.CalendarMonthPage),
      },
      {
        path: 'escalas',
        canActivate: [permissionGuard('schedule.view')],
        loadComponent: () => import('./pages/schedules/schedules').then((m) => m.SchedulesPage),
      },
      {
        path: 'relatorios',
        canActivate: [permissionGuard('report.view')],
        loadComponent: () => import('./pages/reports/reports').then((m) => m.EbdReportsPage),
      },
      {
        path: 'eventos/:id',
        canActivate: [permissionGuard('event.view')],
        loadComponent: () => import('./pages/calendar/event-detail').then((m) => m.EventDetailPage),
      },
      {
        path: 'chamada/:id',
        canActivate: [permissionGuard('call.view')],
        loadComponent: () => import('./pages/call/call').then((m) => m.CallPage),
      },
      {
        path: 'pessoas',
        canActivate: [permissionGuard('person.view')],
        loadComponent: () => import('./pages/people/people-list').then((m) => m.PeopleListPage),
      },
      {
        path: 'familias',
        canActivate: [permissionGuard('family.view')],
        loadComponent: () => import('./pages/families/families-list').then((m) => m.FamiliesListPage),
      },
      { path: 'admin/usuarios', canActivate: [permissionGuard('user.manage')], loadComponent: () => import('./pages/admin/users-admin').then(m => m.UsersAdminPage) },
      { path: 'admin/auditoria', canActivate: [permissionGuard('audit.view')], loadComponent: () => import('./pages/admin/audit').then(m => m.AuditPage) },
      // ---- Módulo de Dízimos ----
      {
        path: 'dizimos/coletas',
        canActivate: [permissionGuard('dizimos.coleta.operar')],
        loadComponent: () => import('./pages/dizimos/coletas-list').then((m) => m.ColetasListPage),
      },
      {
        path: 'dizimos/coletas/:id',
        canActivate: [permissionGuard('dizimos.coleta.operar')],
        loadComponent: () => import('./pages/dizimos/coleta-lancamento').then((m) => m.ColetaLancamentoPage),
      },
      {
        path: 'dizimos/alertas',
        canActivate: [permissionGuard('dizimos.alertas.manage')],
        loadComponent: () => import('./pages/dizimos/pastoral-alerts').then((m) => m.PastoralAlertsPage),
      },
      {
        path: 'dizimos/membros/:id/historico',
        canActivate: [permissionGuard('dizimos.historico_individual.view')],
        loadComponent: () => import('./pages/dizimos/membro-historico').then((m) => m.MembroHistoricoPage),
      },
      {
        path: 'dizimos/diaconato',
        canActivate: [permissionGuard('dizimos.diaconato.atender')],
        loadComponent: () => import('./pages/dizimos/diaconato-solicitacoes').then((m) => m.DiaconatoSolicitacoesPage),
      },
      {
        path: 'dizimos/config',
        canActivate: [permissionGuard('dizimos.config.manage')],
        loadComponent: () => import('./pages/dizimos/dizimos-config').then((m) => m.DizimosConfigPage),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
