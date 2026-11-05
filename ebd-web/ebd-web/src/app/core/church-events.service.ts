import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface ChurchEvent {
  id: number;
  institution_id: number;
  created_by_user_id?: number;
  title: string;
  slug: string;
  theme?: string;
  description?: string;
  event_type: string;
  target_audience: string;
  location_name?: string;
  location_address?: string;
  location_maps_url?: string;
  departure_meeting_point?: string;
  departure_time?: string;
  starts_at: string;
  ends_at?: string;
  registration_starts_at?: string;
  registration_ends_at?: string;
  max_capacity?: number;
  is_paid: boolean;
  price: number;
  pix_key?: string;
  pix_key_type?: string;
  pix_receiver_name?: string;
  instructions?: string;
  contact_phone?: string;
  contact_email?: string;
  require_medical_info: boolean;
  allow_non_members: boolean;
  status: 'draft' | 'published' | 'closed' | 'cancelled';
  total_registrations?: number;
  confirmed_registrations?: number;
  pending_payments?: number;
  confirmed_payments?: number;
  checked_in_count?: number;
  created_at?: string;
  updated_at?: string;
}

export interface ChurchEventRegistration {
  id: number;
  church_event_id: number;
  person_id?: number;
  registration_code: string;
  full_name: string;
  phone: string;
  email?: string;
  cpf?: string;
  birth_date?: string;
  gender?: string;
  is_member: boolean;
  church_name?: string;
  is_minor: boolean;
  guardian_name?: string;
  guardian_phone?: string;
  dietary_restrictions?: string;
  medical_notes?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
  payment_status: 'free' | 'pending' | 'confirmed' | 'rejected';
  payment_amount: number;
  payment_proof_path?: string;
  payment_notes?: string;
  checked_in: boolean;
  checked_in_at?: string;
  status: 'confirmed' | 'cancelled' | 'waitlist';
  notes?: string;
  created_at?: string;
}

export interface ChurchEventStats {
  total: number;
  confirmed: number;
  pending_payment: number;
  confirmed_payment: number;
  checked_in: number;
  total_collected: number;
  capacity?: number;
  remaining_capacity?: number;
}

export interface PublicEventData {
  event: ChurchEvent & {
    institution?: {
      id: number;
      name: string;
      city?: string;
      state?: string;
    };
  };
  availability: {
    is_open: boolean;
    is_full: boolean;
    total_registered: number;
    max_capacity?: number;
    remaining_spots?: number;
  };
}

export interface RegistrationSubmission {
  full_name: string;
  phone: string;
  email?: string;
  cpf?: string;
  birth_date?: string;
  gender?: string;
  is_member: boolean;
  church_name?: string;
  is_minor: boolean;
  guardian_name?: string;
  guardian_phone?: string;
  dietary_restrictions?: string;
  medical_notes?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
  notes?: string;
}

@Injectable({
  providedIn: 'root',
})
export class ChurchEventsService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/church-events`;
  private publicApiUrl = `${environment.apiUrl}/public/events`;

  getEvents(params?: { search?: string; status?: string; per_page?: number }): Observable<any> {
    let httpParams = new HttpParams();
    if (params?.search) httpParams = httpParams.set('search', params.search);
    if (params?.status) httpParams = httpParams.set('status', params.status);
    if (params?.per_page) httpParams = httpParams.set('per_page', params.per_page.toString());

    return this.http.get(this.apiUrl, { params: httpParams });
  }

  getEvent(id: number, filters?: { search?: string; payment_status?: string; checked_in?: boolean }): Observable<{
    event: ChurchEvent;
    stats: ChurchEventStats;
    registrations: ChurchEventRegistration[];
  }> {
    let httpParams = new HttpParams();
    if (filters?.search) httpParams = httpParams.set('search', filters.search);
    if (filters?.payment_status) httpParams = httpParams.set('payment_status', filters.payment_status);
    if (filters?.checked_in !== undefined) httpParams = httpParams.set('checked_in', String(filters.checked_in));

    return this.http.get<any>(`${this.apiUrl}/${id}`, { params: httpParams });
  }

  createEvent(data: Partial<ChurchEvent>): Observable<ChurchEvent> {
    return this.http.post<ChurchEvent>(this.apiUrl, data);
  }

  updateEvent(id: number, data: Partial<ChurchEvent>): Observable<ChurchEvent> {
    return this.http.put<ChurchEvent>(`${this.apiUrl}/${id}`, data);
  }

  deleteEvent(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  updateRegistration(eventId: number, regId: number, data: Partial<ChurchEventRegistration>): Observable<ChurchEventRegistration> {
    return this.http.patch<ChurchEventRegistration>(`${this.apiUrl}/${eventId}/registrations/${regId}`, data);
  }

  deleteRegistration(eventId: number, regId: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${eventId}/registrations/${regId}`);
  }

  getExportCsvUrl(eventId: number): string {
    return `${this.apiUrl}/${eventId}/export-csv`;
  }

  // --- Rotas Públicas ---
  getPublicEvent(slug: string): Observable<PublicEventData> {
    return this.http.get<PublicEventData>(`${this.publicApiUrl}/${slug}`);
  }

  submitPublicRegistration(slug: string, data: RegistrationSubmission): Observable<any> {
    return this.http.post<any>(`${this.publicApiUrl}/${slug}/register`, data);
  }
}

