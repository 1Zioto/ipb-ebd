import { CommonModule } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AdminService, PermissionAdmin, RoleAdmin } from '../../core/admin.service';
import { AuthUser } from '../../core/models';

@Component({ selector: 'app-users-admin', standalone: true, imports: [CommonModule, FormsModule], templateUrl: './users-admin.html', styleUrl: './users-admin.scss' })
export class UsersAdminPage implements OnInit {
  private service = inject(AdminService);
  users = signal<AuthUser[]>([]); roles = signal<RoleAdmin[]>([]); permissions = signal<PermissionAdmin[]>([]);
  loading = signal(true); saving = signal(false); error = signal<string | null>(null); showForm = signal(false);
  roleEditing = signal<RoleAdmin | null>(null); rolePermissionIds = new Set<number>();
  form = { name: '', username: '', email: '', password: '', role_ids: [] as number[], is_active: true };
  ngOnInit() { this.reload(); }
  reload() { this.loading.set(true); Promise.all([this.service.users().toPromise(), this.service.roles().toPromise(), this.service.permissions().toPromise()]).then(([u,r,p]) => { this.users.set(u?.data ?? []); this.roles.set(r ?? []); this.permissions.set(p ?? []); this.loading.set(false); }).catch(e => { this.error.set(e.error?.message ?? 'Falha ao carregar administração.'); this.loading.set(false); }); }
  openNew() { this.form = { name:'', username:'', email:'', password:'', role_ids:[], is_active:true }; this.error.set(null); this.showForm.set(true); }
  toggleRole(id:number) { this.form.role_ids = this.form.role_ids.includes(id) ? this.form.role_ids.filter(x=>x!==id) : [...this.form.role_ids,id]; }
  saveUser() { if (!this.form.name || !this.form.username || this.form.password.length < 8 || !this.form.role_ids.length) return; this.saving.set(true); this.service.createUser(this.form).subscribe({next:()=>{this.showForm.set(false);this.saving.set(false);this.reload();},error:e=>{this.error.set(this.message(e));this.saving.set(false);}}); }
  toggleActive(u:AuthUser) { this.service.updateUser(u.id,{is_active:!u.is_active}).subscribe({next:()=>this.reload(),error:e=>this.error.set(this.message(e))}); }
  editRole(r:RoleAdmin) { this.roleEditing.set(r); this.rolePermissionIds = new Set(r.permissions.map(p=>p.id)); }
  togglePermission(id:number) { this.rolePermissionIds.has(id) ? this.rolePermissionIds.delete(id) : this.rolePermissionIds.add(id); }
  saveRole() { const role=this.roleEditing(); if(!role)return; this.saving.set(true); this.service.updateRole(role.id,[...this.rolePermissionIds]).subscribe({next:()=>{this.roleEditing.set(null);this.saving.set(false);this.reload();},error:e=>{this.error.set(this.message(e));this.saving.set(false);}}); }
  private message(e:any):string { const errors=e.error?.errors; return errors ? Object.values(errors).flat().join(' ') : (e.error?.message ?? 'Operação não concluída.'); }
}
