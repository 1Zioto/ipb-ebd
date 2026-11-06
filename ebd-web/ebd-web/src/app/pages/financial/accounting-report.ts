import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { TextareaModule } from 'primeng/textarea';
import { InputTextModule } from 'primeng/inputtext';
import { TooltipModule } from 'primeng/tooltip';
import { TagModule } from 'primeng/tag';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { environment } from '@/environments/environment';
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
    InputTextModule,
    TooltipModule,
    TagModule,
    ToastModule,
  ],
  providers: [MessageService],
  templateUrl: './accounting-report.html',
})
export class AccountingReportPage implements OnInit {
  private http = inject(HttpClient);
  private msg = inject(MessageService);
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

  // Fechamento de Exercício Anual & Prestação de Contas
  exerciciosFechados = signal<any[]>([]);
  modalExerciciosAnuais = false;
  modalFecharExercicio = false;
  modalParecer = false;
  anoFechamento = new Date().getFullYear() - 1;
  dataFechamento = new Date().toISOString().split('T')[0];
  loadingFechamento = signal<boolean>(false);
  parecerTexto = '';
  exercicioSelecionado: any = null;

  ngOnInit(): void {
    this.loadData();
    this.carregarExercicios();
  }

  carregarExercicios(): void {
    this.http.get<any[]>(`${environment.apiUrl}/financial/annual-closings`).subscribe({
      next: (res) => this.exerciciosFechados.set(res || []),
      error: () => {},
    });
  }

  abrirModalExercicios(): void {
    this.carregarExercicios();
    this.modalExerciciosAnuais = true;
  }

  abrirModalNovoFechamento(): void {
    this.modalFecharExercicio = true;
  }

  executarFechamento(): void {
    this.loadingFechamento.set(true);
    const payload = {
      year: this.anoFechamento,
      closing_date: this.dataFechamento,
    };

    this.http.post<any>(`${environment.apiUrl}/financial/annual-closings/fechar-exercicio`, payload).subscribe({
      next: (res) => {
        this.loadingFechamento.set(false);
        this.modalFecharExercicio = false;
        this.msg.add({
          severity: 'success',
          summary: 'Exercício Fechado',
          detail: res.message || 'Snapshot anual gerado com sucesso.',
        });
        this.carregarExercicios();
      },
      error: (err) => {
        this.loadingFechamento.set(false);
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: err.error?.message || 'Falha ao encerrar exercício.',
        });
      },
    });
  }

  abrirModalParecer(ex: any): void {
    this.exercicioSelecionado = ex;
    this.parecerTexto = ex.conselho_parecer || '';
    this.modalParecer = true;
  }

  salvarParecer(): void {
    if (!this.exercicioSelecionado || !this.parecerTexto.trim()) {
      this.msg.add({
        severity: 'warn',
        summary: 'Atenção',
        detail: 'Digite o parecer oficial do Conselho / Exame de Contas.',
      });
      return;
    }

    const id = this.exercicioSelecionado.id;
    this.http.post<any>(`${environment.apiUrl}/financial/annual-closings/${id}/aprovar-conselho`, { parecer: this.parecerTexto }).subscribe({
      next: () => {
        this.msg.add({
          severity: 'success',
          summary: 'Parecer Registrado',
          detail: 'Exercício aprovado pelo Conselho da Igreja.',
        });
        this.modalParecer = false;
        this.carregarExercicios();
      },
      error: (err) => {
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: err.error?.message || 'Falha ao registrar parecer.',
        });
      },
    });
  }

  publicarParaMembros(ex: any): void {
    if (!ex || !ex.id) return;
    this.http.post<any>(`${environment.apiUrl}/financial/annual-closings/${ex.id}/publicar-membros`, {}).subscribe({
      next: () => {
        this.msg.add({
          severity: 'success',
          summary: 'Publicado!',
          detail: `Prestação de Contas de ${ex.year} agora está visível para os membros da igreja.`,
        });
        this.carregarExercicios();
      },
      error: (err) => {
        this.msg.add({
          severity: 'error',
          summary: 'Erro ao Publicar',
          detail: err.error?.message || 'Falha ao publicar prestação de contas.',
        });
      },
    });
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
