import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.html',
  styleUrl: './login.scss',
})
export class LoginPage {
  private auth = inject(AuthService);
  private router = inject(Router);

  isRegisterMode = signal(false);

  // Campos de Login
  username = signal('');
  password = signal('');

  // Campos de Cadastro da Nova Igreja
  churchName = signal('');
  shortName = signal('');
  type = signal('igreja');
  city = signal('');
  state = signal('');
  superiorCode = signal('');
  adminName = signal('');
  adminUsername = signal('');
  adminEmail = signal('');
  regPassword = signal('');
  confirmPassword = signal('');

  loading = signal(false);
  error = signal<string | null>(null);
  successMsg = signal<string | null>(null);

  toggleMode(): void {
    this.isRegisterMode.set(!this.isRegisterMode());
    this.error.set(null);
    this.successMsg.set(null);
  }

  async submitLogin() {
    this.error.set(null);
    this.loading.set(true);
    try {
      await this.auth.login(this.username(), this.password());
      this.router.navigate(['/']);
    } catch (e: any) {
      const msg = e?.error?.errors?.username?.[0] || e?.error?.message || 'Falha no login.';
      this.error.set(msg);
    } finally {
      this.loading.set(false);
    }
  }

  async submitRegister() {
    this.error.set(null);

    if (this.regPassword() !== this.confirmPassword()) {
      this.error.set('As senhas digitadas não coincidem.');
      return;
    }

    this.loading.set(true);
    try {
      const payload = {
        church_name: this.churchName(),
        short_name: this.shortName(),
        type: this.type(),
        city: this.city(),
        state: this.state(),
        superior_code: this.superiorCode(),
        admin_name: this.adminName(),
        admin_username: this.adminUsername(),
        admin_email: this.adminEmail(),
        password: this.regPassword(),
      };

      const res = await this.auth.registerChurch(payload);
      this.successMsg.set(`Igreja "${res.institution.name}" cadastrada com sucesso! Código gerado: ${res.institution.code}`);
      
      // Redireciona automaticamente após cadastrar
      setTimeout(() => {
        this.router.navigate(['/']);
      }, 1500);
    } catch (e: any) {
      const msg = e?.error?.message || e?.error?.errors?.admin_username?.[0] || 'Erro ao cadastrar igreja.';
      this.error.set(msg);
    } finally {
      this.loading.set(false);
    }
  }
}
