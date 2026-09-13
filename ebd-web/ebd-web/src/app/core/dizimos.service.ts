import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import {
  ColetaDizimo,
  LancamentoDizimo,
  AlertaDizimo,
  AcompanhamentoDizimo,
  SolicitacaoDiaconato,
  PastoralDashboardStats,
  MemberFinancialHistory,
  TithesSettings,
  AuditLog,
  Paginated,
} from './models';

@Injectable({ providedIn: 'root' })
export class DizimosService {
  private http = inject(HttpClient);
  private baseUrl = `${environment.apiUrl}/dizimos`;

  // --- Coletas ---
  getColetas(params?: { status?: string; date_from?: string; date_to?: string; page?: number }): Observable<Paginated<ColetaDizimo>> {
    let p = new HttpParams();
    if (params?.status) p = p.set('status', params.status);
    if (params?.date_from) p = p.set('date_from', params.date_from);
    if (params?.date_to) p = p.set('date_to', params.date_to);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<Paginated<ColetaDizimo>>(`${this.baseUrl}/coletas`, { params: p });
  }

  openColeta(data: { date: string; service_meeting?: string; description?: string; notes?: string }): Observable<ColetaDizimo> {
    return this.http.post<ColetaDizimo>(`${this.baseUrl}/coletas`, data);
  }

  getColeta(id: number): Observable<ColetaDizimo> {
    return this.http.get<ColetaDizimo>(`${this.baseUrl}/coletas/${id}`);
  }

  addLancamento(coletaId: number, data: {
    person_id?: number | null;
    amount: number;
    contribution_type?: string;
    is_unidentified?: boolean;
    notes?: string;
    force?: boolean;
  }): Observable<{ duplicate?: boolean; message?: string; lancamento?: LancamentoDizimo; coleta_summary?: unknown }> {
    return this.http.post<{ duplicate?: boolean; message?: string; lancamento?: LancamentoDizimo; coleta_summary?: unknown }>(
      `${this.baseUrl}/coletas/${coletaId}/lancamentos`,
      data
    );
  }

  closeColeta(coletaId: number, verifierId?: number): Observable<ColetaDizimo> {
    return this.http.post<ColetaDizimo>(`${this.baseUrl}/coletas/${coletaId}/fechar`, { verifier_id: verifierId });
  }

  reopenColeta(coletaId: number, reason: string): Observable<ColetaDizimo> {
    return this.http.post<ColetaDizimo>(`${this.baseUrl}/coletas/${coletaId}/reabrir`, { reason });
  }

  updateLancamento(coletaId: number, lancamentoId: number, data: { amount?: number; notes?: string; reason: string }): Observable<LancamentoDizimo> {
    return this.http.put<LancamentoDizimo>(`${this.baseUrl}/coletas/${coletaId}/lancamentos/${lancamentoId}`, data);
  }

  // --- Pastoral ---
  getPastoralDashboard(): Observable<PastoralDashboardStats> {
    return this.http.get<PastoralDashboardStats>(`${this.baseUrl}/pastoral/dashboard`);
  }

  getAlerts(params?: { status?: string; type?: string; page?: number }): Observable<Paginated<AlertaDizimo>> {
    let p = new HttpParams();
    if (params?.status) p = p.set('status', params.status);
    if (params?.type) p = p.set('type', params.type);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<Paginated<AlertaDizimo>>(`${this.baseUrl}/pastoral/alertas`, { params: p });
  }

  getAlert(id: number): Observable<AlertaDizimo> {
    return this.http.get<AlertaDizimo>(`${this.baseUrl}/pastoral/alertas/${id}`);
  }

  addAcompanhamento(alertaId: number, data: {
    date?: string;
    type?: string;
    notes: string;
    next_action?: string;
    review_date?: string;
    alerta_status?: string;
    conclusion?: string;
  }): Observable<AcompanhamentoDizimo> {
    return this.http.post<AcompanhamentoDizimo>(`${this.baseUrl}/pastoral/alertas/${alertaId}/acompanhamentos`, data);
  }

  getMemberHistory(personId: number): Observable<MemberFinancialHistory> {
    return this.http.get<MemberFinancialHistory>(`${this.baseUrl}/membros/${personId}/historico`);
  }

  createDiaconatoRequest(data: { person_id: number; pastor_notes: string }): Observable<SolicitacaoDiaconato> {
    return this.http.post<SolicitacaoDiaconato>(`${this.baseUrl}/pastoral/solicitar-diaconato`, data);
  }

  runAlertEngine(year?: number, month?: number): Observable<{ processed: number; alerts_created: number; alerts_updated: number }> {
    let p = new HttpParams();
    if (year) p = p.set('year', year.toString());
    if (month) p = p.set('month', month.toString());
    return this.http.post<{ processed: number; alerts_created: number; alerts_updated: number }>(`${this.baseUrl}/pastoral/run-engine`, {}, { params: p });
  }

  // --- Diaconato ---
  getDiaconatoRequests(params?: { status?: string; page?: number }): Observable<Paginated<SolicitacaoDiaconato>> {
    let p = new HttpParams();
    if (params?.status) p = p.set('status', params.status);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<Paginated<SolicitacaoDiaconato>>(`${this.baseUrl}/diaconato/solicitacoes`, { params: p });
  }

  updateDiaconatoRequest(id: number, status: string): Observable<SolicitacaoDiaconato> {
    return this.http.put<SolicitacaoDiaconato>(`${this.baseUrl}/diaconato/solicitacoes/${id}`, { status });
  }

  // --- Relatórios Agregados ---
  getGeneralReport(year?: number, month?: number): Observable<unknown> {
    let p = new HttpParams();
    if (year) p = p.set('year', year.toString());
    if (month) p = p.set('month', month.toString());
    return this.http.get<unknown>(`${this.baseUrl}/relatorios/geral`, { params: p });
  }

  // --- Configurações & Auditoria ---
  getSettings(): Observable<TithesSettings> {
    return this.http.get<TithesSettings>(`${this.baseUrl}/settings`);
  }

  updateSettings(settings: Partial<TithesSettings>): Observable<TithesSettings> {
    return this.http.put<TithesSettings>(`${this.baseUrl}/settings`, settings);
  }

  getAuditLogs(params?: { action?: string; entity?: string; page?: number }): Observable<Paginated<AuditLog>> {
    let p = new HttpParams();
    if (params?.action) p = p.set('action', params.action);
    if (params?.entity) p = p.set('entity', params.entity);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<Paginated<AuditLog>>(`${this.baseUrl}/auditoria`, { params: p });
  }
}
