import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../environments/environment';
import { ClassRoom, ClassTeacher, Enrollment } from './models';

export interface ClassCallSession {
  id: number;
  event_id: number;
  event_date: string | null;
  event_type: string | null;
  status: string;
  teacher_name: string | null;
  present: number;
  absent: number;
  total: number;
  bibles: number | null;
  magazines: number | null;
}

@Injectable({ providedIn: 'root' })
export class ClassesService {
  private http = inject(HttpClient);
  private base = `${environment.apiUrl}/classes`;

  list(): Promise<{ data: ClassRoom[] }> {
    return firstValueFrom(this.http.get<{ data: ClassRoom[] }>(this.base));
  }
  get(id: number): Promise<{ data: ClassRoom }> {
    return firstValueFrom(this.http.get<{ data: ClassRoom }>(`${this.base}/${id}`));
  }
  create(payload: Partial<ClassRoom>): Promise<{ data: ClassRoom }> {
    return firstValueFrom(this.http.post<{ data: ClassRoom }>(this.base, payload));
  }
  update(id: number, payload: Partial<ClassRoom>): Promise<{ data: ClassRoom }> {
    return firstValueFrom(this.http.put<{ data: ClassRoom }>(`${this.base}/${id}`, payload));
  }
  remove(id: number): Promise<unknown> {
    return firstValueFrom(this.http.delete(`${this.base}/${id}`));
  }

  sessions(classId: number): Promise<{ data: ClassCallSession[] }> {
    return firstValueFrom(this.http.get<{ data: ClassCallSession[] }>(`${this.base}/${classId}/sessions`));
  }

  // Alunos
  students(classId: number, all = false): Promise<{ data: Enrollment[] }> {
    return firstValueFrom(this.http.get<{ data: Enrollment[] }>(`${this.base}/${classId}/students${all ? '?all=1' : ''}`));
  }
  enroll(classId: number, personId: number): Promise<unknown> {
    return firstValueFrom(this.http.post(`${this.base}/${classId}/students`, { person_id: personId }));
  }
  unenroll(classId: number, personId: number): Promise<unknown> {
    return firstValueFrom(this.http.delete(`${this.base}/${classId}/students/${personId}`));
  }

  // Professores
  teachers(classId: number): Promise<{ data: ClassTeacher[] }> {
    return firstValueFrom(this.http.get<{ data: ClassTeacher[] }>(`${this.base}/${classId}/teachers`));
  }
  addTeacher(classId: number, personId: number): Promise<unknown> {
    return firstValueFrom(this.http.post(`${this.base}/${classId}/teachers`, { person_id: personId }));
  }
  removeTeacher(classId: number, personId: number): Promise<unknown> {
    return firstValueFrom(this.http.delete(`${this.base}/${classId}/teachers/${personId}`));
  }
}
