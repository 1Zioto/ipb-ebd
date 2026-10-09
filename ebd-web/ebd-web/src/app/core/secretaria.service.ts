import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface CanonicalStats {
  total: number;
  comungantes: number;
  nao_comungantes: number;
  sob_disciplina: number;
  jurisdicao_especial: number;
  falecidos: number;
}

export interface CanonicalMember {
  id: number;
  full_name: string;
  birth_date?: string;
  age?: number;
  gender?: string;
  phone?: string;
  email?: string;
  cpf?: string;
  is_active?: boolean;
  can_teach?: boolean;
  can_superintend?: boolean;
  is_tither?: boolean;
  envelope_number?: string;
  canonical_status: 'comungante' | 'nao_comungante' | 'sob_disciplina' | 'jurisdicao_especial' | 'falecido';
  roll_number?: string;
  reception_type?: string;
  reception_date?: string;
  baptism_date?: string;
  profession_date?: string;
  exit_type?: string;
  exit_date?: string;
  marital_status?: string;
  spouse_name?: string;
  marriage_date?: string;
  notes?: string;
  families?: { id: number; name: string }[];
}

export interface EstatisticaPresbiterio {
  ano: number;
  igreja: string;
  presbiterio: string;
  comungantes_atual: number;
  nao_comungantes_atual: number;
  sob_disciplina_atual: number;
  total_membros: number;
  movimento_ano: {
    recebidos_profissao_batismo: number;
    recebidos_profissao: number;
    recebidos_transferencia: number;
    saidas_transferencia: number;
    saidas_falecimento: number;
    casamentos: number;
    batismos_infantis: number;
  };
}

export interface CartaTransferencia {
  id: number;
  numero_carta: string;
  tipo: 'Emitida' | 'Recebida';
  person_id: number;
  person?: { id: number; full_name: string; roll_number?: string };
  igreja_origem: string;
  igreja_destino: string;
  cidade_uf?: string;
  data_emissao: string;
  data_validade?: string;
  observacoes?: string;
  status: 'Ativa' | 'Concluída' | 'Expirada' | 'Cancelada';
}

export interface AtaConselho {
  id: number;
  numero_ata: string;
  tipo: 'Ordinária' | 'Extraordinária';
  data_reuniao: string;
  horario?: string;
  local?: string;
  pastor_presidente?: string;
  secretario_conselho?: string;
  presbiters_presentes?: string[];
  abertura?: string;
  pauta?: string;
  deliberacoes?: string;
  ata_original?: string;
  status: 'Rascunho' | 'Aprovada' | 'Assinada';
}

export interface SociedadeMembro {
  id: number;
  sociedade_id: number;
  person_id: number;
  tipo_socio: 'efetivo' | 'cooperador';
  data_admissao?: string;
  status: 'ativo' | 'inativo' | 'licenciado';
  cargo_atual?: string;
  observacoes?: string;
  person?: {
    id: number;
    full_name: string;
    phone?: string;
    email?: string;
    canonical_status?: string;
    birth_date?: string;
  };
}

export interface SociedadeAta {
  id: number;
  sociedade_id: number;
  numero_ata: string;
  titulo: string;
  tipo_reuniao: string;
  data_reuniao: string;
  horario?: string;
  local?: string;
  presidente_id?: number;
  presidente?: { id: number; full_name: string };
  secretario_id?: number;
  secretario?: { id: number; full_name: string };
  pauta?: string;
  conteudo: string;
  presentes_count: number;
  status: 'Rascunho' | 'Aprovada' | 'Assinada';
  visto_conselho_data?: string;
  visto_conselho_relator?: string;
}

export interface SociedadeInterna {
  id: number;
  sigla: string;
  nome: string;
  lema?: string;
  faixa_etaria?: string;
  ano_exercicio: number;
  diretorias?: { id: number; cargo: string; ano: number; person: { id: number; full_name: string; phone?: string; email?: string } }[];
  atividades?: { id: number; titulo: string; data: string; horario?: string; tipo: string; local?: string; descricao?: string }[];
  membros?: SociedadeMembro[];
  atas?: SociedadeAta[];
  membros_count?: number;
  atas_count?: number;
  costCenter?: { id: number; code: string; name: string };
}

