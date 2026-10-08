import { CommonModule } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { CheckboxModule } from 'primeng/checkbox';
import { MessageModule } from 'primeng/message';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { firstValueFrom } from 'rxjs';
import { AdminService, PermissionAdmin, RoleAdmin } from '../../core/admin.service';
import { AuthService } from '../../core/auth.service';
import { AuthUser } from '../../core/models';

@Component({
  selector: 'app-users-admin',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    TableModule,
    DialogModule,
    InputTextModule,
    CheckboxModule,
    MessageModule,
    TagModule,
    TooltipModule,
  ],
  templateUrl: './users-admin.html',
})
export class UsersAdminPage implements OnInit {
  private service = inject(AdminService);
  auth = inject(AuthService);

  users = signal<AuthUser[]>([]);
  roles = signal<RoleAdmin[]>([]);
  permissions = signal<PermissionAdmin[]>([]);

  loading = signal(true);
  saving = signal(false);
  deleting = signal(false);
  error = signal<string | null>(null);
  successMsg = signal<string | null>(null);

  showForm = signal(false);
  showDeleteDialog = signal(false);
  userEditing = signal<AuthUser | null>(null);
  userToDelete = signal<AuthUser | null>(null);

  roleEditing = signal<RoleAdmin | null>(null);
  rolePermissionIds = new Set<number>();

  form = {
    userId: null as number | null,
    name: '',
    username: '',
    email: '',
    password: '',
    role_ids: [] as number[],
    is_active: true,
  };

  ngOnInit() {
    this.reload();
  }

  reload() {
    this.loading.set(true);
    this.error.set(null);
    Promise.all([
      firstValueFrom(this.service.users()),
      firstValueFrom(this.service.roles()),
      firstValueFrom(this.service.permissions()),
    ])
      .then(([u, r, p]) => {
        this.users.set(u?.data ?? []);
        this.roles.set(r ?? []);
        this.permissions.set(p ?? []);
        this.loading.set(false);
      })
      .catch((e) => {
        this.error.set(e.error?.message ?? 'Falha ao carregar administração.');
        this.loading.set(false);
      });
  }

  openNew() {
    this.userEditing.set(null);
    this.form = {
      userId: null,
      name: '',
      username: '',
      email: '',
      password: '',
      role_ids: [],
      is_active: true,
    };
    this.error.set(null);
    this.successMsg.set(null);
    this.showForm.set(true);
  }

  openEdit(user: AuthUser) {
    this.userEditing.set(user);
    const matchedRoleIds =
      user.role_ids && user.role_ids.length > 0
        ? [...user.role_ids]
        : this.roles()
            .filter((r) => user.roles.includes(r.slug))
            .map((r) => r.id);

    this.form = {
      userId: user.id,
      name: user.name,
      username: user.username,
      email: user.email || '',
      password: '',
      role_ids: matchedRoleIds,
      is_active: user.is_active,
    };
    this.error.set(null);
    this.successMsg.set(null);
    this.showForm.set(true);
  }

  toggleRole(id: number) {
    this.form.role_ids = this.form.role_ids.includes(id)
      ? this.form.role_ids.filter((x) => x !== id)
      : [...this.form.role_ids, id];
  }

