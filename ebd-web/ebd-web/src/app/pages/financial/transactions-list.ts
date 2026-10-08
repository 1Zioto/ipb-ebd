import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { TagModule } from 'primeng/tag';
import { MessageModule } from 'primeng/message';
import { SelectModule } from 'primeng/select';
import { FinancialService } from '../../core/financial.service';
import { AuthService } from '../../core/auth.service';
import {
  FinancialAccount,
  FinancialCategory,
  FinancialCostCenter,
  FinancialSummary,
  FinancialTransaction,
} from '../../core/models';

@Component({
  selector: 'app-financial-transactions',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    ButtonModule,
    TableModule,
    DialogModule,
    InputTextModule,
    TextareaModule,
    TagModule,
    MessageModule,
    SelectModule,
  ],
  templateUrl: './transactions-list.html',
})
export class FinancialTransactionsPage implements OnInit {
  private financialService = inject(FinancialService);
  auth = inject(AuthService);

  transactions = signal<FinancialTransaction[]>([]);
  accounts = signal<FinancialAccount[]>([]);
  categories = signal<FinancialCategory[]>([]);
  costCenters = signal<FinancialCostCenter[]>([]);
  summary = signal<FinancialSummary | null>(null);

  loading = signal<boolean>(false);
  saving = signal<boolean>(false);
  errorMessage = signal<string | null>(null);
  showModal = signal<boolean>(false);
  isEditing = signal<boolean>(false);
  editingId: number | null = null;

  // Filtros
  selectedYear = new Date().getFullYear();
  selectedMonth = new Date().getMonth() + 1;
  filterType = '';
  filterStatus = '';
  filterAccountId: number | null = null;
  filterCostCenterId: number | null = null;
  filterCategoryId: number | null = null;
  searchTerm = '';

  // Meses e Anos
  months = [
    { label: 'Janeiro', value: 1 },
    { label: 'Fevereiro', value: 2 },
    { label: 'Março', value: 3 },
    { label: 'Abril', value: 4 },
    { label: 'Maio', value: 5 },
    { label: 'Junho', value: 6 },
    { label: 'Julho', value: 7 },
    { label: 'Agosto', value: 8 },
    { label: 'Setembro', value: 9 },
    { label: 'Outubro', value: 10 },
    { label: 'Novembro', value: 11 },
    { label: 'Dezembro', value: 12 },
  ];
  years: number[] = [2024, 2025, 2026, 2027];

  // Formulário Modal
  form = {
    type: 'despesa' as 'receita' | 'despesa' | 'transferencia',
    date: new Date().toISOString().substring(0, 10),
    competency_date: new Date().toISOString().substring(0, 10),
    amount: null as number | null,
    description: '',
    entity_name: '',
    financial_account_id: null as number | null,
    destination_account_id: null as number | null,
    financial_category_id: null as number | null,
    financial_cost_center_id: null as number | null,
    payment_method: 'pix' as 'pix' | 'ted_doc' | 'dinheiro' | 'boleto' | 'cartao_debito' | 'cartao_credito' | 'cheque' | 'outro',
    document_number: '',
    status: 'pago' as 'pago' | 'pendente',
    notes: '',
  };

  ngOnInit(): void {
    this.loadDropdowns();
    this.loadData();
  }

  loadDropdowns(): void {
    this.financialService.getAccounts().subscribe({
      next: (accs) => this.accounts.set(accs),
      error: (err) => console.error('Erro ao carregar contas:', err),
    });
    this.financialService.getCategories().subscribe({
      next: (cats) => this.categories.set(cats),
      error: (err) => console.error('Erro ao carregar categorias:', err),
    });
    this.financialService.getCostCenters().subscribe({
      next: (ccs) => this.costCenters.set(ccs),
      error: (err) => console.error('Erro ao carregar centros de custo:', err),
    });
  }

  loadData(): void {
    this.loading.set(true);
    this.errorMessage.set(null);

    this.financialService
      .getSummary(this.selectedYear, this.selectedMonth)
      .subscribe({
        next: (s) => this.summary.set(s),
        error: (err) => console.error('Erro ao carregar resumo financeiro:', err),
      });

    this.financialService
      .getTransactions({
        year: this.selectedYear,
        month: this.selectedMonth,
        type: this.filterType || undefined,
        status: this.filterStatus || undefined,
        account_id: this.filterAccountId || undefined,
        cost_center_id: this.filterCostCenterId || undefined,
        category_id: this.filterCategoryId || undefined,
        search: this.searchTerm || undefined,
      })
      .subscribe({
        next: (res) => {
          this.transactions.set(res.data);
          this.loading.set(false);
        },
        error: (err) => {
          this.errorMessage.set(err.error?.message || 'Erro ao carregar movimentações.');
          this.loading.set(false);
        },
      });
  }