export interface CatecumenoDiscipulo {
  id: number;
  person_id: number;
  person?: { id: number; full_name: string; phone?: string; email?: string };
  mentor_id?: number;
  mentor?: { id: number; name: string };
  fase: 'Classe de Catecúmenos' | 'Novo Convertido' | 'Apto para Batismo/Profissão' | 'Concluído';
  data_inicio: string;
  data_conclusao?: string;
  licoes_concluidas: number;
  total_licoes: number;
  observacoes?: string;
}

export interface LivroBiblioteca {
  id: number;
  titulo: string;
  autor: string;
  categoria: string;
  editora?: string;
  ano?: number;
  isbn?: string;
  quantidade_total: number;
  quantidade_disponivel: number;
  localizacao?: string;
}

export interface EmprestimoLivro {
  id: number;
  livro_id: number;
  livro?: { id: number; titulo: string; autor: string; categoria: string };
  person_id: number;
  person?: { id: number; full_name: string; phone?: string };
  data_emprestimo: string;
  data_prevista_devolucao: string;
  data_devolucao?: string;
  status: 'Emprestado' | 'Devolvido' | 'Atrasado';
  observacoes?: string;
}

export interface TermoBalancete {
  ano: number;
  mes: number;
  mes_extenso: string;
  igreja: string;
  cnpj: string;
  saldo_anterior: number;
  entradas: number;
  saidas: number;
  saldo_atual: number;
  parecer_texto: string;
  assinaturas: { titulo: string; nome: string }[];
  data_emissao: string;
}

export interface FichaMinisterial {
  person?: CanonicalMember;
  membro: CanonicalMember;
  cargos_atuais: { sociedade: string; sigla?: string; cargo: string; tipo_socio?: string; data_admissao?: string; ano?: number }[];
  classes_aluno?: string[];
  classes_professor?: string[];
  familias?: { id: number; name: string; relationship?: string; is_head?: boolean }[];
  historico_transferencias?: CartaTransferencia[];
  igreja?: string;
  presbiterio?: string;
  pastor_presidente?: string;
  data_emissao?: string;
  hora_emissao?: string;
  codigo_autenticidade?: string;
}

@Injectable({ providedIn: 'root' })
export class SecretariaService {
  private http = inject(HttpClient);
  private api = environment.apiUrl;

  // 🏛️ Secretaria & Rol Canônico
  getMembros(params?: { status?: string; search?: string; page?: number }): Observable<{ membros: { data: CanonicalMember[]; current_page: number; last_page: number; total: number }; stats: CanonicalStats }> {
    let p = new HttpParams();
    if (params?.status) p = p.set('status', params.status);
    if (params?.search) p = p.set('search', params.search);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<{ membros: { data: CanonicalMember[]; current_page: number; last_page: number; total: number }; stats: CanonicalStats }>(`${this.api}/secretaria/membros`, { params: p });
  }

  getMembro(id: number): Observable<CanonicalMember> {
    return this.http.get<CanonicalMember>(`${this.api}/secretaria/membros/${id}`);
  }

  updateMembro(id: number, data: Partial<CanonicalMember>): Observable<CanonicalMember> {
    return this.http.put<CanonicalMember>(`${this.api}/secretaria/membros/${id}`, data);
  }

  getEstatisticaPresbiterio(ano?: number): Observable<EstatisticaPresbiterio> {
    let p = new HttpParams();
    if (ano) p = p.set('ano', ano.toString());
    return this.http.get<EstatisticaPresbiterio>(`${this.api}/secretaria/estatistica-presbiterio`, { params: p });
  }