  saveUser() {
    if (!this.form.name.trim() || !this.form.username.trim()) {
      this.error.set('Preencha os campos obrigatórios (Nome e Login).');
      return;
    }
    if (!this.form.role_ids.length) {
      this.error.set('Selecione ao menos um papel para o usuário.');
      return;
    }

    const isEditing = !!this.form.userId;

    if (!isEditing && (!this.form.password || this.form.password.length < 8)) {
      this.error.set('A senha é obrigatória e deve possuir no mínimo 8 caracteres.');
      return;
    }

    if (isEditing && this.form.password && this.form.password.length < 8) {
      this.error.set('Caso informada, a nova senha deve possuir no mínimo 8 caracteres.');
      return;
    }

    this.saving.set(true);
    this.error.set(null);

    if (isEditing) {
      const payload: any = {
        name: this.form.name.trim(),
        username: this.form.username.trim(),
        email: this.form.email.trim() ? this.form.email.trim() : null,
        role_ids: this.form.role_ids,
        is_active: this.form.is_active,
      };
      if (this.form.password.trim()) {
        payload.password = this.form.password;
      }

      this.service.updateUser(this.form.userId!, payload).subscribe({
        next: () => {
          this.showForm.set(false);
          this.saving.set(false);
          this.successMsg.set('Usuário atualizado com sucesso.');
          this.reload();
        },
        error: (e) => {
          this.error.set(this.message(e));
          this.saving.set(false);
        },
      });
    } else {
      const payload = {
        name: this.form.name.trim(),
        username: this.form.username.trim(),
        email: this.form.email.trim() ? this.form.email.trim() : null,
        password: this.form.password,
        role_ids: this.form.role_ids,
        is_active: this.form.is_active,
      };

      this.service.createUser(payload).subscribe({
        next: () => {
          this.showForm.set(false);
          this.saving.set(false);
          this.successMsg.set('Usuário cadastrado com sucesso.');
          this.reload();
        },
        error: (e) => {
          this.error.set(this.message(e));
          this.saving.set(false);
        },
      });
    }
  }

  toggleActive(u: AuthUser) {
    if (u.id === this.auth.user()?.id) {
      this.error.set('Você não pode alterar o status do seu próprio usuário.');
      return;
    }
    this.service.updateUser(u.id, { is_active: !u.is_active }).subscribe({
      next: () => {
        this.successMsg.set(`Usuário ${u.name} ${!u.is_active ? 'ativado' : 'desativado'} com sucesso.`);
        this.reload();
      },
      error: (e) => this.error.set(this.message(e)),
    });
  }

  openDeleteConfirm(user: AuthUser) {
    if (user.id === this.auth.user()?.id) {
      this.error.set('Você não pode excluir seu próprio usuário logado.');
      return;
    }
    this.userToDelete.set(user);
    this.showDeleteDialog.set(true);
  }

  confirmDelete() {
    const user = this.userToDelete();
    if (!user) return;

    this.deleting.set(true);
    this.service.deleteUser(user.id).subscribe({
      next: () => {
        this.showDeleteDialog.set(false);
        this.userToDelete.set(null);
        this.deleting.set(false);
        this.successMsg.set(`Usuário "${user.name}" excluído com sucesso.`);
        this.reload();
      },
      error: (e) => {
        this.error.set(this.message(e));
        this.deleting.set(false);
      },
    });
  }

  getRoleBadgeSeverity(slug: string): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
    switch (slug) {
      case 'programador':
        return 'danger';
      case 'pastor':
        return 'warn';
      case 'superintendencia':
        return 'info';
      case 'professor':
        return 'success';
      default:
        return 'secondary';
    }
  }

  editRole(r: RoleAdmin) {
    this.roleEditing.set(r);
    this.rolePermissionIds = new Set(r.permissions.map((p) => p.id));
  }

  togglePermission(id: number) {
    this.rolePermissionIds.has(id)
      ? this.rolePermissionIds.delete(id)
      : this.rolePermissionIds.add(id);
  }

  saveRole() {
    const role = this.roleEditing();
    if (!role) return;
    this.saving.set(true);
    this.service.updateRole(role.id, [...this.rolePermissionIds]).subscribe({
      next: () => {
        this.roleEditing.set(null);
        this.saving.set(false);
        this.successMsg.set(`Permissões do papel ${role.name} atualizadas.`);
        this.reload();
      },
      error: (e) => {
        this.error.set(this.message(e));
        this.saving.set(false);
      },
    });
  }

  private message(e: any): string {
    const errors = e.error?.errors;
    return errors
      ? Object.values(errors).flat().join(' ')
      : e.error?.message ?? 'Operação não concluída.';
  }
}
