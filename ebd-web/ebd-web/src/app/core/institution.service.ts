import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import {
  ConsolidatedStats,
  CultRevenueItem,
  DrilldownStats,
  Institution,
  InstitutionBreadcrumb,
  InstitutionSubordinateSummary,
  InstitutionTreeNode,
  Paginated,
} from './models';

@Injectable({ providedIn: 'root' })
export class InstitutionService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/institutions`;

  list(params?: { search?: string; type?: string; status?: string; parent_institution_id?: number; page?: number; per_page?: number }): Observable<Paginated<Institution>> {
    let p = new HttpParams();
    if (params?.search) p = p.set('search', params.search);
    if (params?.type) p = p.set('type', params.type);
    if (params?.status) p = p.set('status', params.status);
    if (params?.parent_institution_id) p = p.set('parent_institution_id', String(params.parent_institution_id));
    if (params?.page) p = p.set('page', String(params.page));
    if (params?.per_page) p = p.set('per_page', String(params.per_page));

    return this.http.get<Paginated<Institution>>(this.apiUrl, { params: p });
  }

  getTree(rootId?: number): Observable<{ root_id: number | null; tree: InstitutionTreeNode[] }> {
    let p = new HttpParams();
    if (rootId) p = p.set('root_id', String(rootId));

    return this.http.get<{ root_id: number | null; tree: InstitutionTreeNode[] }>(`${this.apiUrl}/tree`, { params: p });
  }

  get(id: number): Observable<{ data: Institution; breadcrumbs: InstitutionBreadcrumb[] }> {
    return this.http.get<{ data: Institution; breadcrumbs: InstitutionBreadcrumb[] }>(`${this.apiUrl}/${id}`);
  }

  create(data: Partial<Institution>): Observable<{ message: string; data: Institution }> {
    return this.http.post<{ message: string; data: Institution }>(this.apiUrl, data);
  }

  update(id: number, data: Partial<Institution>): Observable<{ message: string; data: Institution }> {
    return this.http.put<{ message: string; data: Institution }>(`${this.apiUrl}/${id}`, data);
  }

  delete(id: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${this.apiUrl}/${id}`);
  }

  getSubordinates(id: number): Observable<{ parent_institution_id: number; subordinates: InstitutionSubordinateSummary[] }> {
    return this.http.get<{ parent_institution_id: number; subordinates: InstitutionSubordinateSummary[] }>(`${this.apiUrl}/${id}/subordinates`);
  }

  getBreadcrumbs(id: number): Observable<InstitutionBreadcrumb[]> {
    return this.http.get<InstitutionBreadcrumb[]>(`${this.apiUrl}/${id}/breadcrumbs`);
  }

  transfer(id: number, newParentId: number | null, reason: string): Observable<{ message: string; data: Institution }> {
    return this.http.post<{ message: string; data: Institution }>(`${this.apiUrl}/${id}/transfer`, {
      new_parent_id: newParentId,
      reason,
    });
  }

  getHistory(id: number, page: number = 1): Observable<Paginated<any>> {
    const p = new HttpParams().set('page', String(page));
    return this.http.get<Paginated<any>>(`${this.apiUrl}/${id}/history`, { params: p });
  }

  getDashboardSummary(id: number, consolidated: boolean = true, year?: number, month?: number): Observable<ConsolidatedStats> {
    let p = new HttpParams().set('consolidated', String(consolidated));
    if (year) p = p.set('year', String(year));
    if (month) p = p.set('month', String(month));

    return this.http.get<ConsolidatedStats>(`${this.apiUrl}/${id}/dashboard/summary`, { params: p });
  }

  getDashboardDrilldown(id: number, metric: string): Observable<DrilldownStats> {
    const p = new HttpParams().set('metric', metric);
    return this.http.get<DrilldownStats>(`${this.apiUrl}/${id}/dashboard/drilldown`, { params: p });
  }

  getCultByCult(id: number, consolidated: boolean = true, limit: number = 12): Observable<CultRevenueItem[]> {
    const p = new HttpParams()
      .set('consolidated', String(consolidated))
      .set('limit', String(limit));

    return this.http.get<CultRevenueItem[]>(`${this.apiUrl}/${id}/dashboard/cults`, { params: p });
  }

  // --- Vínculos por Código & Aprovações ---
  getByCode(code: string): Observable<{ data: Institution }> {
    return this.http.get<{ data: Institution }>(`${this.apiUrl}/by-code/${code}`);
  }

  getLinkRequests(institutionId?: number, status?: string): Observable<{ received: import('./models').InstitutionLinkRequest[]; sent: import('./models').InstitutionLinkRequest[] }> {
    let p = new HttpParams();
    if (institutionId) p = p.set('institution_id', String(institutionId));
    if (status) p = p.set('status', status);

    return this.http.get<{ received: import('./models').InstitutionLinkRequest[]; sent: import('./models').InstitutionLinkRequest[] }>(`${this.apiUrl}/link-requests/list`, { params: p });
  }

  createLinkRequest(data: { requester_institution_id?: number; target_code: string; type: string; reason?: string }): Observable<{ message: string; data: import('./models').InstitutionLinkRequest }> {
    return this.http.post<{ message: string; data: import('./models').InstitutionLinkRequest }>(`${this.apiUrl}/link-requests`, data);
  }

  acceptLinkRequest(requestId: number, actionNotes?: string): Observable<{ message: string; data: import('./models').InstitutionLinkRequest }> {
    return this.http.post<{ message: string; data: import('./models').InstitutionLinkRequest }>(`${this.apiUrl}/link-requests/${requestId}/accept`, { action_notes: actionNotes });
  }

  rejectLinkRequest(requestId: number, actionNotes?: string): Observable<{ message: string; data: import('./models').InstitutionLinkRequest }> {
    return this.http.post<{ message: string; data: import('./models').InstitutionLinkRequest }>(`${this.apiUrl}/link-requests/${requestId}/reject`, { action_notes: actionNotes });
  }

  cancelLinkRequest(requestId: number): Observable<{ message: string; data: import('./models').InstitutionLinkRequest }> {
    return this.http.post<{ message: string; data: import('./models').InstitutionLinkRequest }>(`${this.apiUrl}/link-requests/${requestId}/cancel`, {});
  }
}
