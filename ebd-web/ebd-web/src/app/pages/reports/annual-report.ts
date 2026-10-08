import { CommonModule } from '@angular/common';
import {
  Component,
  OnInit,
  AfterViewInit,
  OnDestroy,
  inject,
  signal,
  effect,
  ElementRef,
  ViewChild,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { ProgressBarModule } from 'primeng/progressbar';
import { Chart } from 'chart.js/auto';
import { EbdService } from '../../core/ebd.service';
import { AnnualReportSummary } from '../../core/models';

@Component({
  selector: 'app-annual-report',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    TableModule,
    TagModule,
    TooltipModule,
    ProgressBarModule,
  ],
  templateUrl: './annual-report.html',
  styleUrls: ['./annual-report.scss'],
})
export class AnnualReportPage implements OnInit, AfterViewInit, OnDestroy {
  private ebdService = inject(EbdService);

  @ViewChild('financialChartCanvas') financialCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('categoriesChartCanvas') categoriesCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('ebdMonthlyChartCanvas') ebdMonthlyCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('ebdClassesChartCanvas') ebdClassesCanvas?: ElementRef<HTMLCanvasElement>;

  selectedYear = signal<number>(2026);
  availableYears = [2024, 2025, 2026, 2027];

  reportData = signal<AnnualReportSummary | null>(null);
  loading = signal<boolean>(true);
  presentationMode = signal<boolean>(false);
  activeSection = signal<'geral' | 'ebd' | 'financeiro' | 'membresia'>('geral');

  // Instâncias dos gráficos para limpeza e re-render
  private financialChart?: any;
  private categoriesChart?: any;
  private ebdMonthlyChart?: any;
  private ebdClassesChart?: any;

  constructor() {
    // Efeito para re-renderizar gráficos quando os dados mudarem e a aba ativa for 'geral' ou 'ebd'/'financeiro'
    effect(() => {
      const data = this.reportData();
      const section = this.activeSection();
      if (data) {
        setTimeout(() => this.renderCharts(), 100);
      }
    });
  }

  ngOnInit(): void {
    this.fetchData();
  }

  ngAfterViewInit(): void {
    if (this.reportData()) {
      this.renderCharts();
    }
  }

  ngOnDestroy(): void {
    this.destroyCharts();
  }

  fetchData(): void {
    this.loading.set(true);
    this.ebdService.getAnnualReport(this.selectedYear()).subscribe({
      next: (res) => {
        this.reportData.set(res);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
      },
    });
  }

  onYearChange(year: number): void {
    this.selectedYear.set(year);
    this.fetchData();
  }

  togglePresentationMode(): void {
    this.presentationMode.update((v) => !v);
    setTimeout(() => this.renderCharts(), 200);
  }

  printReport(): void {
    window.print();
  }

  formatCurrency(value?: number): string {
    if (value === undefined || value === null) return 'R$ 0,00';
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(value);
  }

  formatPercent(value?: number): string {
    if (value === undefined || value === null) return '0%';
    return `${value.toFixed(1)}%`;
  }

  private destroyCharts(): void {
    this.financialChart?.destroy();
    this.categoriesChart?.destroy();
    this.ebdMonthlyChart?.destroy();
    this.ebdClassesChart?.destroy();
  }