  openCreateModal(type: 'receita' | 'despesa' | 'transferencia' = 'despesa'): void {
    this.isEditing.set(false);
    this.editingId = null;
    this.errorMessage.set(null);

    const firstAccount = this.accounts().find((a) => a.is_active);

    this.form = {
      type,
      date: new Date().toISOString().substring(0, 10),
      competency_date: new Date().toISOString().substring(0, 10),
      amount: null,
      description: '',
      entity_name: '',
      financial_account_id: firstAccount ? firstAccount.id : null,
      destination_account_id: null,
      financial_category_id: null,
      financial_cost_center_id: null,
      payment_method: 'pix',
      document_number: '',
      status: 'pago',
      notes: '',
    };

    this.showModal.set(true);
  }

  openEditModal(tx: FinancialTransaction): void {
    this.isEditing.set(true);
    this.editingId = tx.id;
    this.errorMessage.set(null);

    this.form = {
      type: tx.type,
      date: tx.date ? tx.date.substring(0, 10) : new Date().toISOString().substring(0, 10),
      competency_date: tx.competency_date ? tx.competency_date.substring(0, 10) : '',
      amount: Number(tx.amount),
      description: tx.description,
      entity_name: tx.entity_name || '',
      financial_account_id: tx.financial_account_id,
      destination_account_id: tx.destination_account_id || null,
      financial_category_id: tx.financial_category_id || null,
      financial_cost_center_id: tx.financial_cost_center_id || null,
      payment_method: tx.payment_method,
      document_number: tx.document_number || '',
      status: tx.status as 'pago' | 'pendente',
      notes: tx.notes || '',
    };

    this.showModal.set(true);
  }

  closeModal(): void {
    this.showModal.set(false);
  }

  saveTransaction(): void {
    if (!this.form.amount || this.form.amount <= 0 || !this.form.description || !this.form.financial_account_id) {
      this.errorMessage.set('Preencha os campos obrigatórios (Valor, Descrição e Conta).');
      return;
    }

    if (this.form.type === 'transferencia' && (!this.form.destination_account_id || this.form.destination_account_id === this.form.financial_account_id)) {
      this.errorMessage.set('Selecione uma conta de destino diferente da conta de origem.');
      return;
    }

    this.saving.set(true);
    this.errorMessage.set(null);

    const payload: Partial<FinancialTransaction> = {
      type: this.form.type,
      date: this.form.date,
      competency_date: this.form.competency_date || this.form.date,
      amount: this.form.amount,
      description: this.form.description,
      entity_name: this.form.entity_name || undefined,
      financial_account_id: this.form.financial_account_id,
      destination_account_id: this.form.destination_account_id || undefined,
      financial_category_id: this.form.financial_category_id || undefined,
      financial_cost_center_id: this.form.financial_cost_center_id || undefined,
      payment_method: this.form.payment_method,
      document_number: this.form.document_number || undefined,
      status: this.form.status,
      notes: this.form.notes || undefined,
    };

    const request$ = this.isEditing() && this.editingId
      ? this.financialService.updateTransaction(this.editingId, payload)
      : this.financialService.createTransaction(payload);

    request$.subscribe({
      next: () => {
        this.saving.set(false);
        this.closeModal();
        this.loadData();
      },
      error: (err) => {
        this.saving.set(false);
        this.errorMessage.set(err.error?.message || 'Erro ao salvar lançamento.');
      },
    });
  }

  deleteTransaction(tx: FinancialTransaction): void {
    if (!confirm(`Deseja realmente excluir o lançamento "${tx.description}"?`)) return;

    this.financialService.deleteTransaction(tx.id).subscribe({
      next: () => {
        this.loadData();
      },
      error: (err) => {
        alert(err.error?.message || 'Erro ao excluir lançamento.');
      },
    });
  }

  get filteredCategories(): FinancialCategory[] {
    if (this.form.type === 'transferencia') return [];
    return this.categories().filter((c) => c.type === this.form.type);
  }
}
