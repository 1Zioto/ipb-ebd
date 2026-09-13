import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../environments/environment';
import { Paginated, Person } from './models';

export interface PersonFilters {
  search?: string;
  is_active?: boolean;
  can_teach?: boolean;
  can_superintend?: boolean;
  page?: number;
  per_page?: number;
}

@Injectable({ providedIn: 'root' })
export class PeopleService {
  private http = inject(HttpClient);
  private base = `${environment.apiUrl}/people`;

  list(filters: PersonFilters = {}): Promise<Paginated<Person>> {
    let params = new HttpParams();
    if (filters.search) params = params.set('search', filters.search);
    if (filters.is_active !== undefined) params = params.set('is_active', String(filters.is_active));
    if (filters.can_teach) params = params.set('can_teach', '1');
    if (filters.can_superintend) params = params.set('can_superintend', '1');
    if (filters.page) params = params.set('page', String(filters.page));
    params = params.set('per_page', String(filters.per_page ?? 20));
    return firstValueFrom(this.http.get<Paginated<Person>>(this.base, { params }));
  }

  create(payload: Partial<Person>): Promise<{ data: Person }> {
    return firstValueFrom(this.http.post<{ data: Person }>(this.base, payload));
  }

  update(id: number, payload: Partial<Person>): Promise<{ data: Person }> {
    return firstValueFrom(this.http.put<{ data: Person }>(`${this.base}/${id}`, payload));
  }

  remove(id: number): Promise<unknown> {
    return firstValueFrom(this.http.delete(`${this.base}/${id}`));
  }

  birthdays(scope: 'today' | 'week'): Promise<{ data: Person[] }> {
    return firstValueFrom(this.http.get<{ data: Person[] }>(`${this.base}/birthdays?scope=${scope}`));
  }
}
