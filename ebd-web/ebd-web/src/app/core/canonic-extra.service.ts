import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface ProcessoDisciplinar {
  id: number;
  numero_processo: string;
  person_id: number;
  person?: {
    id: number;
    full_name: string;
    roll_number?: string;
    canonical_status: string;
  };
  tipo_falta: string;
  descricao_falta: string;
  medida_disciplinar: string;
  data_abertura: string;
  data_julgamento?: string;
  data_restauracao?: string;
  prazo_meses?: number;
  relator_presbitero?: string;
  ata_conselho_id?: number;
  ataConselho?: {
    id: number;
    numero_ata: string;
    data_reuniao: string;
  };
  status: string;
  observacoes_pastorais?: string;
  created_at?: string;
}

export interface PatrimonioBem {
  id: number;
  numero_tombamento: string;
  nome: string;
  categoria: string;
  localizacao: string;
  data_aquisicao?: string;
  valor_aquisicao?: number;
  valor_atual?: number;
  estado_conservacao: 'Excelente' | 'Bom' | 'Regular' | 'Danificado';
  status: 'Ativo' | 'Em Manutenção' | 'Baixado/Descartado' | 'Cedido/Emprestado';
  nota_fiscal?: string;
  descricao?: string;
  responsavel_diacono?: string;
}

export interface OrdemServicoDiaconia {
  id: number;
  numero_os: string;
  titulo: string;
  descricao: string;
  tipo_servico: string;
  localizacao: string;
  prioridade: 'Baixa' | 'Média' | 'Alta' | 'Urgente';
  status: 'Pendente' | 'Em Andamento' | 'Concluída' | 'Cancelada';
  solicitante: string;
  diacono_responsavel?: string;
  data_solicitacao: string;
  data_previsao?: string;
  data_conclusao?: string;
  custo_estimado: number;
  custo_real: number;
  observacoes?: string;
}

export interface EscalaDiacono {
  id: number;
  data_culto: string;
  periodo: string;
  recepcao_porta?: string;
  recolhimento_ofertas?: string;
  apoio_pulpito_ceia?: string;
  seguranca_patio?: string;
  diacono_coordenador?: string;
  observacoes?: string;
}

export interface CotaConciliar {
  id: number;
  ano: number;
  mes: number;
  base_calculo: number;
  aliquota_presbiterio_pct: number;
  aliquota_supremo_concilio_pct: number;
  valor_presbiterio: number;
  valor_supremo_concilio: number;
  status_presbiterio: 'Pendente' | 'Pago';
  status_supremo_concilio: 'Pendente' | 'Pago';
  data_pagamento_presbiterio?: string;
  data_pagamento_sc?: string;
  comprovante_presbiterio?: string;
  comprovante_sc?: string;
  observacoes?: string;
}

export interface OrcamentoLinha {
  id: number;
  departamento_ou_sociedade: string;
  descricao: string;
  financial_cost_center?: string;
  valor_previsto: number;
  valor_realizado: number;
  saldo: number;
  percentual: number;
  status: string;
  observacoes?: string;
}

export interface ComparativoOrcamentoResponse {
  ano: number;
  linhas: OrcamentoLinha[];
  totais: {
    previsto_total: number;
    realizado_total: number;
    saldo_total: number;
    percentual_execucao: number;
    despesas_gerais_igreja: number;
  };
}

export interface ParecerExameContas {
  id: number;
  numero_parecer: string;
  ano_exercicio: number;
  periodo: string;
  data_emissao: string;
  relator: string;
  membros_comissao?: string[];
  resultado: 'Favorável sem ressalvas' | 'Favorável com ressalvas' | 'Desfavorável';
  total_receitas_auditado: number;
  total_despesas_auditado: number;
  saldo_apurado: number;
  conformidade_livro_caixa: boolean;
  conformidade_extratos_bancarios: boolean;
  conformidade_comprovantes_fiscais: boolean;
  conformidade_cotas_conciliares: boolean;
  ressalvas_e_recomendacoes?: string;
  texto_conclusao: string;
  status: string;
}

@Injectable({
  providedIn: 'root',
})
export class CanonicExtraService {
  private http = inject(HttpClient);
  private api = environment.apiUrl;

  // ==========================================
  // 1. DISCIPLINA & JURISDIÇÃO PASTORAL
  // ==========================================
  getProcessos(params?: { status?: string; tipo_falta?: string; search?: string; page?: number }): Observable<any> {
    let p = new HttpParams();
    if (params?.status) p = p.set('status', params.status);
    if (params?.tipo_falta) p = p.set('tipo_falta', params.tipo_falta);
    if (params?.search) p = p.set('search', params.search);
    if (params?.page) p = p.set('page', params.page);
    return this.http.get(`${this.api}/disciplina/processos`, { params: p });
  }

  createProcesso(data: Partial<ProcessoDisciplinar>): Observable<ProcessoDisciplinar> {
    return this.http.post<ProcessoDisciplinar>(`${this.api}/disciplina/processos`, data);
  }

  updateProcesso(id: number, data: Partial<ProcessoDisciplinar>): Observable<ProcessoDisciplinar> {
    return this.http.put<ProcessoDisciplinar>(`${this.api}/disciplina/processos/${id}`, data);
  }

  restaurarMembro(id: number, data: { data_restauracao: string; observacoes_pastorais?: string }): Observable<any> {
    return this.http.post(`${this.api}/disciplina/processos/${id}/restaurar`, data);
  }

  getAlertasAbandono(): Observable<any[]> {
    return this.http.get<any[]>(`${this.api}/disciplina/alertas-abandono`);
  }