  // Cartas de Transferência
  getCartas(params?: { tipo?: string; status?: string; page?: number }): Observable<{ data: CartaTransferencia[]; total: number; current_page: number; last_page: number }> {
    let p = new HttpParams();
    if (params?.tipo) p = p.set('tipo', params.tipo);
    if (params?.status) p = p.set('status', params.status);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<{ data: CartaTransferencia[]; total: number; current_page: number; last_page: number }>(`${this.api}/secretaria/cartas`, { params: p });
  }

  createCarta(data: Partial<CartaTransferencia>): Observable<CartaTransferencia> {
    return this.http.post<CartaTransferencia>(`${this.api}/secretaria/cartas`, data);
  }

  // Livro de Atas do Conselho
  getAtas(params?: { tipo?: string; search?: string; page?: number }): Observable<{ data: AtaConselho[]; total: number; current_page: number; last_page: number }> {
    let p = new HttpParams();
    if (params?.tipo) p = p.set('tipo', params.tipo);
    if (params?.search) p = p.set('search', params.search);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<{ data: AtaConselho[]; total: number; current_page: number; last_page: number }>(`${this.api}/secretaria/atas`, { params: p });
  }

  createAta(data: Partial<AtaConselho>): Observable<AtaConselho> {
    return this.http.post<AtaConselho>(`${this.api}/secretaria/atas`, data);
  }

  updateAta(id: number, data: Partial<AtaConselho>): Observable<AtaConselho> {
    return this.http.put<AtaConselho>(`${this.api}/secretaria/atas/${id}`, data);
  }

  aprovarAta(id: number): Observable<{ message: string; ata: AtaConselho }> {
    return this.http.patch<{ message: string; ata: AtaConselho }>(`${this.api}/secretaria/atas/${id}/aprovar`, {});
  }

  // 👥 Sociedades Internas
  getSociedades(): Observable<{ sociedades: SociedadeInterna[]; membros_potenciais: Record<string, number> }> {
    return this.http.get<{ sociedades: SociedadeInterna[]; membros_potenciais: Record<string, number> }>(`${this.api}/sociedades`);
  }

  getSociedade(id: number): Observable<SociedadeInterna> {
    return this.http.get<SociedadeInterna>(`${this.api}/sociedades/${id}`);
  }

  createSociedade(data: Partial<SociedadeInterna>): Observable<SociedadeInterna> {
    return this.http.post<SociedadeInterna>(`${this.api}/sociedades`, data);
  }

  updateSociedade(id: number, data: Partial<SociedadeInterna>): Observable<SociedadeInterna> {
    return this.http.put<SociedadeInterna>(`${this.api}/sociedades/${id}`, data);
  }

  deleteSociedade(id: number): Observable<any> {
    return this.http.delete(`${this.api}/sociedades/${id}`);
  }

  addSociedadeDiretoria(sociedadeId: number, data: { cargo: string; person_id: number; ano?: number }): Observable<any> {
    return this.http.post(`${this.api}/sociedades/${sociedadeId}/diretoria`, data);
  }

  addSociedadeAtividade(sociedadeId: number, data: { titulo: string; data: string; horario?: string; tipo?: string; local?: string; descricao?: string }): Observable<any> {
    return this.http.post(`${this.api}/sociedades/${sociedadeId}/atividades`, data);
  }

  // 👥 Rol de Sócios / Membros da Sociedade
  getSociedadeMembros(sociedadeId: number): Observable<{ sociedade_id: number; total: number; efetivos: number; cooperadores: number; data: SociedadeMembro[] }> {
    return this.http.get<any>(`${this.api}/sociedades/${sociedadeId}/membros`);
  }

  addSociedadeMembro(sociedadeId: number, data: any): Observable<SociedadeMembro> {
    return this.http.post<SociedadeMembro>(`${this.api}/sociedades/${sociedadeId}/membros`, data);
  }

  arrolarMembrosEmLote(sociedadeId: number, data: { person_ids: number[]; tipo_socio?: string }): Observable<{ message: string; adicionados: number }> {
    return this.http.post<any>(`${this.api}/sociedades/${sociedadeId}/membros/em-lote`, data);
  }

