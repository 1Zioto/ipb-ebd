import { CommonModule } from '@angular/common';
import {
  Component,
  OnInit,
  AfterViewInit,
  OnDestroy,
  inject,
  signal,
  ElementRef,
  ViewChild,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { ProgressBarModule } from 'primeng/progressbar';
import { InputTextModule } from 'primeng/inputtext';
import { Chart } from 'chart.js/auto';
import {
  IntelligenceService,
  OverviewMetrics,
  DemographicsData,
  MovementsData,
  EcclesiasticalLifeData,
  FamiliesGeoData,
  EbdAnalyticsData,
  SocietiesAnalyticsData,
  DataQualityData,
  CongregationMember,
} from '../../core/intelligence.service';
import { AuthService } from '../../core/auth.service';
import { PdfService } from '../../core/pdf.service';

type IntelligenceTab =
  | 'overview'
  | 'demographics'
  | 'movements'
  | 'ecclesiastical'
  | 'families'
  | 'ebd'
  | 'societies'
  | 'quality'
  | 'members';

@Component({
  selector: 'app-intelligence',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    TableModule,
    TagModule,
    TooltipModule,
    ProgressBarModule,
    InputTextModule,
  ],
  templateUrl: './intelligence.html',
})
export class IntelligencePage implements OnInit, AfterViewInit, OnDestroy {
  private intelligenceService = inject(IntelligenceService);
  private pdfSvc = inject(PdfService);
  auth = inject(AuthService);

  // Filtros Globais
  selectedYear = signal<number>(2026);
  availableYears = [2024, 2025, 2026, 2027];
  consolidated = signal<boolean>(false);
  activeTab = signal<IntelligenceTab>('overview');
  loading = signal<boolean>(true);

  // Estados de Dados
  overviewData = signal<OverviewMetrics | null>(null);
  demographicsData = signal<DemographicsData | null>(null);
  movementsData = signal<MovementsData | null>(null);
  ecclesiasticalData = signal<EcclesiasticalLifeData | null>(null);
  familiesGeoData = signal<FamiliesGeoData | null>(null);
  ebdData = signal<EbdAnalyticsData | null>(null);
  societiesData = signal<SocietiesAnalyticsData | null>(null);
  dataQualityData = signal<DataQualityData | null>(null);

  // Membros da Congregação
  membersData = signal<CongregationMember[]>([]);
  membersTotal = signal<number>(0);
  membersLoading = signal<boolean>(false);
  memberSearchQuery = signal<string>('');
  memberCanonicalFilter = signal<string>('');
  memberActiveFilter = signal<string>('all');

  // Canvas ViewChilds para Gráficos Chart.js
  @ViewChild('canonicalCanvas') canonicalCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('ageOverviewCanvas') ageOverviewCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('faixasDetalhadasCanvas') faixasDetalhadasCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('estadoCivilCanvas') estadoCivilCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('aniversariosCanvas') aniversariosCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('evolucaoAnualCanvas') evolucaoAnualCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('admissoesMesCanvas') admissoesMesCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('tiposRecepcaoCanvas') tiposRecepcaoCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('tempoMembresiaCanvas') tempoMembresiaCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('sacramentosCanvas') sacramentosCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('tamanhosFamiliaCanvas') tamanhosFamiliaCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('topBairrosCanvas') topBairrosCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('frequenciaMensalCanvas') frequenciaMensalCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('classesEbdCanvas') classesEbdCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('sociedadesCanvas') sociedadesCanvas?: ElementRef<HTMLCanvasElement>;

  // Instâncias ativas dos gráficos
  private charts: { [key: string]: any } = {};

  ngOnInit(): void {
    this.loadCurrentTab();
  }

  ngAfterViewInit(): void {
    // Renderização dos gráficos após montagem do DOM
  }

  ngOnDestroy(): void {
    this.destroyAllCharts();
  }

  setTab(tab: IntelligenceTab): void {
    this.activeTab.set(tab);
    this.loadCurrentTab();
  }

  onYearChange(): void {
    this.loadCurrentTab();
  }

  toggleConsolidated(): void {
    this.consolidated.update((v) => !v);
    this.loadCurrentTab();
  }

