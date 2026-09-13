import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../environments/environment';
import { AttendanceRecord, CallSummary, EbdSession } from './models';

interface RecordsResponse { session: EbdSession; records: AttendanceRecord[]; summary: CallSummary; }

@Injectable({ providedIn: 'root' })
export class CallService {
  private http = inject(HttpClient);
  private base = (id: number) => `${environment.apiUrl}/sessions/${id}`;

  open(id: number): Promise<RecordsResponse> {
    return firstValueFrom(this.http.post<RecordsResponse>(`${this.base(id)}/open`, {}));
  }
  records(id: number): Promise<RecordsResponse> {
    return firstValueFrom(this.http.get<RecordsResponse>(`${this.base(id)}/records`));
  }
  saveAttendance(id: number, records: Array<{ person_id: number; present: boolean; brought_bible?: boolean | null; brought_magazine?: boolean | null }>): Promise<RecordsResponse> {
    return firstValueFrom(this.http.put<RecordsResponse>(`${this.base(id)}/attendance`, { records }));
  }
  setTeacher(id: number, personId: number | null): Promise<{ data: EbdSession }> {
    return firstValueFrom(this.http.put<{ data: EbdSession }>(`${this.base(id)}/teacher`, { person_id: personId }));
  }
  setMaterials(id: number, payload: { material_mode: string; bibles_total?: number; magazines_total?: number }): Promise<{ data: EbdSession }> {
    return firstValueFrom(this.http.put<{ data: EbdSession }>(`${this.base(id)}/materials`, payload));
  }
  finalize(id: number): Promise<{ session: EbdSession; summary: CallSummary }> {
    return firstValueFrom(this.http.post<{ session: EbdSession; summary: CallSummary }>(`${this.base(id)}/finalize`, {}));
  }
  reopen(id: number): Promise<{ data: EbdSession }> {
    return firstValueFrom(this.http.post<{ data: EbdSession }>(`${this.base(id)}/reopen`, {}));
  }
}
