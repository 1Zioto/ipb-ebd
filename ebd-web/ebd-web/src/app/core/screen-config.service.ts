import { Injectable, signal, computed, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../environments/environment';

export interface ChurchInfo {
  id: number;
  name: string;
  short_name: string;
  cnpj?: string;
  city: string;
  state: string;
  presbiterio: string;
  sinodo: string;
  pastor_titular: string;
  total_membros: number;
  classes_ebd: number;
  status: 'Ativa' | 'Em Implantação' | 'Congregação';
  logo?: string;
}

export const BRAZILIAN_STATES = [
  { label: 'Acre (AC)', value: 'AC' },
  { label: 'Alagoas (AL)', value: 'AL' },
  { label: 'Amapá (AP)', value: 'AP' },
  { label: 'Amazonas (AM)', value: 'AM' },
  { label: 'Bahia (BA)', value: 'BA' },
  { label: 'Ceará (CE)', value: 'CE' },
  { label: 'Distrito Federal (DF)', value: 'DF' },
  { label: 'Espírito Santo (ES)', value: 'ES' },
  { label: 'Goiás (GO)', value: 'GO' },
  { label: 'Maranhão (MA)', value: 'MA' },
  { label: 'Mato Grosso (MT)', value: 'MT' },
  { label: 'Mato Grosso do Sul (MS)', value: 'MS' },
  { label: 'Minas Gerais (MG)', value: 'MG' },
  { label: 'Pará (PA)', value: 'PA' },
  { label: 'Paraíba (PB)', value: 'PB' },
  { label: 'Paraná (PR)', value: 'PR' },
  { label: 'Pernambuco (PE)', value: 'PE' },
  { label: 'Piauí (PI)', value: 'PI' },
  { label: 'Rio de Janeiro (RJ)', value: 'RJ' },
  { label: 'Rio Grande do Norte (RN)', value: 'RN' },
  { label: 'Rio Grande do Sul (RS)', value: 'RS' },
  { label: 'Rondônia (RO)', value: 'RO' },
  { label: 'Roraima (RR)', value: 'RR' },
  { label: 'Santa Catarina (SC)', value: 'SC' },
  { label: 'São Paulo (SP)', value: 'SP' },
  { label: 'Sergipe (SE)', value: 'SE' },
  { label: 'Tocantins (TO)', value: 'TO' },
];

export interface ScreenModuleDef {
  key: string;
  label: string;
  icon: string;
  group: string;
  description: string;
  route: string;
  defaultEnabled: boolean;
}

export const SYSTEM_SCREENS: ScreenModuleDef[] = [
  {
    key: 'dashboard',
    label: 'Tela de Boas-vindas',
    icon: 'pi pi-home',
    group: 'Visão Geral',
    description: 'Página inicial com boas-vindas, resumo do dia, versículo e atalhos operacionais rápidos.',
    route: '/dashboard',
    defaultEnabled: true,
  },
  {
    key: 'inteligencia',
    label: 'Dashboards e Informações da Congregação',
    icon: 'pi pi-chart-bar',
    group: 'Visão Geral',
    description: 'Painel executivo, demográfico, pastoral, estatísticas vitais, gráficos analíticos e exportação da membresia.',
    route: '/inteligencia',
    defaultEnabled: true,
  },
  {
    key: 'sociedades',
    label: 'Sociedades Internas (SAF, UPH, UMP, UPA, UCP)',
    icon: 'pi pi-id-card',
    group: 'Educação & Ministérios',
    description: 'Gestão das forças ativas, diretorias societárias e rol de sócios das sociedades internas.',
    route: '/sociedades',
    defaultEnabled: true,
  },
  {
    key: 'oficiais',
    label: 'Oficiais & Secretarias',
    icon: 'pi pi-shield',
    group: 'Secretaria & Membresia',
    description: 'Conselho da Igreja, Junta Diaconal, Secretarias ministeriais e gestão de equipes.',
    route: '/secretaria/oficiais-lideranca',
    defaultEnabled: true,
  },
  {
    key: 'membros',
    label: 'Rol de Membros (Ficha Cadastral)',
    icon: 'pi pi-address-book',
    group: 'Secretaria & Membresia',
    description: 'Assentamentos oficiais de membros comungantes, não-comungantes e fichas cadastrais completas.',
    route: '/secretaria/membros',
    defaultEnabled: true,
  },
  {
    key: 'pessoas',
    label: 'Pessoas Cadastradas',
    icon: 'pi pi-users',
    group: 'Secretaria & Membresia',
    description: 'Cadastro geral de pessoas, membros, congregados, visitantes e líderes.',
    route: '/pessoas',
    defaultEnabled: true,
  },
  {
    key: 'familias',
    label: 'Famílias & Núcleos',
    icon: 'pi pi-home',
    group: 'Secretaria & Membresia',
    description: 'Agrupamento familiar, chefes de família e parentesco dos membros.',
    route: '/familias',
    defaultEnabled: true,
  },
  {
    key: 'classes',
    label: 'Classes EBD & Chamada Dominical',
    icon: 'pi pi-book',
    group: 'Educação & Ministérios',
    description: 'Matrículas de alunos, revistas, marcação de presença e relatórios dominicais.',
    route: '/classes',
    defaultEnabled: true,
  },
  {
    key: 'calendario',
    label: 'Calendário de Eventos',
    icon: 'pi pi-calendar',
    group: 'Educação & Ministérios',
    description: 'Agenda oficial da igreja, cultos, reuniões e eventos dominicais.',
    route: '/calendario',
    defaultEnabled: true,
  },
  {
    key: 'escalas',
    label: 'Escalas de Serviço',
    icon: 'pi pi-list',
    group: 'Educação & Ministérios',
    description: 'Escalas de professores, dirigentes, sonoplastia e equipes de apoio.',
    route: '/escalas',
    defaultEnabled: true,
  },
  {
    key: 'relatorios_ebd',
    label: 'Relatórios EBD & Estatísticas',
    icon: 'pi pi-chart-bar',
    group: 'Educação & Ministérios',
    description: 'Gráficos de assiduidade, Bíblias e evolução de presença na EBD.',
    route: '/relatorios',
    defaultEnabled: true,
  },
  {
    key: 'relatorio_anual',
    label: 'Relatório Anual IPB',
    icon: 'pi pi-chart-pie',
    group: 'Educação & Ministérios',
    description: 'Consolidação de dados para envio formal ao Presbitério e Sínodo.',
    route: '/relatorios/anual',
    defaultEnabled: true,
  },
  {
    key: 'discipulado_biblioteca',
    label: 'Catecúmenos & Biblioteca',
    icon: 'pi pi-bookmark',
    group: 'Educação & Ministérios',
    description: 'Acompanhamento de novos convertidos, classes catecúmenas e acervo da igreja.',
    route: '/discipulado-biblioteca',
    defaultEnabled: true,
  },
  {
    key: 'disciplina',
    label: 'Código de Disciplina & Jurisdição',
    icon: 'pi pi-shield',
    group: 'Secretaria & Membresia',
    description: 'Processos eclesiásticos e acompanhamento pastoral do Conselho da Igreja.',
    route: '/secretaria/disciplina',
    defaultEnabled: true,
  },
  {
    key: 'estatistica_presbiterio',
    label: 'Estatística do Presbitério',
    icon: 'pi pi-percentage',
    group: 'Secretaria & Membresia',
    description: 'Dados estatísticos e conciliares para preenchimento de formulários oficiais.',
    route: '/secretaria/estatistica-presbiterio',
    defaultEnabled: true,
  },
  {
    key: 'cartas',
    label: 'Modelos de Cartas & Documentos',
    icon: 'pi pi-envelope',
    group: 'Secretaria & Membresia',
    description: 'Emissão e preenchimento dos 10 modelos oficiais de cartas, certidões e termos da IPB.',
    route: '/secretaria/modelos-cartas',
    defaultEnabled: true,
  },
  {
    key: 'atas',
    label: 'Livro de Atas do Conselho',
    icon: 'pi pi-book',
    group: 'Secretaria & Membresia',
    description: 'Registro digital e histórico das deliberações oficiais do Conselho.',
    route: '/secretaria/atas',
    defaultEnabled: true,
  },
  {
    key: 'boletim',
    label: 'Boletim Informativo Semanal',
    icon: 'pi pi-file-edit',
    group: 'Secretaria & Membresia',
    description: 'Elaboração, avisos semanais e diagramação do boletim dominical.',
    route: '/secretaria/boletim',
    defaultEnabled: true,
  },
  {
    key: 'financeiro',
    label: 'Livro Caixa (Tesouraria)',
    icon: 'pi pi-wallet',
    group: 'Finanças & Diaconia',
    description: 'Entradas, saídas diárias, controle de saldo e prestação de contas.',
    route: '/financeiro/transacoes',
    defaultEnabled: true,
  },
  {
    key: 'contabilidade',
    label: 'Contabilidade & Balancete',
    icon: 'pi pi-file-excel',
    group: 'Finanças & Diaconia',
    description: 'Demonstrativo de receitas, despesas e balancete contábil mensal.',
    route: '/financeiro/contabilidade',
    defaultEnabled: true,
  },
  {
    key: 'termo_balancete',
    label: 'Termo com Assinaturas',
    icon: 'pi pi-file-edit',
    group: 'Finanças & Diaconia',
    description: 'Geração de termo oficial do balancete com espaço para assinaturas do Conselho.',
    route: '/financeiro/termo-balancete',
    defaultEnabled: true,
  },
  {
    key: 'cotas_orcamento',
    label: 'Cotas & Orçamento Anual',
    icon: 'pi pi-chart-line',
    group: 'Finanças & Diaconia',
    description: 'Cotas conciliares (Supremo Concílio, Sínodo, Presbitério) e planejamento orçamentário.',
    route: '/financeiro/cotas-orcamento',
    defaultEnabled: true,
  },
  {
    key: 'parecer_exame_contas',
    label: 'Parecer do Exame de Contas',
    icon: 'pi pi-verified',
    group: 'Finanças & Diaconia',
    description: 'Laudo formal e relatório da Comissão de Exame de Contas da Igreja.',
    route: '/relatorios/parecer-exame-contas',
    defaultEnabled: true,
  },
  {
    key: 'contas_bancarias',
    label: 'Contas & Caixas',
    icon: 'pi pi-building-columns',
    group: 'Finanças & Diaconia',
    description: 'Gestão de contas correntes, poupanças e fundos de caixa da igreja.',
    route: '/financeiro/contas',
    defaultEnabled: true,
  },
  {
    key: 'plano_contas',
    label: 'Plano de Contas & Custos',
    icon: 'pi pi-tags',
    group: 'Finanças & Diaconia',
    description: 'Categorização de receitas e despesas e centros de custo eclesiásticos.',
    route: '/financeiro/categorias-custos',
    defaultEnabled: true,
  },
  {
    key: 'dizimos',
    label: 'Coletas, Dízimos & Acompanhamento',
    icon: 'pi pi-inbox',
    group: 'Finanças & Diaconia',
    description: 'Lançamento de envelopes do culto, dízimos individuais e relatórios de fidelidade.',
    route: '/dizimos/coletas',
    defaultEnabled: true,
  },
  {
    key: 'alertas_pastorais',
    label: 'Acompanhamento Pastoral',
    icon: 'pi pi-heart',
    group: 'Finanças & Diaconia',
    description: 'Alertas e acompanhamento de fidelidade para o pastor e conselho.',
    route: '/dizimos/alertas',
    defaultEnabled: true,
  },
  {
    key: 'patrimonio',
    label: 'Patrimônio & Livro Tombo',
    icon: 'pi pi-box',
    group: 'Finanças & Diaconia',
    description: 'Bens materiais, equipamentos, inventário e conservação das instalações.',
    route: '/diaconia/patrimonio',
    defaultEnabled: true,
  },
  {
    key: 'diaconato',
    label: 'Assistência Diaconal',
    icon: 'pi pi-hand-heart',
    group: 'Finanças & Diaconia',
    description: 'Atenção aos necessitados, cestas básicas e visitas beneficentes diaconais.',
    route: '/dizimos/diaconato',
    defaultEnabled: true,
  },
  {
    key: 'dizimos_config',
    label: 'Configurações de Dízimos',
    icon: 'pi pi-cog',
    group: 'Finanças & Diaconia',
    description: 'Parâmetros de coletas e limites de confidencialidade.',
    route: '/dizimos/config',
    defaultEnabled: true,
  },
  {
    key: 'usuarios',
    label: 'Gestão de Usuários',
    icon: 'pi pi-user-edit',
    group: 'Administração & Sistema',
    description: 'Controle de acessos, senhas e permissões eclesiásticas.',
    route: '/admin/usuarios',
    defaultEnabled: true,
  },
  {
    key: 'auditoria',
    label: 'Auditoria do Sistema',
    icon: 'pi pi-search',
    group: 'Administração & Sistema',
    description: 'Histórico de ações, registros de acessos e trilha de auditoria.',
    route: '/admin/auditoria',
    defaultEnabled: true,
  },
];

const DEFAULT_CHURCHES: ChurchInfo[] = [
  {
    id: 5,
    name: 'Igreja Presbiteriana em Campo Verde',
    short_name: 'IP Campo Verde',
    cnpj: '',
    city: 'Cariacica',
    state: 'ES',
    presbiterio: 'Presbitério de Vitória',
    sinodo: 'Sínodo Central',
    pastor_titular: 'Rev. Responsável',
    total_membros: 120,
    classes_ebd: 5,
    status: 'Ativa',
  },
  {
    id: 6,
    name: 'Igreja Presbiteriana de Vila Velha',
    short_name: 'IP Vila Velha',
    cnpj: '',
    city: 'Vila Velha',
    state: 'ES',
    presbiterio: 'Presbitério de Vitória',
    sinodo: 'Sínodo Central',
    pastor_titular: 'Rev. Responsável',
    total_membros: 210,
    classes_ebd: 6,
    status: 'Ativa',
  },
  {
    id: 7,
    name: 'Congregação Campo Grande',
    short_name: 'Cong. Campo Grande',
    cnpj: '',
    city: 'Cariacica',
    state: 'ES',
    presbiterio: 'Presbitério de Vitória',
    sinodo: 'Sínodo Central',
    pastor_titular: 'Evangelista Responsável',
    total_membros: 65,
    classes_ebd: 3,
    status: 'Congregação',
  },
  {
    id: 8,
    name: 'Congregação Jardim América',
    short_name: 'Cong. Jardim América',
    cnpj: '',
    city: 'Cariacica',
    state: 'ES',
    presbiterio: 'Presbitério de Vitória',
    sinodo: 'Sínodo Central',
    pastor_titular: 'Evangelista Responsável',
    total_membros: 54,
    classes_ebd: 2,
    status: 'Congregação',
  },
  {
    id: 10,
    name: 'Igreja Presbiteriana Central',
    short_name: 'IP Central',
    cnpj: '',
    city: '',
    state: '',
    presbiterio: 'Presbitério de Vitória',
    sinodo: 'Sínodo Central',
    pastor_titular: 'Pastor Titular',
    total_membros: 80,
    classes_ebd: 4,
    status: 'Ativa',
  },
];

@Injectable({ providedIn: 'root' })
export class ScreenConfigService {
  private http = inject(HttpClient);

  // Lista de igrejas
  readonly churches = signal<ChurchInfo[]>(this.loadStoredChurches());

  // Igreja ativa selecionada pelo Super Admin
  readonly activeChurchId = signal<number>(this.loadActiveChurchId());

  // Igreja ativa computada
  readonly activeChurch = computed(() => {
    const list = this.churches();
    const id = this.activeChurchId();
    return list.find((c) => c.id === id) || list[0] || null;
  });

  // Toggles de telas por igreja: { [churchId]: { [screenKey]: boolean } }
  private togglesState = signal<Record<string, Record<string, boolean>>>(this.loadStoredToggles());

  // Versão reativa para forçar re-render de menus
  readonly version = signal<number>(0);

  constructor() {
    // Garante inicialização padrão
    if (!this.loadStoredToggles() || Object.keys(this.togglesState()).length === 0) {
      const initial: Record<string, Record<string, boolean>> = {};
      this.churches().forEach((c) => {
        initial[String(c.id)] = {};
        SYSTEM_SCREENS.forEach((s) => {
          initial[String(c.id)][s.key] = s.defaultEnabled;
        });
      });
      this.togglesState.set(initial);
      this.persistToggles(initial);
    }
    // Sincroniza imediatamente com a nuvem (PostgreSQL) para carregar telas de todas as igrejas
    this.loadFromApi();
  }

  async loadFromApi(): Promise<void> {
    try {
      const res = await firstValueFrom(
        this.http.get<{ toggles: Record<string, Record<string, boolean>>; churches: ChurchInfo[] }>(
          `${environment.apiUrl}/screen-configs`
        )
      );
      if (res?.toggles && Object.keys(res.toggles).length > 0) {
        this.togglesState.set(res.toggles);
        localStorage.setItem('ipb_screen_toggles_by_church', JSON.stringify(res.toggles));
      }
      if (res?.churches && Array.isArray(res.churches) && res.churches.length > 0) {
        this.churches.set(res.churches);
        localStorage.setItem('ipb_super_admin_churches_v2', JSON.stringify(res.churches));
      }
      this.version.update((v) => v + 1);
    } catch (e) {
      console.warn('Não foi possível carregar screen-configs da API, usando cache local:', e);
    }
  }

  resolveEffectiveChurchId(): number {
    const rawUser = localStorage.getItem('ebd_user');
    if (rawUser) {
      try {
        const u = JSON.parse(rawUser);
        if (u?.institution_id) {
          return Number(u.institution_id);
        }
      } catch {}
    }
    return this.activeChurchId();
  }

  // --- LEITURA DE PERMISSÃO DE TELA ---
  isScreenEnabled(screenKey: string, churchId?: number): boolean {
    const targetId = churchId ?? this.resolveEffectiveChurchId();
    const churchToggles = this.togglesState()[String(targetId)];
    if (!churchToggles) {
      // Se não há configuração específica, busca padrão
      const def = SYSTEM_SCREENS.find((s) => s.key === screenKey);
      return def ? def.defaultEnabled : true;
    }
    return churchToggles[screenKey] !== false;
  }

  // Obter mapa completo de telas da igreja ativa
  getActiveChurchToggles(churchId?: number): Record<string, boolean> {
    const targetId = churchId ?? this.activeChurchId();
    const map = this.togglesState()[String(targetId)] || {};
    const full: Record<string, boolean> = {};
    SYSTEM_SCREENS.forEach((s) => {
      full[s.key] = map[s.key] !== false;
    });
    return full;
  }

  // --- ALTERAR ESTADO DE UMA TELA ---
  setScreenEnabled(screenKey: string, enabled: boolean, churchId?: number): void {
    const targetId = churchId ?? this.activeChurchId();
    const current = { ...this.togglesState() };
    const churchMap = { ...(current[String(targetId)] || {}) };
    churchMap[screenKey] = enabled;
    current[String(targetId)] = churchMap;

    this.togglesState.set(current);
    this.persistToggles(current);
    this.version.update((v) => v + 1);
  }

  // Ativar ou desativar todas as telas de uma vez para a igreja
  setAllScreens(enabled: boolean, churchId?: number): void {
    const targetId = churchId ?? this.activeChurchId();
    const current = { ...this.togglesState() };
    const churchMap: Record<string, boolean> = {};
    SYSTEM_SCREENS.forEach((s) => {
      churchMap[s.key] = enabled;
    });
    current[String(targetId)] = churchMap;

    this.togglesState.set(current);
    this.persistToggles(current);
    this.version.update((v) => v + 1);
  }

  // --- TROCA DE IGREJA ATIVA (SUPER ADMIN) ---
  switchChurch(churchId: number): void {
    this.activeChurchId.set(churchId);
    localStorage.setItem('ipb_super_admin_active_church_v2', String(churchId));
    this.version.update((v) => v + 1);
  }

  // Adicionar nova igreja
  addChurch(church: Omit<ChurchInfo, 'id'>): ChurchInfo {
    const list = this.churches();
    const newId = Math.max(...list.map((c) => c.id), 0) + 1;
    const newChurch: ChurchInfo = { ...church, id: newId };
    const updated = [...list, newChurch];
    this.churches.set(updated);
    localStorage.setItem('ipb_super_admin_churches_v2', JSON.stringify(updated));

    // Inicializa telas
    this.setAllScreens(true, newId);
    return newChurch;
  }

  // Atualizar igreja existente
  updateChurch(id: number, patch: Partial<ChurchInfo>): void {
    const list = this.churches();
    const updated = list.map((c) => (c.id === id ? { ...c, ...patch } : c));
    this.churches.set(updated);
    localStorage.setItem('ipb_super_admin_churches_v2', JSON.stringify(updated));
    this.version.update((v) => v + 1);
  }

  // Excluir igreja
  deleteChurch(id: number): void {
    const list = this.churches();
    const updated = list.filter((c) => c.id !== id);
    this.churches.set(updated);
    localStorage.setItem('ipb_super_admin_churches_v2', JSON.stringify(updated));
    if (this.activeChurchId() === id && updated.length > 0) {
      this.switchChurch(updated[0].id);
    } else {
      this.version.update((v) => v + 1);
    }
  }

  // Aplicar status de uma tela a TODAS as igrejas cadastradas de uma só vez
  applyToAllChurches(screenKey: string, enabled: boolean): void {
    const current = { ...this.togglesState() };
    this.churches().forEach((c) => {
      const cMap = { ...(current[String(c.id)] || {}) };
      cMap[screenKey] = enabled;
      current[String(c.id)] = cMap;
    });
    this.togglesState.set(current);
    this.persistToggles(current);
    this.version.update((v) => v + 1);
  }

  // Restaurar padrões do sistema
  resetToDefaults(churchId?: number): void {
    const targetId = churchId ?? this.activeChurchId();
    const current = { ...this.togglesState() };
    const defaultMap: Record<string, boolean> = {};
    SYSTEM_SCREENS.forEach((s) => {
      defaultMap[s.key] = s.defaultEnabled;
    });
    current[String(targetId)] = defaultMap;
    this.togglesState.set(current);
    this.persistToggles(current);
    this.version.update((v) => v + 1);
  }

  // Obter contagem de telas ativas de uma igreja
  getEnabledCount(churchId?: number): { enabled: number; total: number } {
    const targetId = churchId ?? this.activeChurchId();
    const toggles = this.getActiveChurchToggles(targetId);
    let count = 0;
    SYSTEM_SCREENS.forEach((s) => {
      if (toggles[s.key]) count++;
    });
    return { enabled: count, total: SYSTEM_SCREENS.length };
  }

  // Estatísticas globais da denominação
  getGlobalStats() {
    const list = this.churches();
    const totalMembers = list.reduce((acc, c) => acc + (c.total_membros || 0), 0);
    const totalCongregations = list.filter((c) => c.status === 'Congregação').length;
    const totalActive = list.filter((c) => c.status === 'Ativa').length;
    return {
      totalChurches: list.length,
      totalActive,
      totalCongregations,
      totalMembers,
      totalScreens: SYSTEM_SCREENS.length,
    };
  }

  // Ativar ou desativar todas as telas de TODAS as igrejas cadastradas de uma só vez
  setAllScreensGlobally(enabled: boolean): void {
    const current = { ...this.togglesState() };
    this.churches().forEach((c) => {
      const churchMap: Record<string, boolean> = {};
      SYSTEM_SCREENS.forEach((s) => {
        churchMap[s.key] = enabled;
      });
      current[String(c.id)] = churchMap;
    });

    this.togglesState.set(current);
    this.persistToggles(current);
    this.version.update((v) => v + 1);
  }

  // --- PERSISTÊNCIA LOCAL & REMOTA ---
  private loadStoredChurches(): ChurchInfo[] {
    const raw = localStorage.getItem('ipb_super_admin_churches_v2');
    if (raw) {
      try {
        const list = JSON.parse(raw);
        if (Array.isArray(list) && list.length > 0 && !list.some((c: any) => c.name?.includes('Bela Vista') || c.state === 'MT')) {
          return list;
        }
      } catch {
        return DEFAULT_CHURCHES;
      }
    }
    return DEFAULT_CHURCHES;
  }

  private loadActiveChurchId(): number {
    const raw = localStorage.getItem('ipb_super_admin_active_church_v2');
    return raw ? Number(raw) : 5;
  }

  private loadStoredToggles(): Record<string, Record<string, boolean>> {
    const raw = localStorage.getItem('ipb_screen_toggles_by_church');
    if (raw) {
      try {
        return JSON.parse(raw);
      } catch {
        return {};
      }
    }
    return {};
  }

  private persistToggles(data: Record<string, Record<string, boolean>>): void {
    localStorage.setItem('ipb_screen_toggles_by_church', JSON.stringify(data));
    // Sincroniza em tempo real com o backend da API para persistir no banco e distribuir para todas as igrejas e computadores
    this.http.post(`${environment.apiUrl}/screen-configs`, {
      toggles: data,
      churches: this.churches()
    }).subscribe({
      next: () => {},
      error: (err) => console.warn('Aviso: falha na sincronização de telas com a API na nuvem:', err)
    });
  }
}
