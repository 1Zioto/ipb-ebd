import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { TooltipModule } from 'primeng/tooltip';
import { ToastModule } from 'primeng/toast';
import { ProgressBarModule } from 'primeng/progressbar';
import { MessageService } from 'primeng/api';
import { FALLBACK_MEMBERS_LIST } from '../../../core/members-fallback.data';
import { CongregationMember } from '../../../core/intelligence.service';
import { ModelosCartasService } from '../../../core/modelos-cartas.service';
import { PdfService } from '../../../core/pdf.service';

export type ReportTabType = 'aniversariantes' | 'demografico' | 'financeiro' | 'patrimonio' | 'membros' | 'ebd';

export interface BirthdayItem {
  member: CongregationMember;
  day: number;
  month: number;
  ageTurning: number;
  phoneFormatted: string;
}

export interface PatrimonyItem {
  tombamento: string;
  nome: string;
  categoria: string;
  localizacao: string;
  estado: 'Excelente' | 'Bom' | 'Regular';
  valor: number;
}

@Component({
  selector: 'app-central-relatorios',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    TableModule,
    TagModule,
    DialogModule,
    TooltipModule,
    ToastModule,
    ProgressBarModule,
  ],
  providers: [MessageService],
  templateUrl: './central-relatorios.html',
  styleUrls: ['./central-relatorios.scss'],
})
export class CentralRelatoriosPage implements OnInit {
  private router = inject(Router);
  private msg = inject(MessageService);
  private letterheadService = inject(ModelosCartasService);
  private pdfSvc = inject(PdfService);

  readonly churchConfig = this.letterheadService.config;

  // Aba ativa inicial: ANIVERSARIANTES (conforme a imagem enviada pelo usuário)
  activeTab = signal<ReportTabType>('aniversariantes');

  // Membros cadastrados (76 membros)
  members = signal<CongregationMember[]>(FALLBACK_MEMBERS_LIST.members);

  // Mês atual (1 = Jan ... 12 = Dez)
  currentMonth = new Date().getMonth() + 1;
  selectedMonth = signal<number>(this.currentMonth);

  // Modal de Impressão de Relatório
  printModal = signal<boolean>(false);
  printReportTitle = signal<string>('Relatório Consolidado');

  // Meses com nomes
  readonly monthsList = [
    { num: 1, label: 'Janeiro', short: 'Jan' },
    { num: 2, label: 'Fevereiro', short: 'Fev' },
    { num: 3, label: 'Março', short: 'Mar' },
    { num: 4, label: 'Abril', short: 'Abr' },
    { num: 5, label: 'Maio', short: 'Mai' },
    { num: 6, label: 'Junho', short: 'Jun' },
    { num: 7, label: 'Julho', short: 'Jul' },
    { num: 8, label: 'Agosto', short: 'Ago' },
    { num: 9, label: 'Setembro', short: 'Set' },
    { num: 10, label: 'Outubro', short: 'Out' },
    { num: 11, label: 'Novembro', short: 'Nov' },
    { num: 12, label: 'Dezembro', short: 'Dez' },
  ];

  // 1. Processamento de Aniversariantes
  allBirthdays = computed<BirthdayItem[]>(() => {
    const list: BirthdayItem[] = [];
    const currentYear = new Date().getFullYear();

    for (const m of this.members()) {
      if (m.birth_date) {
        const parts = m.birth_date.split('-');
        if (parts.length === 3) {
          const birthYear = parseInt(parts[0], 10);
          const birthMonth = parseInt(parts[1], 10);
          const birthDay = parseInt(parts[2], 10);

          list.push({
            member: m,
            day: birthDay,
            month: birthMonth,
            ageTurning: currentYear - birthYear,
            phoneFormatted: m.phone || '(27) 99999-0000',
          });
        }
      }
    }
    return list;
  });

  // Aniversariantes do mês selecionado
  monthBirthdays = computed(() => {
    const mNum = this.selectedMonth();
    return this.allBirthdays()
      .filter((b) => b.month === mNum)
      .sort((a, b) => a.day - b.day);
  });

