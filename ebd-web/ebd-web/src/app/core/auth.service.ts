import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../environments/environment';
import { AuthUser, LoginResponse } from './models';

const TOKEN_KEY = 'ebd_token';
const USER_KEY = 'ebd_user';
const CONTEXT_KEY = 'ebd_active_context';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);

  private _user = signal<AuthUser | null>(this.readStoredUser());
  readonly user = this._user.asReadonly();
  readonly isAuthenticated = computed(() => !!this._user() && !!this.token());

  private _activeContext = signal<'membro' | 'admin'>(this.readStoredContext());
  readonly activeContext = this._activeContext.asReadonly();
  readonly isMemberContext = computed(() => this._activeContext() === 'membro');

  token(): string | null {
    return localStorage.getItem(TOKEN_KEY);
  }

  private readStoredUser(): AuthUser | null {
    const raw = localStorage.getItem(USER_KEY);
    return raw ? (JSON.parse(raw) as AuthUser) : null;
  }

  private readStoredContext(): 'membro' | 'admin' {
    const raw = localStorage.getItem(CONTEXT_KEY);
    return raw === 'admin' ? 'admin' : 'membro';
  }

  setContext(context: 'membro' | 'admin'): void {
    if (context === 'admin' && !this.hasManagementAccess()) {
      return;
    }
    localStorage.setItem(CONTEXT_KEY, context);
    this._activeContext.set(context);
  }

  async login(username: string, password: string): Promise<void> {
    const res = await firstValueFrom(
      this.http.post<LoginResponse>(`${environment.apiUrl}/auth/login`, { username, password })
    );
    localStorage.setItem(TOKEN_KEY, res.token);
    localStorage.setItem(USER_KEY, JSON.stringify(res.user));
    this._user.set(res.user);
  }

  async registerChurch(data: any): Promise<{ message: string; institution: { id: number; name: string; code: string } }> {
    const res = await firstValueFrom(
      this.http.post<LoginResponse & { message: string; institution: { id: number; name: string; code: string } }>(
        `${environment.apiUrl}/auth/register-church`,
        data
      )
    );
    if (res.token && res.user) {
      localStorage.setItem(TOKEN_KEY, res.token);
      localStorage.setItem(USER_KEY, JSON.stringify(res.user));
      this._user.set(res.user);
    }
    return res;
  }

  async refreshMe(): Promise<void> {
    try {
      const res = await firstValueFrom(
        this.http.get<{ data: AuthUser }>(`${environment.apiUrl}/auth/me`)
      );
      localStorage.setItem(USER_KEY, JSON.stringify(res.data));
      this._user.set(res.data);
    } catch {
      this.clearSession();
    }
  }

  async logout(): Promise<void> {
    try {
      await firstValueFrom(this.http.post(`${environment.apiUrl}/auth/logout`, {}));
    } catch { /* ignora */ }
    this.clearSession();
    this.router.navigate(['/login']);
  }

  clearSession(): void {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    localStorage.removeItem(CONTEXT_KEY);
    localStorage.removeItem('ipb_super_admin_mode');
    this._user.set(null);
    this._activeContext.set('membro');
  }

  /**
   * Identifica exclusivamente o Usuário Master do sistema (superadmin).
   * Apenas este perfil tem visualização e acesso à Central Super Admin.
   */
  readonly isMasterUser = computed(() => {
    const u = this._user();
    if (!u) return false;
    const username = (u.username || '').toLowerCase().trim();
    const email = (u.email || '').toLowerCase().trim();
    return (
      username === 'superadmin' ||
      email === 'superadmin@ipb.org.br' ||
      username === 'master' ||
      email === 'douglaszioto@gmail.com' ||
      !!u.is_programmer
    );
  });

  /**
   * Verifica se o usuário autenticado possui papéis ou permissões de gestão (oficial/diretoria).
   */
  readonly hasManagementAccess = computed(() => {
    const u = this._user();
    if (!u) return false;
    if (this.isMasterUser()) return true;
    const managementRoles = [
      'admin', 'pastor', 'presbitero', 'diacono', 'superintendente',
      'professor', 'tesoureiro', 'secretario', 'conselho', 'diretoria', 'programador'
    ];
    const roles = u.roles || [];
    const hasRole = roles.some(r => managementRoles.includes(r.toLowerCase()));
    const hasPerm = !!(u.permissions && u.permissions.length > 0);
    return hasRole || hasPerm;
  });

  /**
   * Central Super Admin e privilégios de parametrização são exclusivos do Usuário Master.
   * Quando o usuário estiver no contexto da Área do Membro, o modo Super Admin fica inativo.
   */
  readonly isSuperAdmin = computed(() => {
    if (this.isMemberContext()) return false;
    return this.isMasterUser();
  });

  setSuperAdminMode(active: boolean): void {
    if (!this.isMasterUser()) {
      localStorage.removeItem('ipb_super_admin_mode');
      return;
    }
    if (active) {
      localStorage.setItem('ipb_super_admin_mode', 'true');
    } else {
      localStorage.removeItem('ipb_super_admin_mode');
    }
  }

  can(permission: string): boolean {
    // Quando estiver na Área do Membro, nenhuma permissão administrativa é concedida
    if (this.isMemberContext()) {
      return false;
    }
    if (this.isSuperAdmin()) return true;
    const u = this._user();
    if (!u) return false;
    return u.is_programmer || u.permissions.includes(permission) || u.permissions.includes('*');
  }
}