  removeSociedadeMembro(sociedadeId: number, membroId: number): Observable<any> {
    return this.http.delete(`${this.api}/sociedades/${sociedadeId}/membros/${membroId}`);
  }

  // 📖 Livro de Atas da Sociedade
  getSociedadeAtas(sociedadeId: number): Observable<{ sociedade_id: number; total: number; data: SociedadeAta[] }> {
    return this.http.get<any>(`${this.api}/sociedades/${sociedadeId}/atas`);
  }

  addSociedadeAta(sociedadeId: number, data: any): Observable<SociedadeAta> {
    return this.http.post<SociedadeAta>(`${this.api}/sociedades/${sociedadeId}/atas`, data);
  }

  updateSociedadeAta(sociedadeId: number, ataId: number, data: any): Observable<SociedadeAta> {
    return this.http.put<SociedadeAta>(`${this.api}/sociedades/${sociedadeId}/atas/${ataId}`, data);
  }

  deleteSociedadeAta(sociedadeId: number, ataId: number): Observable<any> {
    return this.http.delete(`${this.api}/sociedades/${sociedadeId}/atas/${ataId}`);
  }

  // 📖 Discipulado & Catecúmenos
  getDiscipulado(params?: { fase?: string; page?: number }): Observable<{ items: { data: CatecumenoDiscipulo[]; current_page: number; last_page: number; total: number }; stats: any }> {
    let p = new HttpParams();
    if (params?.fase) p = p.set('fase', params.fase);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<any>(`${this.api}/discipulado-biblioteca/discipulado`, { params: p });
  }

  createCatecumeno(data: any): Observable<CatecumenoDiscipulo> {
    return this.http.post<CatecumenoDiscipulo>(`${this.api}/discipulado-biblioteca/discipulado`, data);
  }

  updateCatecumeno(id: number, data: any): Observable<CatecumenoDiscipulo> {
    return this.http.put<CatecumenoDiscipulo>(`${this.api}/discipulado-biblioteca/discipulado/${id}`, data);
  }

  // Biblioteca
  getLivros(params?: { categoria?: string; search?: string; page?: number }): Observable<{ livros: { data: LivroBiblioteca[]; total: number; current_page: number; last_page: number }; stats: any }> {
    let p = new HttpParams();
    if (params?.categoria) p = p.set('categoria', params.categoria);
    if (params?.search) p = p.set('search', params.search);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<any>(`${this.api}/discipulado-biblioteca/livros`, { params: p });
  }

  createLivro(data: any): Observable<LivroBiblioteca> {
    return this.http.post<LivroBiblioteca>(`${this.api}/discipulado-biblioteca/livros`, data);
  }

  getEmprestimos(params?: { status?: string; page?: number }): Observable<{ data: EmprestimoLivro[]; total: number; current_page: number; last_page: number }> {
    let p = new HttpParams();
    if (params?.status) p = p.set('status', params.status);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<any>(`${this.api}/discipulado-biblioteca/emprestimos`, { params: p });
  }

  createEmprestimo(data: any): Observable<EmprestimoLivro> {
    return this.http.post<EmprestimoLivro>(`${this.api}/discipulado-biblioteca/emprestimos`, data);
  }

  devolverEmprestimo(id: number): Observable<EmprestimoLivro> {
    return this.http.post<EmprestimoLivro>(`${this.api}/discipulado-biblioteca/emprestimos/${id}/devolver`, {});
  }

  // 📊 Relatórios Oficiais com Assinaturas
  getTermoBalancete(year?: number, month?: number): Observable<TermoBalancete> {
    let p = new HttpParams();
    if (year) p = p.set('year', year.toString());
    if (month) p = p.set('month', month.toString());
    return this.http.get<TermoBalancete>(`${this.api}/relatorios-oficiais/termo-balancete`, { params: p });
  }

  getFichaMinisterial(personId: number): Observable<FichaMinisterial> {
    return this.http.get<FichaMinisterial>(`${this.api}/relatorios-oficiais/ficha-ministerial/${personId}`);
  }
}
