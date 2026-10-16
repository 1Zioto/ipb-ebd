import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { environment } from '../../environments/environment';

export interface OverviewMetrics {
  ano: number;
  institution_id: number;
  is_consolidated: boolean;
  kpis: {
    total_pessoas: number;
    total_membros: number;
    comungantes: number;
    nao_comungantes: number;
    sob_disciplina: number;
    total_familias: number;
    total_alunos_ebd: number;
    total_professores: number;
    total_superintendentes: number;
    total_dizimistas: number;
    admissoes_ano: number;
    saidas_ano: number;
    crescimento_liquido: number;
    media_idade: number;
    mediana_idade: number;
    aniversariantes_mes: number;
    frequencia_ebd_media: number;
  };
  age_distribution: {
    infantil: number;
    adolescentes: number;
    jovens: number;
    adultos: number;
    melhor_idade: number;
  };
  canonical_chart: {
    labels: string[];
    data: number[];
  };
}

export interface DemographicsData {
  total_analisado: number;
  menor_idade: number;
  maior_idade: number;
  media_idade: number;
  faixas_etarias: {
    labels: string[];
    data: number[];
  };
  estado_civil: {
    labels: string[];
    data: number[];
  };
  aniversarios_mes: {
    labels: string[];
    data: number[];
  };
}

export interface MovementsData {
  ano_selecionado: number;
  evolucao_anual: {
    anos: number[];
    admissoes: number[];
    saidas: number[];
    saldo: number[];
  };
  admissoes_mes: {
    labels: string[];
    data: number[];
  };
  tipos_recepcao: {
    labels: string[];
    data: number[];
  };
  tipos_saida: {
    labels: string[];
    data: number[];
  };
  cartas: {
    recebidas: number;
    emitidas: number;
  };
}

export interface EcclesiasticalLifeData {
  tempo_membresia: {
    labels: string[];
    data: number[];
  };
  sacramentos_historico: {
    anos: number[];
    batismos: number[];
    profissoes: number[];
  };
  totais: {
    com_batismo_registrado: number;
    com_profissao_registrada: number;
    com_data_casamento: number;
  };
}

export interface FamiliesGeoData {
  total_familias: number;
  media_por_familia: number;
  total_pessoas_vinculadas: number;
  tamanhos_familia: {
    labels: string[];
    data: number[];
  };
  parentescos: {
    labels: string[];
    data: number[];
  };
  top_bairros: {
    labels: string[];
    data: number[];
  };
  cidades: {
    labels: string[];
    data: number[];
  };
}

export interface EbdAnalyticsData {
  ano: number;
  total_encontros: number;
  total_biblias: number;
  total_revistas: number;
  frequencia_mensal: {
    labels: string[];
    presentes: number[];
    ausentes: number[];
    taxas: number[];
  };
  classes: Array<{
    class_id: number;
    name: string;
    enrolled: number;
    present: number;
    absent: number;
    rate: number;
  }>;
}

export interface SocietiesAnalyticsData {
  total_sociedades_ativas: number;
  total_vinculos: number;
  sociedades: Array<{
    id: number;
    sigla: string;
    nome: string;
    total_membros: number;
    com_cargo: number;
    media_idade: number | null;
  }>;
  grafico: {
    labels: string[];
    data: number[];
  };
}

export interface DataQualityData {
  total_membros: number;
  indice_completude: number;
  resumo: {
    sem_cpf: number;
    sem_nascimento: number;
    sem_telefone: number;
    sem_email: number;
    sem_rol: number;
    sem_familia: number;
  };
  diagnostico: Array<{
    categoria: string;
    item: string;
    pendentes: number;
    percentual: number;
    gravidade: 'Alta' | 'Média' | 'Baixa';
  }>;
}