  printReport(): void {
    if (!this.overviewData()) {
      this.intelligenceService.getOverview(this.selectedYear(), undefined, this.consolidated()).subscribe((res) => {
        this.overviewData.set(res);
        setTimeout(() => {
          this.pdfSvc.gerarPdfEmNovaAba(
            'relatorio-congregacao-pdf',
            `relatorio-congregacao-${this.selectedYear()}`,
            `Relatório Executivo e Demográfico da Congregação — IPB ${this.selectedYear()}`
          );
        }, 150);
      });
      return;
    }

    this.pdfSvc.gerarPdfEmNovaAba(
      'relatorio-congregacao-pdf',
      `relatorio-congregacao-${this.selectedYear()}`,
      `Relatório Executivo e Demográfico da Congregação — IPB ${this.selectedYear()}`
    );
  }

  exportMembersToExcel(): void {
    const canonical = this.memberCanonicalFilter() || undefined;
    const active = this.memberActiveFilter() === 'all' ? undefined : this.memberActiveFilter() === 'active';
    this.intelligenceService.downloadMembersExcel(undefined, this.consolidated(), canonical, active);
  }

  loadMembers(): void {
    this.membersLoading.set(true);
    this.intelligenceService
      .getMembersList({
        search: this.memberSearchQuery() || undefined,
        canonical_status: this.memberCanonicalFilter() || undefined,
        is_active: this.memberActiveFilter() === 'all' ? undefined : this.memberActiveFilter() === 'active',
        consolidated: this.consolidated(),
      })
      .subscribe({
        next: (res) => {
          this.membersData.set(res.members);
          this.membersTotal.set(res.total);
          this.membersLoading.set(false);
          this.loading.set(false);
        },
        error: () => {
          this.membersLoading.set(false);
          this.loading.set(false);
        },
      });
  }

  loadCurrentTab(): void {
    this.loading.set(true);
    const tab = this.activeTab();
    const ano = this.selectedYear();
    const cons = this.consolidated();

    switch (tab) {
      case 'overview':
        this.intelligenceService.getOverview(ano, undefined, cons).subscribe({
          next: (res) => {
            this.overviewData.set(res);
            this.loading.set(false);
            this.scheduleChartRender(() => this.renderOverviewCharts(), this.canonicalCanvas);
          },
          error: () => this.loading.set(false),
        });
        break;

      case 'demographics':
        this.intelligenceService.getDemographics().subscribe({
          next: (res) => {
            this.demographicsData.set(res);
            this.loading.set(false);
            this.scheduleChartRender(() => this.renderDemographicsCharts(), this.faixasDetalhadasCanvas);
          },
          error: () => this.loading.set(false),
        });
        break;

      case 'movements':
        this.intelligenceService.getMovements(ano).subscribe({
          next: (res) => {
            this.movementsData.set(res);
            this.loading.set(false);
            this.scheduleChartRender(() => this.renderMovementsCharts(), this.evolucaoAnualCanvas);
          },
          error: () => this.loading.set(false),
        });
        break;

      case 'ecclesiastical':
        this.intelligenceService.getEcclesiasticalLife().subscribe({
          next: (res) => {
            this.ecclesiasticalData.set(res);
            this.loading.set(false);
            this.scheduleChartRender(() => this.renderEcclesiasticalCharts(), this.tempoMembresiaCanvas);
          },
          error: () => this.loading.set(false),
        });
        break;

      case 'families':
        this.intelligenceService.getFamiliesGeo().subscribe({
          next: (res) => {
            this.familiesGeoData.set(res);
            this.loading.set(false);
            this.scheduleChartRender(() => this.renderFamiliesCharts(), this.tamanhosFamiliaCanvas);
          },
          error: () => this.loading.set(false),
        });
        break;

      case 'ebd':
        this.intelligenceService.getEbdAnalytics(ano).subscribe({
          next: (res) => {
            this.ebdData.set(res);
            this.loading.set(false);
            this.scheduleChartRender(() => this.renderEbdCharts(), this.frequenciaMensalCanvas);
          },
          error: () => this.loading.set(false),
        });
        break;

      case 'societies':
        this.intelligenceService.getSocietiesAnalytics().subscribe({
          next: (res) => {
            this.societiesData.set(res);
            this.loading.set(false);
            this.scheduleChartRender(() => this.renderSocietiesCharts(), this.sociedadesCanvas);
          },
          error: () => this.loading.set(false),
        });
        break;

      case 'quality':
        this.intelligenceService.getDataQuality().subscribe({
          next: (res) => {
            this.dataQualityData.set(res);
            this.loading.set(false);
          },
          error: () => this.loading.set(false),
        });
        break;

      case 'members':
        this.loadMembers();
        break;
    }
  }