  // Contagem de aniversariantes por mês
  birthdaysCountByMonth = computed<Record<number, number>>(() => {
    const counts: Record<number, number> = {};
    for (let i = 1; i <= 12; i++) counts[i] = 0;
    for (const b of this.allBirthdays()) {
      if (counts[b.month] !== undefined) counts[b.month]++;
    }
    return counts;
  });

  // 2. Dados Demográficos Consolidados
  demographics = computed(() => {
    const mems = this.members();
    const total = mems.length;

    let criancas = 0; // 0-11
    let adolescentes = 0; // 12-17
    let jovens = 0; // 18-35
    let adultos = 0; // 36-59
    let idosos = 0; // 60+

    let casados = 0;
    let solteiros = 0;
    let viuvos = 0;
    let outrosCivil = 0;

    let comungantes = 0;
    let naoComungantes = 0;
    let sobDisciplina = 0;

    for (const m of mems) {
      const age = m.age || 0;
      if (age <= 11) criancas++;
      else if (age <= 17) adolescentes++;
      else if (age <= 35) jovens++;
      else if (age <= 59) adultos++;
      else idosos++;

      const civil = (m.marital_status || '').toLowerCase();
      if (civil.includes('casad')) casados++;
      else if (civil.includes('solteir')) solteiros++;
      else if (civil.includes('viuv')) viuvos++;
      else outrosCivil++;

      const st = (m.canonical_status || '').toLowerCase();
      if (st.includes('comungante') && !st.includes('nao')) comungantes++;
      else if (st.includes('nao') || st.includes('não')) naoComungantes++;
      else if (st.includes('disciplina')) sobDisciplina++;
      else comungantes++;
    }

    return {
      total,
      faixas: {
        criancas: { count: criancas, pct: Math.round((criancas / total) * 100) },
        adolescentes: { count: adolescentes, pct: Math.round((adolescentes / total) * 100) },
        jovens: { count: jovens, pct: Math.round((jovens / total) * 100) },
        adultos: { count: adultos, pct: Math.round((adultos / total) * 100) },
        idosos: { count: idosos, pct: Math.round((idosos / total) * 100) },
      },
      estadoCivil: {
        casados: { count: casados, pct: Math.round((casados / total) * 100) },
        solteiros: { count: solteiros, pct: Math.round((solteiros / total) * 100) },
        viuvos: { count: viuvos, pct: Math.round((viuvos / total) * 100) },
        outros: { count: outrosCivil, pct: Math.round((outrosCivil / total) * 100) },
      },
      condicaoEclesiastica: {
        comungantes: { count: comungantes, pct: Math.round((comungantes / total) * 100) },
        naoComungantes: { count: naoComungantes, pct: Math.round((naoComungantes / total) * 100) },
        sobDisciplina: { count: sobDisciplina, pct: Math.round((sobDisciplina / total) * 100) },
      },
    };
  });

  // 3. Dados Financeiros Realistas da Congregação
  financialData = signal({
    receitasTotal: 28450.0,
    despesasTotal: 19120.0,
    saldoMes: 9330.0,
    itensReceita: [
      { categoria: 'Dízimos Regulares dos Membros', valor: 22800.0, pct: 80 },
      { categoria: 'Ofertas Alçadas dos Cultos', valor: 4250.0, pct: 15 },
      { categoria: 'Ofertas Missionárias & Especiais', valor: 1400.0, pct: 5 },
    ],
    itensDespesa: [
      { categoria: 'Prebenda e Sustento Pastoral', valor: 7500.0, pct: 39 },
      { categoria: 'Manutenção, Água, Energia e Templo', valor: 6320.0, pct: 33 },
      { categoria: 'Cotas Conciliares IPB (Presbitério e Sínodo)', valor: 2800.0, pct: 15 },
      { categoria: 'Material de Educação Cristã & EBD', valor: 1500.0, pct: 8 },
      { categoria: 'Ação Social & Junta Diaconal', valor: 1000.0, pct: 5 },
    ],
  });