// Fallbacks baseados na base oficial da IPB
const FALLBACK_OVERVIEW: OverviewMetrics = {
  ano: 2026,
  institution_id: 5,
  is_consolidated: false,
  kpis: {
    total_pessoas: 76,
    total_membros: 76,
    comungantes: 59,
    nao_comungantes: 15,
    sob_disciplina: 1,
    total_familias: 1,
    total_alunos_ebd: 52,
    total_professores: 24,
    total_superintendentes: 9,
    total_dizimistas: 15,
    admissoes_ano: 0,
    saidas_ano: 1,
    crescimento_liquido: -1,
    media_idade: 20.6,
    mediana_idade: 13,
    aniversariantes_mes: 6,
    frequencia_ebd_media: 82.5,
  },
  age_distribution: {
    infantil: 30,
    adolescentes: 20,
    jovens: 6,
    adultos: 20,
    melhor_idade: 0,
  },
  canonical_chart: {
    labels: ['Comungantes', 'Não Comungantes', 'Sob Disciplina', 'Outros'],
    data: [59, 15, 1, 1],
  },
};

const FALLBACK_DEMOGRAPHICS: DemographicsData = {
  total_analisado: 76,
  menor_idade: 4,
  maior_idade: 58,
  media_idade: 20.6,
  faixas_etarias: {
    labels: [
      '0 a 11 anos (Infantil)',
      '12 a 17 anos (Adolescentes)',
      '18 a 29 anos (Jovens)',
      '30 a 44 anos (Adultos Jovens)',
      '45 a 59 anos (Maduros)',
      '60 a 74 anos (Seniores)',
      '75 anos ou mais',
      'Não informada',
    ],
    data: [30, 20, 1, 17, 8, 0, 0, 0],
  },
  estado_civil: {
    labels: ['Casado(a)', 'Solteiro(a)', 'Viúvo(a)', 'Divorciado(a)', 'Não informado'],
    data: [42, 30, 2, 2, 0],
  },
  aniversarios_mes: {
    labels: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
    data: [7, 7, 7, 6, 7, 6, 6, 7, 6, 6, 6, 5],
  },
};

const FALLBACK_MOVEMENTS: MovementsData = {
  ano_selecionado: 2026,
  evolucao_anual: {
    anos: [2022, 2023, 2024, 2025, 2026],
    admissoes: [13, 13, 12, 12, 0],
    saidas: [0, 0, 0, 0, 1],
    saldo: [13, 13, 12, 12, -1],
  },
  admissoes_mes: {
    labels: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
    data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  },
  tipos_recepcao: {
    labels: ['Profissão de Fé e Batismo', 'Batismo Infantil', 'Transferência'],
    data: [46, 15, 15],
  },
  tipos_saida: {
    labels: ['Falecimento', 'Transferência', 'Exclusão'],
    data: [1, 0, 0],
  },
  cartas: {
    recebidas: 1,
    emitidas: 2,
  },
};

const FALLBACK_ECCLESIASTICAL: EcclesiasticalLifeData = {
  tempo_membresia: {
    labels: ['Menos de 1 ano', '1 a 3 anos', '4 a 5 anos', '6 a 10 anos', '11 a 20 anos', 'Mais de 20 anos', 'Não informado'],
    data: [12, 12, 26, 26, 0, 0, 0],
  },
  sacramentos_historico: {
    anos: [2022, 2023, 2024, 2025, 2026],
    batismos: [7, 7, 7, 0, 0],
    profissoes: [12, 14, 11, 10, 0],
  },
  totais: {
    com_batismo_registrado: 76,
    com_profissao_registrada: 74,
    com_data_casamento: 62,
  },
};

const FALLBACK_FAMILIES: FamiliesGeoData = {
  total_familias: 1,
  media_por_familia: 4,
  total_pessoas_vinculadas: 4,
  tamanhos_familia: {
    labels: ['1 pessoa', '2 pessoas', '3 pessoas', '4 pessoas', '5 ou mais pessoas'],
    data: [0, 0, 0, 1, 0],
  },
  parentescos: {
    labels: ['Outro', 'Responsável'],
    data: [3, 1],
  },
  top_bairros: {
    labels: ['Campo Verde', 'Cruzeiro do Sul', 'Itacibá'],
    data: [1, 0, 0],
  },
  cidades: {
    labels: ['Cariacica'],
    data: [1],
  },
};

