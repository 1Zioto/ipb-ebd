import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../environments/environment';
import { AuthUser, LoginResponse } from './models';

const TOKEN_KEY = 'ebd_token';
const USER_KEY = 'ebd_user';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);

  private _user = signal<AuthUser | null>(this.readStoredUser());
  readonly user = this._user.asReadonly();
  readonly isAuthenticated = computed(() => !!this._user() && !!this.token());

  token(): string | null {
    return localStorage.getItem(TOKEN_KEY);
  }

  private readStoredUser(): AuthUser | null {
    const raw = localStorage.getItem(USER_KEY);
    return raw ? (JSON.parse(raw) as AuthUser) : null;
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
    localStorage.removeItem('ipb_super_admin_mode');
    this._user.set(null);
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
    return username === 'superadmin' || email === 'superadmin@ipb.org.br' || username === 'master';
  });

  /**
   * Central Super Admin e privilégios de parametrização são exclusivos do Usuário Master.
   */
  readonly isSuperAdmin = computed(() => {
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
    if (this.isSuperAdmin()) return true;
    const u = this._user();
    if (!u) return false;
    return u.is_programmer || u.permissions.includes(permission) || u.permissions.includes('*');
  }
}
