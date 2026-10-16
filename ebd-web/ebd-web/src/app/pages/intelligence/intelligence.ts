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
import { DialogModule } from 'primeng/dialog';
import { CheckboxModule } from 'primeng/checkbox';
import { firstValueFrom } from 'rxjs';
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

export interface ReportSectionOption {
  key: string;
  label: string;
  icon: string;
  description: string;
}

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
    DialogModule,
    CheckboxModule,
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

  // Modal de Configuração do Relatório Oficial (PDF)
  showReportModal = signal<boolean>(false);
  isGeneratingPdf = signal<boolean>(false);

  availableReportSections: ReportSectionOption[] = [
    { key: 'overview', label: 'Visão Geral', icon: '🏛️', description: 'Indicadores Vitais, Membresia e Perfil Etário' },
    { key: 'members', label: 'Membros da Congregação', icon: '👥', description: 'Relação Nominal dos Membros Arrolados e Situação Eclesiástica' },
    { key: 'demographics', label: 'Demografia', icon: '📊', description: 'Faixas Etárias Detalhadas, Estado Civil e Aniversariantes' },
    { key: 'movements', label: 'Movimentação do Rol', icon: '📈', description: 'Evolução Anual, Entradas vs Saídas e Modos de Recepção' },
    { key: 'ecclesiastical', label: 'Vida Eclesiástica', icon: '⛪', description: 'Tempo de Membresia no Rol, Batismos e Profissões de Fé' },
    { key: 'families', label: 'Famílias & Geografia', icon: '👨‍👩‍👧‍👦', description: 'Distribuição dos Núcleos Familiares e Concentração Geográfica' },
    { key: 'ebd', label: 'Escola Dominical', icon: '📖', description: 'Frequência Média Mensal e Desempenho por Turmas' },
    { key: 'societies', label: 'Sociedades Internas', icon: '🤝', description: 'Sócios Arrolados em UCP, UPA, UMP, SAF e UPH' },
    { key: 'quality', label: 'Qualidade Cadastral', icon: '📋', description: 'Auditoria de Registros Pendentes e Inconsistências' },
  ];

  selectedSections = signal<{ [key: string]: boolean }>({
    overview: true,
    members: true,
    demographics: true,
    movements: true,
    ecclesiastical: true,
    families: true,
    ebd: true,
    societies: true,
    quality: true,
  });

  reportChartImages = signal<{ [key: string]: string }>({});

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
    // Carrega antecipadamente o resumo executivo para garantir que o relatório para impressão esteja sempre pronto
    this.intelligenceService.getOverview(this.selectedYear(), undefined, this.consolidated()).subscribe({
      next: (res) => this.overviewData.set(res),
      error: () => {},
    });
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

  setConsolidated(val: boolean): void {
    if (this.consolidated() !== val) {
      this.consolidated.set(val);
      this.loadCurrentTab();
    }
  }

  toggleConsolidated(): void {
    this.consolidated.update((v) => !v);
    this.loadCurrentTab();
  }

  openPrintModal(): void {
    this.showReportModal.set(true);
  }

  toggleAllSections(select: boolean): void {
    const updated: { [key: string]: boolean } = {};
    for (const sec of this.availableReportSections) {
      updated[sec.key] = select;
    }
    this.selectedSections.set(updated);
  }

  toggleSection(key: string): void {
    this.selectedSections.update((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
  }

  hasAtLeastOneSectionSelected(): boolean {
    return Object.values(this.selectedSections()).some((v) => v);
  }

  private createOffscreenChartImage(config: any, width = 720, height = 300): string {
    try {
      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext('2d');
      if (!ctx) return '';

      const chartConfig = {
        ...config,
        options: {
          ...config.options,
          responsive: false,
          animation: false,
        },
      };

      const chart = new Chart(ctx, chartConfig);
      const dataUrl = chart.toBase64Image('image/png', 1);
      chart.destroy();
      return dataUrl;
    } catch (err) {
      console.warn('Erro ao gerar imagem de gráfico offscreen:', err);
      return '';
    }
  }

  private generateAllSelectedChartImages(): { [key: string]: string } {
    const images: { [key: string]: string } = {};
    const selected = this.selectedSections();

    // 1. Visão Geral
    if (selected['overview']) {
      const data = this.overviewData();
      if (data) {
        images['canonical'] = this.createOffscreenChartImage({
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
            plugins: {
              legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 10 } } },
            },
          },
        }, 340, 240);

        images['ageOverview'] = this.createOffscreenChartImage({
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
                borderRadius: 4,
              },
            ],
          },
          options: {
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } },
          },
        }, 380, 240);
      }
    }

    // 2. Demografia
    if (selected['demographics']) {
      const data = this.demographicsData();
      if (data) {
        images['faixasDet'] = this.createOffscreenChartImage({
          type: 'bar',
          data: {
            labels: data.faixas_etarias.labels,
            datasets: [
              {
                label: 'Pessoas',
                data: data.faixas_etarias.data,
                backgroundColor: 'rgba(14, 165, 233, 0.85)',
                borderColor: '#0284c7',
                borderRadius: 4,
              },
            ],
          },
          options: {
            indexAxis: 'y',
            plugins: { legend: { display: false } },
            scales: { x: { beginAtZero: true } },
          },
        }, 350, 240);

        images['estadoCivil'] = this.createOffscreenChartImage({
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
            plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, font: { size: 9 } } } },
          },
        }, 350, 240);

        images['aniversarios'] = this.createOffscreenChartImage({
          type: 'bar',
          data: {
            labels: data.aniversarios_mes.labels,
            datasets: [
              {
                label: 'Aniversariantes',
                data: data.aniversarios_mes.data,
                backgroundColor: 'rgba(245, 158, 11, 0.85)',
                borderColor: '#d97706',
                borderRadius: 4,
              },
            ],
          },
          options: {
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } },
          },
        }, 720, 200);
      }
    }

    // 3. Movimentação do Rol
    if (selected['movements']) {
      const data = this.movementsData();
      if (data) {
        images['evolucaoAnual'] = this.createOffscreenChartImage({
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
                borderWidth: 2,
                tension: 0.2,
              },
            ],
          },
          options: {
            plugins: { legend: { position: 'top', labels: { boxWidth: 10, font: { size: 9 } } } },
            scales: { y: { beginAtZero: true } },
          },
        }, 720, 220);

        images['admissoesMes'] = this.createOffscreenChartImage({
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
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } },
          },
        }, 350, 200);

        images['tiposRecepcao'] = this.createOffscreenChartImage({
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
            plugins: { legend: { position: 'right', labels: { boxWidth: 10, font: { size: 9 } } } },
          },
        }, 350, 200);
      }
    }

    // 4. Vida Eclesiástica
    if (selected['ecclesiastical']) {
      const data = this.ecclesiasticalData();
      if (data) {
        images['tempoMemb'] = this.createOffscreenChartImage({
          type: 'bar',
          data: {
            labels: data.tempo_membresia.labels,
            datasets: [
              {
                label: 'Membros',
                data: data.tempo_membresia.data,
                backgroundColor: 'rgba(4, 120, 87, 0.85)',
                borderColor: '#047857',
                borderRadius: 4,
              },
            ],
          },
          options: {
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } },
          },
        }, 350, 220);

        images['sacramentos'] = this.createOffscreenChartImage({
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
            plugins: { legend: { position: 'top', labels: { boxWidth: 10, font: { size: 9 } } } },
            scales: { y: { beginAtZero: true } },
          },
        }, 350, 220);
      }
    }

    // 5. Famílias & Geografia
    if (selected['families']) {
      const data = this.familiesGeoData();
      if (data) {
        images['tamanhosFam'] = this.createOffscreenChartImage({
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
            plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, font: { size: 9 } } } },
          },
        }, 350, 220);

        images['topBairros'] = this.createOffscreenChartImage({
          type: 'bar',
          data: {
            labels: data.top_bairros.labels,
            datasets: [
              {
                label: 'Famílias',
                data: data.top_bairros.data,
                backgroundColor: 'rgba(99, 102, 241, 0.85)',
                borderRadius: 4,
              },
            ],
          },
          options: {
            indexAxis: 'y',
            plugins: { legend: { display: false } },
            scales: { x: { beginAtZero: true } },
          },
        }, 350, 220);
      }
    }

    // 6. Escola Dominical
    if (selected['ebd']) {
      const data = this.ebdData();
      if (data) {
        images['freqEbd'] = this.createOffscreenChartImage({
          type: 'line',
          data: {
            labels: data.frequencia_mensal.labels,
            datasets: [
              {
                label: 'Taxa (%)',
                data: data.frequencia_mensal.taxas,
                borderColor: '#047857',
                backgroundColor: 'rgba(4, 120, 87, 0.1)',
                fill: true,
                tension: 0.2,
                borderWidth: 2,
              },
            ],
          },
          options: {
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true, max: 100 } },
          },
        }, 350, 220);

        images['classesEbd'] = this.createOffscreenChartImage({
          type: 'bar',
          data: {
            labels: data.classes.map((c) => c.name),
            datasets: [
              {
                label: 'Taxa (%)',
                data: data.classes.map((c) => c.rate),
                backgroundColor: 'rgba(16, 185, 129, 0.85)',
                borderRadius: 4,
              },
            ],
          },
          options: {
            indexAxis: 'y',
            plugins: { legend: { display: false } },
            scales: { x: { beginAtZero: true, max: 100 } },
          },
        }, 350, 220);
      }
    }

    // 7. Sociedades Internas
    if (selected['societies']) {
      const data = this.societiesData();
      if (data && data.grafico.labels.length > 0) {
        images['sociedades'] = this.createOffscreenChartImage({
          type: 'bar',
          data: {
            labels: data.grafico.labels,
            datasets: [
              {
                label: 'Sócios Inscritos',
                data: data.grafico.data,
                backgroundColor: ['#ec4899', '#0284c7', '#f59e0b', '#8b5cf6', '#10b981'],
                borderRadius: 4,
              },
            ],
          },
          options: {
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } },
          },
        }, 720, 220);
      }
    }

    return images;
  }

  async prepareAndGeneratePdf(): Promise<void> {
    if (!this.hasAtLeastOneSectionSelected()) return;

    this.isGeneratingPdf.set(true);

    try {
      const selected = this.selectedSections();
      const promises: Promise<any>[] = [];

      // Carrega os dados pendentes para as seções selecionadas
      if (selected['overview'] && !this.overviewData()) {
        promises.push(
          firstValueFrom(this.intelligenceService.getOverview(this.selectedYear(), undefined, this.consolidated()))
            .then((res) => this.overviewData.set(res))
            .catch(() => {})
        );
      }

      if (selected['members'] && this.membersData().length === 0) {
        promises.push(
          firstValueFrom(this.intelligenceService.getMembersList({ consolidated: this.consolidated() }))
            .then((res) => {
              this.membersData.set(res.members);
              this.membersTotal.set(res.total);
            })
            .catch(() => {})
        );
      }

      if (selected['demographics'] && !this.demographicsData()) {
        promises.push(
          firstValueFrom(this.intelligenceService.getDemographics())
            .then((res) => this.demographicsData.set(res))
            .catch(() => {})
        );
      }

      if (selected['movements'] && !this.movementsData()) {
        promises.push(
          firstValueFrom(this.intelligenceService.getMovements(this.selectedYear()))
            .then((res) => this.movementsData.set(res))
            .catch(() => {})
        );
      }

      if (selected['ecclesiastical'] && !this.ecclesiasticalData()) {
        promises.push(
          firstValueFrom(this.intelligenceService.getEcclesiasticalLife())
            .then((res) => this.ecclesiasticalData.set(res))
            .catch(() => {})
        );
      }

      if (selected['families'] && !this.familiesGeoData()) {
        promises.push(
          firstValueFrom(this.intelligenceService.getFamiliesGeo())
            .then((res) => this.familiesGeoData.set(res))
            .catch(() => {})
        );
      }

      if (selected['ebd'] && !this.ebdData()) {
        promises.push(
          firstValueFrom(this.intelligenceService.getEbdAnalytics(this.selectedYear()))
            .then((res) => this.ebdData.set(res))
            .catch(() => {})
        );
      }

      if (selected['societies'] && !this.societiesData()) {
        promises.push(
          firstValueFrom(this.intelligenceService.getSocietiesAnalytics())
            .then((res) => this.societiesData.set(res))
            .catch(() => {})
        );
      }

      if (selected['quality'] && !this.dataQualityData()) {
        promises.push(
          firstValueFrom(this.intelligenceService.getDataQuality())
            .then((res) => this.dataQualityData.set(res))
            .catch(() => {})
        );
      }

      if (promises.length > 0) {
        await Promise.all(promises);
      }

      // Gera imagens de todos os gráficos selecionados
      const images = this.generateAllSelectedChartImages();
      this.reportChartImages.set(images);

      // Fecha o diálogo de configuração
      this.showReportModal.set(false);

      // Aguarda o ciclo de renderização do Angular para atualizar as tags <img> do modelo
      setTimeout(async () => {
        await this.pdfSvc.gerarPdfEmNovaAba(
          'relatorio-congregacao-pdf',
          `relatorio-congregacao-${this.selectedYear()}`,
          `Relatório Executivo e Demográfico da Congregação — IPB ${this.selectedYear()}`
        );
        this.isGeneratingPdf.set(false);
      }, 300);
    } catch (err) {
      console.error('Falha ao preparar relatório em PDF:', err);
      this.isGeneratingPdf.set(false);
    }
  }

  printReport(): void {
    this.openPrintModal();
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

    // 1. Distribuição da Membresia
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
