import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { FinancialService } from '../../core/financial.service';
import { AuthService } from '../../core/auth.service';
import { FinancialAccount } from '../../core/models';

@Component({
  selector: 'app-accounts-list',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    ButtonModule,
    DialogModule,
    InputTextModule,
  ],
  templateUrl: './accounts-list.html',
})
export class AccountsListPage implements OnInit {
  private financialService = inject(FinancialService);
  auth = inject(AuthService);

  accounts = signal<FinancialAccount[]>([]);
  loading = signal<boolean>(false);

  showModal = signal<boolean>(false);
  isEditing = signal<boolean>(false);
  editingId: number | null = null;

  form = {
    name: '',
    account_type: 'corrente' as 'caixa' | 'corrente' | 'poupanca' | 'aplicacao',
    bank_name: '',
    agency: '',
    account_number: '',
    initial_balance: 0,
    notes: '',
  };

  ngOnInit(): void {
    this.loadAccounts();
  }

  loadAccounts(): void {
    this.loading.set(true);
    this.financialService.getAccounts().subscribe({
      next: (accs) => {
        this.accounts.set(accs);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  openCreateModal(): void {
    this.isEditing.set(false);
    this.editingId = null;
    this.form = {
      name: '',
      account_type: 'corrente',
      bank_name: '',
      agency: '',
      account_number: '',
      initial_balance: 0,
      notes: '',
    };
    this.showModal.set(true);
  }

  openEditModal(acc: FinancialAccount): void {
    this.isEditing.set(true);
    this.editingId = acc.id;
    this.form = {
      name: acc.name,
      account_type: acc.account_type,
      bank_name: acc.bank_name || '',
      agency: acc.agency || '',
      account_number: acc.account_number || '',
      initial_balance: Number(acc.initial_balance),
      notes: acc.notes || '',
    };
    this.showModal.set(true);
  }

  saveAccount(): void {
    if (!this.form.name) return;

    const req$ = this.isEditing() && this.editingId
      ? this.financialService.updateAccount(this.editingId, this.form)
      : this.financialService.createAccount(this.form);

    req$.subscribe({
      next: () => {
        this.showModal.set(false);
        this.loadAccounts();
      },
      error: (err) => alert(err.error?.message || 'Erro ao salvar conta.'),
    });
  }

  recalculate(acc: FinancialAccount): void {
    this.financialService.recalculateAccount(acc.id).subscribe({
      next: (res) => {
        alert(res.message);
        this.loadAccounts();
      },
      error: (err) => alert(err.error?.message || 'Erro ao recalcular.'),
    });
  }

  deleteAccount(acc: FinancialAccount): void {
    if (!confirm(`Deseja realmente desativar ou excluir a conta "${acc.name}"?`)) return;

    this.financialService.deleteAccount(acc.id).subscribe({
      next: () => this.loadAccounts(),
      error: (err) => alert(err.error?.message || 'Erro ao excluir conta.'),
    });
  }
}