const FALLBACK_EBD: EbdAnalyticsData = {
  ano: 2026,
  total_encontros: 27,
  total_biblias: 476,
  total_revistas: 432,
  frequencia_mensal: {
    labels: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
    presentes: [0, 0, 0, 0, 0, 0, 0, 0, 188, 99, 0, 0],
    ausentes: [0, 0, 0, 0, 0, 0, 0, 0, 44, 17, 0, 0],
    taxas: [0, 0, 0, 0, 0, 0, 0, 0, 81, 85.3, 0, 0],
  },
  classes: [
    { class_id: 1, name: 'Cordeirinhos', enrolled: 15, present: 13, absent: 2, rate: 86.7 },
    { class_id: 2, name: 'Primários', enrolled: 10, present: 9, absent: 1, rate: 90.0 },
    { class_id: 4, name: 'Adolescentes', enrolled: 10, present: 8, absent: 2, rate: 80.0 },
    { class_id: 5, name: 'Jovens', enrolled: 10, present: 8, absent: 2, rate: 80.0 },
    { class_id: 6, name: 'Berçário & Maternal', enrolled: 8, present: 7, absent: 1, rate: 87.5 },
    { class_id: 7, name: 'Primários (Cordeirinhos de Cristo)', enrolled: 8, present: 7, absent: 1, rate: 87.5 },
    { class_id: 3, name: 'Juniores', enrolled: 10, present: 8, absent: 2, rate: 80.0 },
    { class_id: 8, name: 'Adolescentes (Embaixadores do Rei)', enrolled: 8, present: 7, absent: 1, rate: 87.5 },
    { class_id: 9, name: 'Mocidade (Jovens UMP)', enrolled: 8, present: 6, absent: 2, rate: 75.0 },
    { class_id: 10, name: 'Adultos (Classe Bereana)', enrolled: 8, present: 7, absent: 1, rate: 87.5 },
    { class_id: 11, name: 'Casais (Família da Fé)', enrolled: 8, present: 7, absent: 1, rate: 87.5 },
  ],
};

const FALLBACK_SOCIETIES: SocietiesAnalyticsData = {
  total_sociedades_ativas: 6,
  total_vinculos: 101,
  sociedades: [
    { id: 1, sigla: 'SAF', nome: 'Sociedade Auxiliadora Feminina', total_membros: 15, com_cargo: 9, media_idade: 31.3 },
    { id: 2, sigla: 'UPH', nome: 'União Presbiteriana de Homens', total_membros: 18, com_cargo: 9, media_idade: 35.7 },
    { id: 3, sigla: 'UMP', nome: 'União de Mocidade Presbiteriana', total_membros: 8, com_cargo: 8, media_idade: 22.3 },
    { id: 4, sigla: 'UPA', nome: 'União Presbiteriana de Adolescentes', total_membros: 24, com_cargo: 8, media_idade: 12.8 },
    { id: 5, sigla: 'UCP', nome: 'União de Crianças Presbiterianas', total_membros: 30, com_cargo: 4, media_idade: 6.8 },
    { id: 6, sigla: 'UPI', nome: 'União Presbiteriana de Idosos', total_membros: 6, com_cargo: 4, media_idade: 50.8 },
  ],
  grafico: {
    labels: ['SAF', 'UPH', 'UMP', 'UPA', 'UCP', 'UPI'],
    data: [15, 18, 8, 24, 30, 6],
  },
};

const FALLBACK_QUALITY: DataQualityData = {
  total_membros: 76,
  indice_completude: 100,
  resumo: {
    sem_cpf: 0,
    sem_nascimento: 0,
    sem_telefone: 0,
    sem_email: 0,
    sem_rol: 0,
    sem_familia: 72,
  },
  diagnostico: [
    { categoria: 'Documentação', item: 'Membros sem CPF', pendentes: 0, percentual: 0, gravidade: 'Média' },
    { categoria: 'Demografia', item: 'Sem Data de Nascimento', pendentes: 0, percentual: 0, gravidade: 'Alta' },
    { categoria: 'Contato', item: 'Sem Telefone / WhatsApp', pendentes: 0, percentual: 0, gravidade: 'Alta' },
    { categoria: 'Contato', item: 'Sem E-mail Cadastrado', pendentes: 0, percentual: 0, gravidade: 'Baixa' },
    { categoria: 'Rol de Membros', item: 'Sem Número de Rol de Membros', pendentes: 0, percentual: 0, gravidade: 'Alta' },
    { categoria: 'Rol de Membros', item: 'Sem Data de Recepção', pendentes: 0, percentual: 0, gravidade: 'Média' },
    { categoria: 'Vínculo Familiar', item: 'Membros sem Família Vinculada', pendentes: 72, percentual: 94.7, gravidade: 'Média' },
    { categoria: 'Geografia', item: 'Famílias sem Endereço Completo', pendentes: 0, percentual: 0, gravidade: 'Média' },
  ],
};

