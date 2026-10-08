import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { TextareaModule } from 'primeng/textarea';
import { TagModule } from 'primeng/tag';
import { FinancialService } from '../../core/financial.service';
import { AuthService } from '../../core/auth.service';
import {
  FinancialLedger,
  FinancialTrialBalance,
} from '../../core/models';

@Component({
  selector: 'app-accounting-report',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    ButtonModule,
    TableModule,
    DialogModule,
    TextareaModule,
    TagModule,
  ],
  templateUrl: './accounting-report.html',
})
export class AccountingReportPage implements OnInit {
  private financialService = inject(FinancialService);
  auth = inject(AuthService);

  ledger = signal<FinancialLedger | null>(null);
  trialBalance = signal<FinancialTrialBalance | null>(null);

  loading = signal<boolean>(false);
  closingLoading = signal<boolean>(false);
  errorMessage = signal<string | null>(null);
  activeTab: 'ledger' | 'categories' | 'costCenters' = 'ledger';

  // Período
  selectedYear = new Date().getFullYear();
  selectedMonth = new Date().getMonth() + 1;

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

  // Fechamento de Mês Modal
  showCloseModal = signal<boolean>(false);
  closeNotes = '';

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.loading.set(true);
    this.errorMessage.set(null);

    this.financialService
      .getLedger({ year: this.selectedYear, month: this.selectedMonth })
      .subscribe({
        next: (res) => {
          this.ledger.set(res);
          this.loading.set(false);
        },
        error: (err) => {
          this.errorMessage.set(err.error?.message || 'Erro ao carregar livro caixa.');
          this.loading.set(false);
        },
      });

    this.financialService
      .getTrialBalance(this.selectedYear, this.selectedMonth)
      .subscribe({
        next: (res) => this.trialBalance.set(res),
        error: (err) => console.error('Erro ao carregar balancete:', err),
      });
  }

  exportCsv(): void {
    const url = this.financialService.getExportCsvUrl(this.selectedYear, this.selectedMonth);
    window.open(url, '_blank');
  }

  printReport(): void {
    window.print();
  }

  openCloseMonthModal(): void {
    this.closeNotes = '';
    this.showCloseModal.set(true);
  }

  confirmCloseMonth(): void {
    this.closingLoading.set(true);
    this.financialService
      .closeMonth(this.selectedYear, this.selectedMonth, this.closeNotes)
      .subscribe({
        next: () => {
          this.closingLoading.set(false);
          this.showCloseModal.set(false);
          this.loadData();
        },
        error: (err) => {
          this.closingLoading.set(false);
          alert(err.error?.message || 'Erro ao fechar mês contábil.');
        },
      });
  }

  reopenMonth(): void {
    if (!confirm(`Deseja realmente reabrir o mês ${this.selectedMonth}/${this.selectedYear} para novos lançamentos?`)) return;

    this.closingLoading.set(true);
    this.financialService
      .reopenMonth(this.selectedYear, this.selectedMonth)
      .subscribe({
        next: () => {
          this.closingLoading.set(false);
          this.loadData();
        },
        error: (err) => {
          this.closingLoading.set(false);
          alert(err.error?.message || 'Erro ao reabrir mês contábil.');
        },
      });
  }

  get currentMonthLabel(): string {
    const m = this.months.find((item) => item.value === this.selectedMonth);
    return m ? m.label : String(this.selectedMonth);
  }
}
