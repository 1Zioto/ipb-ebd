import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../environments/environment';
import { EbdEvent, EbdSession } from './models';

@Injectable({ providedIn: 'root' })
export class EventsService {
  private http = inject(HttpClient);
  private base = `${environment.apiUrl}/events`;

  listMonth(year: number, month: number): Promise<{ data: EbdEvent[] }> {
    return firstValueFrom(this.http.get<{ data: EbdEvent[] }>(`${this.base}?year=${year}&month=${month}`));
  }
  generate(year: number, month: number): Promise<{ createdEvents: number; existingEvents: number; createdSessions: number }> {
    return firstValueFrom(this.http.post<any>(`${this.base}/generate`, { year, month }));
  }
  get(id: number): Promise<{ data: EbdEvent }> {
    return firstValueFrom(this.http.get<{ data: EbdEvent }>(`${this.base}/${id}`));
  }
  createAdhoc(payload: { event_date: string; type: string; notes?: string; class_ids?: number[] }): Promise<{ data: EbdEvent }> {
    return firstValueFrom(this.http.post<{ data: EbdEvent }>(this.base, payload));
  }
  setSuperintendent(id: number, personId: number | null): Promise<{ data: EbdEvent }> {
    return firstValueFrom(this.http.put<{ data: EbdEvent }>(`${this.base}/${id}/superintendent`, { person_id: personId }));
  }
  setSessionStatus(sessionId: number, payload: { status: string; status_reason?: string; merged_into_class_id?: number }): Promise<{ data: EbdSession }> {
    return firstValueFrom(this.http.put<{ data: EbdSession }>(`${environment.apiUrl}/sessions/${sessionId}/status`, payload));
  }
}
