import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Paginated, Person } from './models';
import { environment } from '../../environments/environment';

export interface MonthlyReport {
  events_count: number;
  total_present: number;
  total_absent: number;
  total_bibles: number;
  total_magazines: number;
}

export interface ClassReport {
  class?: { id: number; name: string };
  sessions: Array<{ session_id: number; date: string; teacher?: string; status: string; present: number; absent: number; bibles: number; magazines: number }>;
}

export interface StudentReport {
  person?: { id: number; full_name: string };
  summary?: { attendance_percentage: number; total_events: number; present: number; absent: number };
  history: Array<{ date: string; class_name: string; present: boolean; brought_bible: boolean; brought_magazine: boolean }>;
}

export interface EbdDashboardSummary {
  metrics: {
    total_students: number;
    total_teachers: number;
    total_classes: number;
    pending_calls: number;
  };
  next_event: {
    id: number;
    event_date: string;
    type: string;
    status: string;
    superintendent_name: string | null;
  } | null;
  birthdays_today: Person[];
  birthdays_week: Person[];
  announcements: { id: number; title: string; content: string; created_at: string }[];
}

export interface SuperintendentLiveMonitor {
  event: {
    id: number;
    event_date: string;
    type: string;
    status: string;
    superintendent: string | null;
  };
  live_summary: {
    present: number;
    absent: number;
    total_enrolled: number;
    bibles: number;
    magazines: number;
  };
  sessions: {
    id: number;
    class_name: string;
    teacher_name: string | null;
    status: string;
    material_mode: string;
    bibles_total: number | null;
    magazines_total: number | null;
    finalized_at: string | null;
  }[];
}

export interface ScheduleItem {
  id: number;
  date: string;
  class_id?: number;
  class_room?: { id: number; name: string };
  teacher_person_id?: number;
  teacher?: { id: number; full_name: string };
  superintendent_person_id?: number;
  superintendent?: { id: number; full_name: string };
}

@Injectable({ providedIn: 'root' })
export class EbdService {
  private http = inject(HttpClient);
  private baseUrl = environment.apiUrl;

  getDashboardSummary(): Observable<EbdDashboardSummary> {
    return this.http.get<EbdDashboardSummary>(`${this.baseUrl}/dashboard/summary`);
  }

  getSuperintendentLive(eventId?: number): Observable<SuperintendentLiveMonitor> {
    const url = eventId
      ? `${this.baseUrl}/dashboard/superintendent-live/${eventId}`
      : `${this.baseUrl}/dashboard/superintendent-live`;
    return this.http.get<SuperintendentLiveMonitor>(url);
  }

  getTeacherSchedules(year?: number, month?: number): Observable<ScheduleItem[]> {
    let p = new HttpParams();
    if (year) p = p.set('year', year.toString());
    if (month) p = p.set('month', month.toString());
    return this.http.get<ScheduleItem[]>(`${this.baseUrl}/schedules/teachers`, { params: p });
  }

  setTeacherSchedule(data: { date: string; class_id: number; teacher_person_id: number }): Observable<ScheduleItem> {
    return this.http.post<ScheduleItem>(`${this.baseUrl}/schedules/teachers`, data);
  }

  getSuperintendentSchedules(year?: number, month?: number): Observable<ScheduleItem[]> {
    let p = new HttpParams();
    if (year) p = p.set('year', year.toString());
    if (month) p = p.set('month', month.toString());
    return this.http.get<ScheduleItem[]>(`${this.baseUrl}/schedules/superintendents`, { params: p });
  }

  setSuperintendentSchedule(data: { date: string; superintendent_person_id: number }): Observable<ScheduleItem> {
    return this.http.post<ScheduleItem>(`${this.baseUrl}/schedules/superintendents`, data);
  }

  getMonthlyReport(year?: number, month?: number): Observable<MonthlyReport> {
    let p = new HttpParams();
    if (year) p = p.set('year', year.toString());
    if (month) p = p.set('month', month.toString());
    return this.http.get<MonthlyReport>(`${this.baseUrl}/reports/ebd/monthly`, { params: p });
  }

  getClassReport(classId: number, dateFrom?: string, dateTo?: string): Observable<ClassReport> {
    let p = new HttpParams();
    if (dateFrom) p = p.set('date_from', dateFrom);
    if (dateTo) p = p.set('date_to', dateTo);
    return this.http.get<ClassReport>(`${this.baseUrl}/reports/ebd/class/${classId}`, { params: p });
  }

  getStudentReport(personId: number, dateFrom?: string, dateTo?: string): Observable<StudentReport> {
    let p = new HttpParams();
    if (dateFrom) p = p.set('date_from', dateFrom);
    if (dateTo) p = p.set('date_to', dateTo);
    return this.http.get<StudentReport>(`${this.baseUrl}/reports/ebd/student/${personId}`, { params: p });
  }

  getAuditLogs(params?: { action?: string; entity?: string; page?: number }): Observable<Paginated<unknown>> {
    let p = new HttpParams();
    if (params?.action) p = p.set('action', params.action);
    if (params?.entity) p = p.set('entity', params.entity);
    if (params?.page) p = p.set('page', params.page.toString());
    return this.http.get<Paginated<unknown>>(`${this.baseUrl}/audit/logs`, { params: p });
  }
}