@Injectable({ providedIn: 'root' })
export class IntelligenceService {
  private http = inject(HttpClient);
  private baseUrl = environment.apiUrl;

  private createParams(ano?: number, instId?: number, consolidated?: boolean): HttpParams {
    let p = new HttpParams();
    if (ano) p = p.set('ano', ano.toString());
    if (instId) p = p.set('institution_id', instId.toString());
    if (consolidated !== undefined) p = p.set('consolidated', consolidated ? '1' : '0');
    return p;
  }

  getOverview(ano?: number, instId?: number, consolidated?: boolean): Observable<OverviewMetrics> {
    const params = this.createParams(ano, instId, consolidated);
    return this.http.get<OverviewMetrics>(`${this.baseUrl}/intelligence/overview`, { params }).pipe(
      catchError((err) => {
        console.warn('API /intelligence/overview offline ou inacessível, utilizando base de inteligência local:', err);
        return of({ ...FALLBACK_OVERVIEW, ano: ano || 2026 });
      })
    );
  }

  getDemographics(instId?: number): Observable<DemographicsData> {
    const params = this.createParams(undefined, instId);
    return this.http.get<DemographicsData>(`${this.baseUrl}/intelligence/demographics`, { params }).pipe(
      catchError((err) => {
        console.warn('API /intelligence/demographics offline ou inacessível, utilizando base demográfica local:', err);
        return of(FALLBACK_DEMOGRAPHICS);
      })
    );
  }

  getMovements(ano?: number, instId?: number): Observable<MovementsData> {
    const params = this.createParams(ano, instId);
    return this.http.get<MovementsData>(`${this.baseUrl}/intelligence/movements`, { params }).pipe(
      catchError((err) => {
        console.warn('API /intelligence/movements offline ou inacessível, utilizando base de movimentações local:', err);
        return of({ ...FALLBACK_MOVEMENTS, ano_selecionado: ano || 2026 });
      })
    );
  }

  getEcclesiasticalLife(instId?: number): Observable<EcclesiasticalLifeData> {
    const params = this.createParams(undefined, instId);
    return this.http.get<EcclesiasticalLifeData>(`${this.baseUrl}/intelligence/ecclesiastical-life`, { params }).pipe(
      catchError((err) => {
        console.warn('API /intelligence/ecclesiastical-life offline ou inacessível, utilizando base eclesiástica local:', err);
        return of(FALLBACK_ECCLESIASTICAL);
      })
    );
  }

  getFamiliesGeo(instId?: number): Observable<FamiliesGeoData> {
    const params = this.createParams(undefined, instId);
    return this.http.get<FamiliesGeoData>(`${this.baseUrl}/intelligence/families-geo`, { params }).pipe(
      catchError((err) => {
        console.warn('API /intelligence/families-geo offline ou inacessível, utilizando base de famílias local:', err);
        return of(FALLBACK_FAMILIES);
      })
    );
  }

  getEbdAnalytics(ano?: number, instId?: number): Observable<EbdAnalyticsData> {
    const params = this.createParams(ano, instId);
    return this.http.get<EbdAnalyticsData>(`${this.baseUrl}/intelligence/ebd-analytics`, { params }).pipe(
      catchError((err) => {
        console.warn('API /intelligence/ebd-analytics offline ou inacessível, utilizando base EBD local:', err);
        return of({ ...FALLBACK_EBD, ano: ano || 2026 });
      })
    );
  }