  // ==========================================
  // 2. JUNTA DIACONAL & PATRIMÔNIO
  // ==========================================
  getBens(params?: { categoria?: string; status?: string; search?: string; page?: number }): Observable<any> {
    let p = new HttpParams();
    if (params?.categoria) p = p.set('categoria', params.categoria);
    if (params?.status) p = p.set('status', params.status);
    if (params?.search) p = p.set('search', params.search);
    if (params?.page) p = p.set('page', params.page);
    return this.http.get(`${this.api}/diaconia/bens`, { params: p });
  }

  createBem(data: Partial<PatrimonioBem>): Observable<PatrimonioBem> {
    return this.http.post<PatrimonioBem>(`${this.api}/diaconia/bens`, data);
  }

  updateBem(id: number, data: Partial<PatrimonioBem>): Observable<PatrimonioBem> {
    return this.http.put<PatrimonioBem>(`${this.api}/diaconia/bens/${id}`, data);
  }

  deleteBem(id: number): Observable<any> {
    return this.http.delete(`${this.api}/diaconia/bens/${id}`);
  }

  // Ordens de Serviço
  getOrdensServico(params?: { status?: string; prioridade?: string; page?: number }): Observable<any> {
    let p = new HttpParams();
    if (params?.status) p = p.set('status', params.status);
    if (params?.prioridade) p = p.set('prioridade', params.prioridade);
    if (params?.page) p = p.set('page', params.page);
    return this.http.get(`${this.api}/diaconia/ordens-servico`, { params: p });
  }

  createOS(data: Partial<OrdemServicoDiaconia>): Observable<OrdemServicoDiaconia> {
    return this.http.post<OrdemServicoDiaconia>(`${this.api}/diaconia/ordens-servico`, data);
  }

  updateOS(id: number, data: Partial<OrdemServicoDiaconia>): Observable<OrdemServicoDiaconia> {
    return this.http.put<OrdemServicoDiaconia>(`${this.api}/diaconia/ordens-servico/${id}`, data);
  }

  concluirOS(id: number, data: { data_conclusao: string; custo_real: number; observacoes?: string }): Observable<any> {
    return this.http.post(`${this.api}/diaconia/ordens-servico/${id}/concluir`, data);
  }

  // Escalas de Diáconos
  getEscalasDiaconos(mes?: number, ano?: number): Observable<EscalaDiacono[]> {
    let p = new HttpParams();
    if (mes) p = p.set('mes', mes);
    if (ano) p = p.set('ano', ano);
    return this.http.get<EscalaDiacono[]>(`${this.api}/diaconia/escalas`, { params: p });
  }

  createEscalaDiacono(data: Partial<EscalaDiacono>): Observable<EscalaDiacono> {
    return this.http.post<EscalaDiacono>(`${this.api}/diaconia/escalas`, data);
  }

  updateEscalaDiacono(id: number, data: Partial<EscalaDiacono>): Observable<EscalaDiacono> {
    return this.http.put<EscalaDiacono>(`${this.api}/diaconia/escalas/${id}`, data);
  }

  // ==========================================
  // 3. COTAS CONCILIARES & ORÇAMENTO
  // ==========================================
  getCotas(ano?: number): Observable<any> {
    let p = new HttpParams();
    if (ano) p = p.set('ano', ano);
    return this.http.get(`${this.api}/cotas-orcamento/cotas`, { params: p });
  }

  calcularCotaMes(data: { ano: number; mes: number; base_calculo?: number; aliquota_presbiterio_pct?: number; aliquota_supremo_concilio_pct?: number }): Observable<CotaConciliar> {
    return this.http.post<CotaConciliar>(`${this.api}/cotas-orcamento/cotas/calcular`, data);
  }

  atualizarPagamentoCota(id: number, data: Partial<CotaConciliar>): Observable<CotaConciliar> {
    return this.http.put<CotaConciliar>(`${this.api}/cotas-orcamento/cotas/${id}/pagamento`, data);
  }

  getComparativoOrcamento(ano?: number): Observable<ComparativoOrcamentoResponse> {
    let p = new HttpParams();
    if (ano) p = p.set('ano', ano);
    return this.http.get<ComparativoOrcamentoResponse>(`${this.api}/cotas-orcamento/orcamento/comparativo`, { params: p });
  }

  createLinhaOrcamento(data: any): Observable<any> {
    return this.http.post(`${this.api}/cotas-orcamento/orcamento/linhas`, data);
  }

  deleteLinhaOrcamento(id: number): Observable<any> {
    return this.http.delete(`${this.api}/cotas-orcamento/orcamento/linhas/${id}`);
  }

  // ==========================================
  // 4. EXAME DE CONTAS
  // ==========================================
  getPareceres(params?: { ano?: number; resultado?: string; page?: number }): Observable<any> {
    let p = new HttpParams();
    if (params?.ano) p = p.set('ano', params.ano);
    if (params?.resultado) p = p.set('resultado', params.resultado);
    if (params?.page) p = p.set('page', params.page);
    return this.http.get(`${this.api}/exame-contas/pareceres`, { params: p });
  }

  auditarPeriodo(ano: number, periodo: string): Observable<any> {
    let p = new HttpParams().set('ano', ano).set('periodo', periodo);
    return this.http.get(`${this.api}/exame-contas/auditar-periodo`, { params: p });
  }

  createParecer(data: Partial<ParecerExameContas>): Observable<ParecerExameContas> {
    return this.http.post<ParecerExameContas>(`${this.api}/exame-contas/pareceres`, data);
  }

  updateParecer(id: number, data: Partial<ParecerExameContas>): Observable<ParecerExameContas> {
    return this.http.put<ParecerExameContas>(`${this.api}/exame-contas/pareceres/${id}`, data);
  }
}