  private renderCharts(): void {
    const data = this.reportData();
    if (!data) return;

    this.destroyCharts();

    // 1. Gráfico Financeiro Mensal (Receitas vs Despesas)
    if (this.financialCanvas?.nativeElement) {
      const ctx = this.financialCanvas.nativeElement.getContext('2d');
      if (ctx) {
        const labels = data.financial.monthly.map((m) => m.month_name);
        const revenues = data.financial.monthly.map((m) => m.revenue);
        const expenses = data.financial.monthly.map((m) => m.expense);

        this.financialChart = new Chart(ctx, {
          type: 'bar',
          data: {
            labels,
            datasets: [
              {
                label: 'Receitas / Entradas',
                data: revenues,
                backgroundColor: 'rgba(16, 185, 129, 0.85)',
                borderColor: '#10b981',
                borderRadius: 4,
              },
              {
                label: 'Despesas / Saídas',
                data: expenses,
                backgroundColor: 'rgba(239, 68, 68, 0.85)',
                borderColor: '#ef4444',
                borderRadius: 4,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { position: 'top' },
              tooltip: {
                callbacks: {
                  label: (context) => ` ${context.dataset.label}: ${this.formatCurrency(context.parsed.y)}`,
                },
              },
            },
            scales: {
              y: {
                beginAtZero: true,
                ticks: {
                  callback: (value) => `R$ ${Number(value).toLocaleString('pt-BR')}`,
                },
              },
            },
          },
        });
      }
    }

    // 2. Gráfico de Categorias de Despesas (Doughnut)
    if (this.categoriesCanvas?.nativeElement) {
      const ctx = this.categoriesCanvas.nativeElement.getContext('2d');
      if (ctx) {
        const topCategories = data.financial.categories_expense.slice(0, 6);
        const labels = topCategories.map((c) => c.name);
        const amounts = topCategories.map((c) => c.amount);

        const colors = [
          '#1e3a8a', // Azul Marinho
          '#0d9488', // Verde Petróleo
          '#f59e0b', // Âmbar / Ouro
          '#6366f1', // Índigo
          '#ec4899', // Rosa
          '#94a3b8', // Ardósia
        ];

        this.categoriesChart = new Chart(ctx, {
          type: 'doughnut',
          data: {
            labels,
            datasets: [
              {
                data: amounts,
                backgroundColor: colors.slice(0, topCategories.length),
                borderWidth: 2,
                borderColor: '#ffffff',
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { position: 'right' },
              tooltip: {
                callbacks: {
                  label: (context) => ` ${context.label}: ${this.formatCurrency(Number(context.raw))}`,
                },
              },
            },
          },
        });
      }
    }

    // 3. Gráfico de Frequência Mensal da EBD (Line)
    if (this.ebdMonthlyCanvas?.nativeElement) {
      const ctx = this.ebdMonthlyCanvas.nativeElement.getContext('2d');
      if (ctx) {
        const labels = data.ebd.monthly.map((m) => m.month_name);
        const rates = data.ebd.monthly.map((m) => m.rate);
        const presents = data.ebd.monthly.map((m) => m.present);

        this.ebdMonthlyChart = new Chart(ctx, {
          type: 'line',
          data: {
            labels,
            datasets: [
              {
                label: 'Taxa de Presença (%)',
                data: rates,
                borderColor: '#0284c7',
                backgroundColor: 'rgba(2, 132, 199, 0.15)',
                fill: true,
                tension: 0.35,
                pointRadius: 5,
                pointHoverRadius: 7,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { display: false },
              tooltip: {
                callbacks: {
                  label: (context) => ` Frequência: ${context.parsed.y}% (${presents[context.dataIndex]} presentes)`,
                },
              },
            },
            scales: {
              y: {
                min: 0,
                max: 100,
                ticks: {
                  callback: (value) => `${value}%`,
                },
              },
            },
          },
        });
      }
    }

    // 4. Gráfico de Frequência por Classe da EBD (Horizontal Bar)
    if (this.ebdClassesCanvas?.nativeElement) {
      const ctx = this.ebdClassesCanvas.nativeElement.getContext('2d');
      if (ctx) {
        const labels = data.ebd.classes.map((c) => c.name);
        const rates = data.ebd.classes.map((c) => c.attendance_rate);

        this.ebdClassesChart = new Chart(ctx, {
          type: 'bar',
          data: {
            labels,
            datasets: [
              {
                label: 'Frequência Média (%)',
                data: rates,
                backgroundColor: 'rgba(14, 165, 233, 0.8)',
                borderColor: '#0284c7',
                borderRadius: 4,
              },
            ],
          },
          options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { display: false },
              tooltip: {
                callbacks: {
                  label: (context) => ` Presença Média: ${context.parsed.x}%`,
                },
              },
            },
            scales: {
              x: {
                min: 0,
                max: 100,
                ticks: {
                  callback: (value) => `${value}%`,
                },
              },
            },
          },
        });
      }
    }
  }
}
