import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { AuthUser, Paginated } from './models';

export interface RoleAdmin { id: number; name: string; slug: string; description: string; permissions: PermissionAdmin[]; }
export interface PermissionAdmin { id: number; name: string; slug: string; }

@Injectable({ providedIn: 'root' })
export class AdminService {
  private http = inject(HttpClient);
  private base = `${environment.apiUrl}/admin`;
  users(): Observable<Paginated<AuthUser>> { return this.http.get<Paginated<AuthUser>>(`${this.base}/users`); }
  roles(): Observable<RoleAdmin[]> { return this.http.get<RoleAdmin[]>(`${this.base}/roles`); }
  permissions(): Observable<PermissionAdmin[]> { return this.http.get<PermissionAdmin[]>(`${this.base}/permissions`); }
  createUser(data: unknown): Observable<AuthUser> { return this.http.post<AuthUser>(`${this.base}/users`, data); }
  updateUser(id: number, data: unknown): Observable<AuthUser> { return this.http.patch<AuthUser>(`${this.base}/users/${id}`, data); }
  updateRole(id: number, permissionIds: number[]): Observable<RoleAdmin> { return this.http.put<RoleAdmin>(`${this.base}/roles/${id}`, { permission_ids: permissionIds }); }
}
