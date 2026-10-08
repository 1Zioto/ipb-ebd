import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import {
  FinancialAccount,
  FinancialCostCenter,
  FinancialCategory,
  FinancialTransaction,
  FinancialMonthClosing,
  FinancialSummary,
  FinancialLedger,
  FinancialTrialBalance,
} from './models';

export interface PaginatedResponse<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

@Injectable({
  providedIn: 'root',
})
export class FinancialService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/financial`;

  // ---- Transações & Livro Caixa ----
  getTransactions(filters: {
    year?: number;
    month?: number;
    start_date?: string;
    end_date?: string;
    type?: string;
    status?: string;
    account_id?: number;
    cost_center_id?: number;
    category_id?: number;
    search?: string;
    page?: number;
  } = {}): Observable<PaginatedResponse<FinancialTransaction>> {
    let params = new HttpParams();
    Object.entries(filters).forEach(([key, val]) => {
      if (val !== undefined && val !== null && String(val).trim() !== '') {
        params = params.set(key, String(val));
      }
    });
    return this.http.get<PaginatedResponse<FinancialTransaction>>(`${this.apiUrl}/transactions`, { params });
  }

  getTransaction(id: number): Observable<FinancialTransaction> {
    return this.http.get<FinancialTransaction>(`${this.apiUrl}/transactions/${id}`);
  }

  createTransaction(data: Partial<FinancialTransaction>): Observable<FinancialTransaction> {
    return this.http.post<FinancialTransaction>(`${this.apiUrl}/transactions`, data);
  }

  updateTransaction(id: number, data: Partial<FinancialTransaction>): Observable<FinancialTransaction> {
    return this.http.put<FinancialTransaction>(`${this.apiUrl}/transactions/${id}`, data);
  }

  deleteTransaction(id: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${this.apiUrl}/transactions/${id}`);
  }

  getSummary(year?: number, month?: number): Observable<FinancialSummary> {
    let params = new HttpParams();
    if (year) params = params.set('year', String(year));
    if (month) params = params.set('month', String(month));
    return this.http.get<FinancialSummary>(`${this.apiUrl}/transactions/summary`, { params });
  }

  // ---- Contas e Caixas ----
  getAccounts(): Observable<FinancialAccount[]> {
    return this.http.get<FinancialAccount[]>(`${this.apiUrl}/accounts`);
  }

  createAccount(data: Partial<FinancialAccount>): Observable<FinancialAccount> {
    return this.http.post<FinancialAccount>(`${this.apiUrl}/accounts`, data);
  }

  updateAccount(id: number, data: Partial<FinancialAccount>): Observable<FinancialAccount> {
    return this.http.put<FinancialAccount>(`${this.apiUrl}/accounts/${id}`, data);
  }

  deleteAccount(id: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${this.apiUrl}/accounts/${id}`);
  }

  recalculateAccount(id: number): Observable<{ message: string; current_balance: number }> {
    return this.http.post<{ message: string; current_balance: number }>(`${this.apiUrl}/accounts/${id}/recalculate`, {});
  }

  // ---- Categorias Contábeis / Plano de Contas ----
  getCategories(type?: string, tree = false): Observable<FinancialCategory[]> {
    let params = new HttpParams();
    if (type) params = params.set('type', type);
    if (tree) params = params.set('tree', 'true');
    return this.http.get<FinancialCategory[]>(`${this.apiUrl}/categories`, { params });
  }

  createCategory(data: Partial<FinancialCategory>): Observable<FinancialCategory> {
    return this.http.post<FinancialCategory>(`${this.apiUrl}/categories`, data);
  }

  updateCategory(id: number, data: Partial<FinancialCategory>): Observable<FinancialCategory> {
    return this.http.put<FinancialCategory>(`${this.apiUrl}/categories/${id}`, data);
  }

  deleteCategory(id: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${this.apiUrl}/categories/${id}`);
  }

  // ---- Centros de Custo ----
  getCostCenters(year?: number, month?: number): Observable<FinancialCostCenter[]> {
    let params = new HttpParams();
    if (year) params = params.set('year', String(year));
    if (month) params = params.set('month', String(month));
    return this.http.get<FinancialCostCenter[]>(`${this.apiUrl}/cost-centers`, { params });
  }

  createCostCenter(data: Partial<FinancialCostCenter>): Observable<FinancialCostCenter> {
    return this.http.post<FinancialCostCenter>(`${this.apiUrl}/cost-centers`, data);
  }

  updateCostCenter(id: number, data: Partial<FinancialCostCenter>): Observable<FinancialCostCenter> {
    return this.http.put<FinancialCostCenter>(`${this.apiUrl}/cost-centers/${id}`, data);
  }

  deleteCostCenter(id: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${this.apiUrl}/cost-centers/${id}`);
  }

  // ---- Contabilidade, Balancete e Fechamentos ----
  getLedger(filters: {
    year?: number;
    month?: number;
    account_id?: number;
    cost_center_id?: number;
    category_id?: number;
  } = {}): Observable<FinancialLedger> {
    let params = new HttpParams();
    Object.entries(filters).forEach(([key, val]) => {
      if (val !== undefined && val !== null && String(val).trim() !== '') {
        params = params.set(key, String(val));
      }
    });
    return this.http.get<FinancialLedger>(`${this.apiUrl}/accounting/ledger`, { params });
  }

  getTrialBalance(year: number, month?: number): Observable<FinancialTrialBalance> {
    let params = new HttpParams();
    params = params.set('year', String(year));
    if (month) params = params.set('month', String(month));
    return this.http.get<FinancialTrialBalance>(`${this.apiUrl}/accounting/trial-balance`, { params });
  }

  closeMonth(year: number, month: number, notes?: string): Observable<{ message: string; closing: FinancialMonthClosing }> {
    return this.http.post<{ message: string; closing: FinancialMonthClosing }>(`${this.apiUrl}/accounting/close-month`, {
      year,
      month,
      notes,
    });
  }

  reopenMonth(year: number, month: number): Observable<{ message: string; closing: FinancialMonthClosing }> {
    return this.http.post<{ message: string; closing: FinancialMonthClosing }>(`${this.apiUrl}/accounting/reopen-month`, {
      year,
      month,
    });
  }

  getExportCsvUrl(year: number, month?: number): string {
    let url = `${this.apiUrl}/accounting/export-csv?year=${year}`;
    if (month) {
      url += `&month=${month}`;
    }
    return url;
  }
}