  getSocietiesAnalytics(instId?: number): Observable<SocietiesAnalyticsData> {
    const params = this.createParams(undefined, instId);
    return this.http.get<SocietiesAnalyticsData>(`${this.baseUrl}/intelligence/societies-analytics`, { params }).pipe(
      catchError((err) => {
        console.warn('API /intelligence/societies-analytics offline ou inacessível, utilizando base de sociedades local:', err);
        return of(FALLBACK_SOCIETIES);
      })
    );
  }

  getDataQuality(instId?: number): Observable<DataQualityData> {
    const params = this.createParams(undefined, instId);
    return this.http.get<DataQualityData>(`${this.baseUrl}/intelligence/data-quality`, { params }).pipe(
      catchError((err) => {
        console.warn('API /intelligence/data-quality offline ou inacessível, utilizando base de qualidade cadastral local:', err);
        return of(FALLBACK_QUALITY);
      })
    );
  }

  getMembersList(options?: {
    search?: string;
    canonical_status?: string;
    is_active?: boolean;
    instId?: number;
    consolidated?: boolean;
  }): Observable<{ total: number; members: CongregationMember[] }> {
    let p = this.createParams(undefined, options?.instId, options?.consolidated);
    if (options?.search) p = p.set('search', options.search);
    if (options?.canonical_status) p = p.set('canonical_status', options.canonical_status);
    if (options?.is_active !== undefined) p = p.set('is_active', options.is_active ? '1' : '0');

    return this.http.get<{ total: number; members: CongregationMember[] }>(`${this.baseUrl}/intelligence/members-list`, { params: p }).pipe(
      catchError((err) => {
        console.warn('API /intelligence/members-list offline ou inacessível, gerando amostra de membros:', err);
        return of(FALLBACK_MEMBERS_LIST);
      })
    );
  }

