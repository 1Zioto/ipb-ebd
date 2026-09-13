import { Component, inject, signal } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../core/auth.service';
import { ResponsiveService } from '../core/responsive.service';
import { ThemeService } from '../core/theme.service';
import { InstitutionContextBanner } from './institution-context-banner';
import { ToastComponent } from './toast.component';

@Component({
  selector: 'app-shell',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, InstitutionContextBanner, ToastComponent],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
})
export class Shell {
  private auth = inject(AuthService);
  responsive = inject(ResponsiveService);
  theme = inject(ThemeService);
  user = this.auth.user;
  mobileMenuOpen = signal(false);

  nav = [
    { path: '/dashboard', label: 'Dashboard EBD', icon: '🏠', perm: 'person.view' },
    { path: '/instituicoes/arvore', label: 'Estrutura Institucional', icon: '🌳', perm: 'institution.tree.view' },
    { path: '/instituicoes', label: 'Instituições', icon: '🏢', perm: 'institution.view' },
    { path: '/pessoas', label: 'Pessoas', icon: '👤', perm: 'person.view' },
    { path: '/familias', label: 'Famílias', icon: '🏡', perm: 'family.view' },
    { path: '/classes', label: 'Classes', icon: '📚', perm: 'class.view' },
    { path: '/calendario', label: 'Calendário', icon: '📅', perm: 'event.view' },
    { path: '/escalas', label: 'Escalas', icon: '🗓️', perm: 'schedule.view' },
    { path: '/relatorios', label: 'Relatórios EBD', icon: '📊', perm: 'report.view' },
    { path: '/admin/usuarios', label: 'Usuários', icon: '👥', perm: 'user.manage' },
    { path: '/admin/auditoria', label: 'Auditoria', icon: '🔎', perm: 'audit.view' },
    { path: '/dizimos/coletas', label: 'Coletas de Dízimos', icon: '🧺', perm: 'dizimos.coleta.operar' },
    { path: '/dizimos/alertas', label: 'Alertas Pastorais', icon: '🔔', perm: 'dizimos.alertas.manage' },
    { path: '/dizimos/diaconato', label: 'Fila Diaconato', icon: '🤝', perm: 'dizimos.diaconato.atender' },
    { path: '/dizimos/config', label: 'Config. Dízimos', icon: '⚙️', perm: 'dizimos.config.manage' },
  ];

  visibleNav() {
    return this.nav.filter((n) => this.auth.can(n.perm));
  }

  openMobileMenu() { this.mobileMenuOpen.set(true); }
  closeMobileMenu() { this.mobileMenuOpen.set(false); }

  initials(): string {
    const n = this.user()?.name?.trim() || '';
    const parts = n.split(/\s+/);
    return ((parts[0]?.[0] || '') + (parts.length > 1 ? parts[parts.length - 1][0] : '')).toUpperCase();
  }

  logout() { this.auth.logout(); }
}
