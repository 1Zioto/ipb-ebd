import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../environments/environment';
import { Family, FamilyRelationship, Paginated } from './models';

export type FamilyPayload = Omit<Partial<Family>, 'members'> & {
  members?: { person_id: number; relationship: FamilyRelationship; is_head: boolean }[];
};

@Injectable({ providedIn: 'root' })
export class FamiliesService {
  private http = inject(HttpClient);
  private base = `${environment.apiUrl}/families`;

  list(search = ''): Promise<Paginated<Family>> {
    let params = new HttpParams().set('per_page', 100);
    if (search.trim()) params = params.set('search', search.trim());
    return firstValueFrom(this.http.get<Paginated<Family>>(this.base, { params }));
  }

  create(payload: FamilyPayload): Promise<{ data: Family }> {
    return firstValueFrom(this.http.post<{ data: Family }>(this.base, payload));
  }

  update(id: number, payload: FamilyPayload): Promise<{ data: Family }> {
    return firstValueFrom(this.http.put<{ data: Family }>(`${this.base}/${id}`, payload));
  }

  remove(id: number): Promise<{ message: string }> {
    return firstValueFrom(this.http.delete<{ message: string }>(`${this.base}/${id}`));
  }
}