  // 4. Inventário de Bens Patrimoniais
  patrimonioList = signal<PatrimonyItem[]>([
    {
      tombamento: 'PAT-001',
      nome: 'Mesa de Som Digital Yamaha TF3 24 Canais',
      categoria: 'Som & Áudio',
      localizacao: 'Cabine de Sonoplastia - Templo',
      estado: 'Excelente',
      valor: 18500.0,
    },
    {
      tombamento: 'PAT-002',
      nome: 'Projetor Laser Epson PowerLite 4000 Lumens',
      categoria: 'Multimídia',
      localizacao: 'Nave do Templo Principal',
      estado: 'Excelente',
      valor: 8900.0,
    },
    {
      tombamento: 'PAT-003',
      nome: 'Piano Digital Casio Celviano AP-470',
      categoria: 'Instrumentos Musicais',
      localizacao: 'Plataforma do Altar - Templo',
      estado: 'Excelente',
      valor: 7800.0,
    },
    {
      tombamento: 'PAT-004',
      nome: 'Bateria Acústica Pearl Export Series Completa',
      categoria: 'Instrumentos Musicais',
      localizacao: 'Área Musical do Templo',
      estado: 'Bom',
      valor: 6500.0,
    },
    {
      tombamento: 'PAT-005',
      nome: 'Conjunto de 40 Bancos de Madeira Maciça Angelim',
      categoria: 'Mobiliário',
      localizacao: 'Nave do Templo',
      estado: 'Bom',
      valor: 32000.0,
    },
    {
      tombamento: 'PAT-006',
      nome: 'Ar Condicionado Split Inverter 60.000 BTUs',
      categoria: 'Climatização',
      localizacao: 'Templo Principal',
      estado: 'Excelente',
      valor: 11200.0,
    },
    {
      tombamento: 'PAT-007',
      nome: 'Geladeira Duplex Frost Free Brastemp 440L',
      categoria: 'Eletrodomésticos',
      localizacao: 'Cozinha Comunitária',
      estado: 'Bom',
      valor: 3800.0,
    },
    {
      tombamento: 'PAT-008',
      nome: 'Notebook Dell Inspiron Core i7 16GB RAM',
      categoria: 'Informática',
      localizacao: 'Secretaria e Conselho',
      estado: 'Excelente',
      valor: 5200.0,
    },
  ]);

  totalPatrimonioValor = computed(() => {
    return this.patrimonioList().reduce((acc, item) => acc + item.valor, 0);
  });

  ngOnInit(): void {
    // Inicialização pronta
  }

  // Alternar abas
  setTab(tab: ReportTabType): void {
    this.activeTab.set(tab);
  }

  // Selecionar mês de aniversariantes
  selectMonth(m: number): void {
    this.selectedMonth.set(m);
  }

  // Nome do mês selecionado
  getSelectedMonthName(): string {
    const item = this.monthsList.find((m) => m.num === this.selectedMonth());
    return item ? item.label : '';
  }

  // Felicitar aniversariante no WhatsApp
  felicitarWhatsApp(item: BirthdayItem): void {
    const church = this.churchConfig().churchName;
    const phoneRaw = item.phoneFormatted.replace(/\D/g, '');
    const cleanPhone = phoneRaw.startsWith('55') ? phoneRaw : `55${phoneRaw}`;

    const text = encodeURIComponent(
      `Graça e paz, prezado(a) irmão(ã) ${item.member.full_name}!\n\n` +
        `Em nome do Conselho e de toda a comunidade da ${church}, parabenizamos você pelo seu aniversário neste dia ${item.day} de ${this.getSelectedMonthName()}!\n\n` +
        `"O Senhor te abençoe e te guarde; o Senhor faça resplandecer o seu rosto sobre ti e tenha misericórdia de ti; o Senhor sobre ti levante o seu rosto e te dê a paz." (Números 6:24-26)\n\n` +
        `Parabéns pelos seus ${item.ageTurning} anos! Conte sempre com nossas orações.`
    );

    const url = `https://wa.me/${cleanPhone}?text=${text}`;
    window.open(url, '_blank');
  }

  // Emissão do relatório timbrado oficial em folha A4 com PdfService
  imprimirRelatorio(titulo: string): void {
    this.printReportTitle.set(titulo);
    setTimeout(() => {
      const slug = titulo
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-z0-9]/g, '-');
      this.pdfSvc.gerarPdfEmNovaAba(
        'central-relatorios-print-sheet',
        `relatorio-${slug}`,
        `${titulo} — IPB`
      );
    }, 120);
  }

  // Voltar para o painel principal
  voltarAoPainel(): void {
    this.router.navigate(['/dashboard']);
  }
}