  private scheduleChartRender(renderFn: () => void, canvasRef?: ElementRef<HTMLCanvasElement>): void {
    setTimeout(() => {
      if (canvasRef && !canvasRef.nativeElement) {
        setTimeout(renderFn, 150);
      } else {
        renderFn();
      }
    }, 120);
  }

  private destroyAllCharts(): void {
    Object.keys(this.charts).forEach((k) => {
      this.charts[k]?.destroy();
    });
    this.charts = {};
  }

  private renderOverviewCharts(): void {
    const data = this.overviewData();
    if (!data) return;

    // 1. Rosca Canônica
    if (this.canonicalCanvas?.nativeElement) {
      this.charts['canonical']?.destroy();
      const ctx = this.canonicalCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['canonical'] = new Chart(ctx, {
          type: 'doughnut',
          data: {
            labels: data.canonical_chart.labels,
            datasets: [
              {
                data: data.canonical_chart.data,
                backgroundColor: ['#047857', '#3b82f6', '#f59e0b', '#94a3b8'],
                borderWidth: 2,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: 'bottom' } },
          },
        });
      }
    }

    // 2. Faixas Etárias Overview
    if (this.ageOverviewCanvas?.nativeElement) {
      this.charts['ageOverview']?.destroy();
      const ctx = this.ageOverviewCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['ageOverview'] = new Chart(ctx, {
          type: 'bar',
          data: {
            labels: ['Infantil (0-11)', 'Adolescentes (12-17)', 'Jovens (18-35)', 'Adultos (36-59)', '60+ Anos'],
            datasets: [
              {
                label: 'Membros',
                data: [
                  data.age_distribution.infantil,
                  data.age_distribution.adolescentes,
                  data.age_distribution.jovens,
                  data.age_distribution.adultos,
                  data.age_distribution.melhor_idade,
                ],
                backgroundColor: 'rgba(4, 120, 87, 0.85)',
                borderColor: '#047857',
                borderRadius: 6,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } },
          },
        });
      }
    }
  }

  private renderDemographicsCharts(): void {
    const data = this.demographicsData();
    if (!data) return;

    // Faixas detalhadas
    if (this.faixasDetalhadasCanvas?.nativeElement) {
      this.charts['faixasDet']?.destroy();
      const ctx = this.faixasDetalhadasCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['faixasDet'] = new Chart(ctx, {
          type: 'bar',
          data: {
            labels: data.faixas_etarias.labels,
            datasets: [
              {
                label: 'Pessoas',
                data: data.faixas_etarias.data,
                backgroundColor: 'rgba(14, 165, 233, 0.85)',
                borderColor: '#0284c7',
                borderRadius: 6,
              },
            ],
          },
          options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { x: { beginAtZero: true } },
          },
        });
      }
    }

    // Estado Civil
    if (this.estadoCivilCanvas?.nativeElement) {
      this.charts['estadoCivil']?.destroy();
      const ctx = this.estadoCivilCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['estadoCivil'] = new Chart(ctx, {
          type: 'pie',
          data: {
            labels: data.estado_civil.labels,
            datasets: [
              {
                data: data.estado_civil.data,
                backgroundColor: ['#10b981', '#6366f1', '#f59e0b', '#ec4899', '#94a3b8'],
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: 'bottom' } },
          },
        });
      }
    }

    // Aniversários por Mês
    if (this.aniversariosCanvas?.nativeElement) {
      this.charts['aniversarios']?.destroy();
      const ctx = this.aniversariosCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['aniversarios'] = new Chart(ctx, {
          type: 'bar',
          data: {
            labels: data.aniversarios_mes.labels,
            datasets: [
              {
                label: 'Aniversariantes',
                data: data.aniversarios_mes.data,
                backgroundColor: 'rgba(245, 158, 11, 0.85)',
                borderColor: '#d97706',
                borderRadius: 6,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } },
          },
        });
      }
    }
  }

  private renderMovementsCharts(): void {
    const data = this.movementsData();
    if (!data) return;

    // Evolução Anual
    if (this.evolucaoAnualCanvas?.nativeElement) {
      this.charts['evolucaoAnual']?.destroy();
      const ctx = this.evolucaoAnualCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['evolucaoAnual'] = new Chart(ctx, {
          type: 'bar',
          data: {
            labels: data.evolucao_anual.anos.map(String),
            datasets: [
              {
                label: 'Admissões',
                data: data.evolucao_anual.admissoes,
                backgroundColor: 'rgba(16, 185, 129, 0.85)',
                borderRadius: 4,
              },
              {
                label: 'Saídas',
                data: data.evolucao_anual.saidas,
                backgroundColor: 'rgba(239, 68, 68, 0.85)',
                borderRadius: 4,
              },
              {
                label: 'Saldo Líquido',
                type: 'line',
                data: data.evolucao_anual.saldo,
                borderColor: '#0284c7',
                borderWidth: 3,
                tension: 0.3,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: 'top' } },
            scales: { y: { beginAtZero: true } },
          },
        });
      }
    }

    // Admissões por Mês
    if (this.admissoesMesCanvas?.nativeElement) {
      this.charts['adminkaMes']?.destroy();
      const ctx = this.admissoesMesCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['adminkaMes'] = new Chart(ctx, {
          type: 'bar',
          data: {
            labels: data.admissoes_mes.labels,
            datasets: [
              {
                label: 'Admissões',
                data: data.admissoes_mes.data,
                backgroundColor: '#047857',
                borderRadius: 4,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } },
          },
        });
      }
    }

    // Tipos de Recepção
    if (this.tiposRecepcaoCanvas?.nativeElement) {
      this.charts['tiposRecepcao']?.destroy();
      const ctx = this.tiposRecepcaoCanvas.nativeElement.getContext('2d');
      if (ctx && data.tipos_recepcao.labels.length > 0) {
        this.charts['tiposRecepcao'] = new Chart(ctx, {
          type: 'doughnut',
          data: {
            labels: data.tipos_recepcao.labels,
            datasets: [
              {
                data: data.tipos_recepcao.data,
                backgroundColor: ['#047857', '#0284c7', '#8b5cf6', '#f59e0b', '#ec4899', '#94a3b8'],
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: 'right' } },
          },
        });
      }
    }
  }

  private renderEcclesiasticalCharts(): void {
    const data = this.ecclesiasticalData();
    if (!data) return;

    // Tempo de Membresia
    if (this.tempoMembresiaCanvas?.nativeElement) {
      this.charts['tempoMemb']?.destroy();
      const ctx = this.tempoMembresiaCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['tempoMemb'] = new Chart(ctx, {
          type: 'bar',
          data: {
            labels: data.tempo_membresia.labels,
            datasets: [
              {
                label: 'Membros',
                data: data.tempo_membresia.data,
                backgroundColor: 'rgba(4, 120, 87, 0.85)',
                borderColor: '#047857',
                borderRadius: 6,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } },
          },
        });
      }
    }

    // Sacramentos (Batismos x Profissões)
    if (this.sacramentosCanvas?.nativeElement) {
      this.charts['sacramentos']?.destroy();
      const ctx = this.sacramentosCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['sacramentos'] = new Chart(ctx, {
          type: 'bar',
          data: {
            labels: data.sacramentos_historico.anos.map(String),
            datasets: [
              {
                label: 'Batismos',
                data: data.sacramentos_historico.batismos,
                backgroundColor: '#3b82f6',
                borderRadius: 4,
              },
              {
                label: 'Profissões de Fé',
                data: data.sacramentos_historico.profissoes,
                backgroundColor: '#10b981',
                borderRadius: 4,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: 'top' } },
            scales: { y: { beginAtZero: true } },
          },
        });
      }
    }
  }

  private renderFamiliesCharts(): void {
    const data = this.familiesGeoData();
    if (!data) return;

    // Tamanhos de Família
    if (this.tamanhosFamiliaCanvas?.nativeElement) {
      this.charts['tamanhosFam']?.destroy();
      const ctx = this.tamanhosFamiliaCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['tamanhosFam'] = new Chart(ctx, {
          type: 'doughnut',
          data: {
            labels: data.tamanhos_familia.labels,
            datasets: [
              {
                data: data.tamanhos_familia.data,
                backgroundColor: ['#0284c7', '#047857', '#f59e0b', '#ec4899', '#8b5cf6'],
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: 'bottom' } },
          },
        });
      }
    }

    // Top Bairros
    if (this.topBairrosCanvas?.nativeElement) {
      this.charts['topBairros']?.destroy();
      const ctx = this.topBairrosCanvas.nativeElement.getContext('2d');
      if (ctx && data.top_bairros.labels.length > 0) {
        this.charts['topBairros'] = new Chart(ctx, {
          type: 'bar',
          data: {
            labels: data.top_bairros.labels,
            datasets: [
              {
                label: 'Famílias',
                data: data.top_bairros.data,
                backgroundColor: 'rgba(99, 102, 241, 0.85)',
                borderRadius: 6,
              },
            ],
          },
          options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { x: { beginAtZero: true } },
          },
        });
      }
    }
  }

  private renderEbdCharts(): void {
    const data = this.ebdData();
    if (!data) return;

    // Frequência Mensal da EBD
    if (this.frequenciaMensalCanvas?.nativeElement) {
      this.charts['freqEbd']?.destroy();
      const ctx = this.frequenciaMensalCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['freqEbd'] = new Chart(ctx, {
          type: 'line',
          data: {
            labels: data.frequencia_mensal.labels,
            datasets: [
              {
                label: 'Taxa de Presença (%)',
                data: data.frequencia_mensal.taxas,
                borderColor: '#047857',
                backgroundColor: 'rgba(4, 120, 87, 0.1)',
                fill: true,
                tension: 0.3,
                borderWidth: 3,
                yAxisID: 'yRate',
              },
              {
                label: 'Presentes Totais',
                type: 'bar',
                data: data.frequencia_mensal.presentes,
                backgroundColor: 'rgba(14, 165, 233, 0.7)',
                borderRadius: 4,
                yAxisID: 'yCount',
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: 'top' } },
            scales: {
              yRate: {
                type: 'linear',
                position: 'right',
                min: 0,
                max: 100,
                ticks: { callback: (val) => `${val}%` },
              },
              yCount: {
                type: 'linear',
                position: 'left',
                beginAtZero: true,
              },
            },
          },
        });
      }
    }

    // Classes EBD (Taxa de Presença por Turma)
    if (this.classesEbdCanvas?.nativeElement) {
      this.charts['classesEbd']?.destroy();
      const ctx = this.classesEbdCanvas.nativeElement.getContext('2d');
      if (ctx && data.classes.length > 0) {
        this.charts['classesEbd'] = new Chart(ctx, {
          type: 'bar',
          data: {
            labels: data.classes.map((c) => c.name),
            datasets: [
              {
                label: 'Taxa de Presença (%)',
                data: data.classes.map((c) => c.rate),
                backgroundColor: 'rgba(16, 185, 129, 0.85)',
                borderRadius: 6,
              },
            ],
          },
          options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
              x: {
                min: 0,
                max: 100,
                ticks: { callback: (val) => `${val}%` },
              },
            },
          },
        });
      }
    }
  }

  private renderSocietiesCharts(): void {
    const data = this.societiesData();
    if (!data) return;

    if (this.sociedadesCanvas?.nativeElement && data.grafico.labels.length > 0) {
      this.charts['sociedades']?.destroy();
      const ctx = this.sociedadesCanvas.nativeElement.getContext('2d');
      if (ctx) {
        this.charts['sociedades'] = new Chart(ctx, {
          type: 'bar',
          data: {
            labels: data.grafico.labels,
            datasets: [
              {
                label: 'Sócios Inscritos',
                data: data.grafico.data,
                backgroundColor: ['#ec4899', '#0284c7', '#f59e0b', '#8b5cf6', '#10b981'],
                borderRadius: 6,
              },
            ],
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } },
          },
        });
      }
    }
  }
}