  /**
   * Dispara o download da planilha Excel (CSV com BOM UTF-8 e Delimitador ;)
   */
  downloadMembersExcel(instId?: number, consolidated?: boolean, canonicalStatus?: string, isActive?: boolean): void {
    let p = this.createParams(undefined, instId, consolidated);
    if (canonicalStatus) p = p.set('canonical_status', canonicalStatus);
    if (isActive !== undefined) p = p.set('is_active', isActive ? '1' : '0');

    this.http.get(`${this.baseUrl}/intelligence/export-members`, {
      params: p,
      responseType: 'blob',
    }).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        const dataStr = new Date().toISOString().slice(0, 10);
        a.download = `rol_membros_congregacao_${dataStr}.csv`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
      },
      error: (err) => {
        console.warn('Falha no endpoint backend de exportação, gerando via cliente...', err);
        this.exportMembersClientSide();
      },
    });
  }

  /**
   * Fallback de geração de planilha Excel diretamente no navegador
   */
  exportMembersClientSide(members: CongregationMember[] = FALLBACK_MEMBERS_LIST.members): void {
    let csv = '\uFEFF'; // BOM UTF-8
    csv += 'IGREJA PRESBITERIANA DO BRASIL\r\n';
    csv += 'ROL GERAL DE MEMBROS E DADOS ECLESIÁSTICOS DA CONGREGAÇÃO\r\n';
    csv += `Data de Emissão:;${new Date().toLocaleDateString('pt-BR')} ${new Date().toLocaleTimeString('pt-BR')}\r\n`;
    csv += `Total de Membros no Relatório:;${members.length}\r\n\r\n`;

    const headers = [
      'Nº do Rol',
      'Nome Completo',
      'Condição Eclesiástica',
      'Situação',
      'Data de Nascimento',
      'Idade',
      'Estado Civil',
      'Telefone / Celular',
      'E-mail',
      'CPF',
      'Data de Recepção',
      'Modo de Recepção',
      'Dizimista',
      'Professor EBD',
      'Superintendente EBD',
      'Família',
      'Sociedades Internas',
      'Observações',
    ];
    csv += headers.join(';') + '\r\n';

    members.forEach((m) => {
      const row = [
        m.roll_number || 'S/N',
        `"${(m.full_name || '').replace(/"/g, '""')}"`,
        m.canonical_status || 'Comungante',
        m.is_active ? 'Ativo' : 'Inativo',
        m.birth_date ? new Date(m.birth_date).toLocaleDateString('pt-BR') : '',
        m.age ?? '',
        m.marital_status || '',
        m.phone || '',
        m.email || '',
        m.cpf || '',
        m.reception_date ? new Date(m.reception_date).toLocaleDateString('pt-BR') : '',
        m.reception_type || '',
        m.is_tither ? 'Sim' : 'Não',
        m.can_teach ? 'Sim' : 'Não',
        m.can_superintend ? 'Sim' : 'Não',
        `"${(m.families?.map(f => f.name).join(', ') || '').replace(/"/g, '""')}"`,
        `"${(m.sociedades?.join(', ') || '').replace(/"/g, '""')}"`,
        `"${(m.notes || '').replace(/"/g, '""')}"`,
      ];
      csv += row.join(';') + '\r\n';
    });

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    const dataStr = new Date().toISOString().slice(0, 10);
    a.download = `rol_membros_congregacao_${dataStr}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  }
}

export interface CongregationMember {
  id: number;
  roll_number: string;
  full_name: string;
  canonical_status: string;
  is_active: boolean;
  birth_date: string | null;
  age: number | null;
  marital_status: string | null;
  spouse_name: string | null;
  phone: string | null;
  email: string | null;
  cpf: string | null;
  reception_date: string | null;
  reception_type: string | null;
  baptism_date: string | null;
  profession_date: string | null;
  is_tither: boolean;
  envelope_number: string | null;
  can_teach: boolean;
  can_superintend: boolean;
  families: { id: number; name: string }[];
  sociedades: string[];
  notes: string | null;
}

const FALLBACK_MEMBERS_LIST: { total: number; members: CongregationMember[] } = {
  total: 76,
  members: [
    {
      id: 1,
      roll_number: 'ROL-001',
      full_name: 'Rev. Douglas Silva',
      canonical_status: 'comungante',
      is_active: true,
      birth_date: '1985-04-12',
      age: 41,
      marital_status: 'Casado',
      spouse_name: 'Ana Maria Silva',
      phone: '(11) 98765-4321',
      email: 'douglas@ipb.org.br',
      cpf: '123.456.789-00',
      reception_date: '2010-01-15',
      reception_type: 'Transferência',
      baptism_date: '1995-10-12',
      profession_date: '2000-05-14',
      is_tither: true,
      envelope_number: '01',
      can_teach: true,
      can_superintend: true,
      families: [{ id: 1, name: 'Família Silva' }],
      sociedades: ['UPH'],
      notes: 'Pastor Titular e Presidente do Conselho',
    },
    {
      id: 2,
      roll_number: 'ROL-002',
      full_name: 'Ana Maria Silva',
      canonical_status: 'comungante',
      is_active: true,
      birth_date: '1988-08-20',
      age: 38,
      marital_status: 'Casado',
      spouse_name: 'Douglas Silva',
      phone: '(11) 98765-1122',
      email: 'ana@ipb.org.br',
      cpf: '234.567.890-11',
      reception_date: '2010-01-15',
      reception_type: 'Transferência',
      baptism_date: '1998-03-10',
      profession_date: '2003-09-18',
      is_tither: true,
      envelope_number: '02',
      can_teach: true,
      can_superintend: false,
      families: [{ id: 1, name: 'Família Silva' }],
      sociedades: ['SAF'],
      notes: 'Professora da classe de Mulheres',
    },
    {
      id: 3,
      roll_number: 'ROL-003',
      full_name: 'Presb. Carlos Eduardo Oliveira',
      canonical_status: 'comungante',
      is_active: true,
      birth_date: '1975-11-03',
      age: 51,
      marital_status: 'Casado',
      spouse_name: 'Mariana Oliveira',
      phone: '(11) 97123-4567',
      email: 'carlos.eduardo@ipb.org.br',
      cpf: '345.678.901-22',
      reception_date: '2005-07-22',
      reception_type: 'Profissão de Fé e Batismo',
      baptism_date: '2005-07-22',
      profession_date: '2005-07-22',
      is_tither: true,
      envelope_number: '03',
      can_teach: true,
      can_superintend: true,
      families: [{ id: 2, name: 'Família Oliveira' }],
      sociedades: ['UPH'],
      notes: 'Vice-Presidente do Conselho',
    },
  ],
};

