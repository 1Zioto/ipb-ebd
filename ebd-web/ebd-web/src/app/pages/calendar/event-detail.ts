import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { AuthService } from '../../core/auth.service';
import { EventsService } from '../../core/events.service';
import { PeopleService } from '../../core/people.service';
import { EbdEvent, EbdSession, Person } from '../../core/models';

@Component({
  selector: 'app-event-detail',
  imports: [FormsModule, RouterLink],
  templateUrl: './event-detail.html',
  styleUrl: './calendar.scss',
})
export class EventDetailPage implements OnInit {
  private route = inject(ActivatedRoute);
  private svc = inject(EventsService);
  private peopleSvc = inject(PeopleService);
  private auth = inject(AuthService);

  eventId = 0;
  event = signal<EbdEvent | null>(null);
  superintendents = signal<Person[]>([]);
  selectedSuper = signal<number | null>(null);
  error = signal<string | null>(null);

  canEditSession = computed(() => this.auth.can('call.edit'));
  canAssignSuper = computed(() => this.auth.can('superintendent.assign'));

  // painel de status por sessão
  statusEditing = signal<number | null>(null);
  statusForm = signal<{ status: string; status_reason: string }>({ status: 'nao_realizada', status_reason: '' });

  async ngOnInit() {
    this.eventId = Number(this.route.snapshot.paramMap.get('id'));
    await Promise.all([this.load(), this.loadSupers()]);
  }

  async load() {
    const e = (await this.svc.get(this.eventId)).data;
    this.event.set(e);
    this.selectedSuper.set(e.superintendent_person_id);
  }
  async loadSupers() {
    const all = (await this.peopleSvc.list({ is_active: true, per_page: 500 })).data;
    this.superintendents.set(all.filter(p => p.can_superintend));
  }

  async saveSuper() {
    this.error.set(null);
    try { await this.svc.setSuperintendent(this.eventId, this.selectedSuper()); await this.load(); }
    catch (e: any) { this.error.set(e?.error?.message || 'Erro ao definir superintendente.'); }
  }

  openStatus(s: EbdSession) {
    this.statusEditing.set(s.id);
    this.statusForm.set({ status: s.status === 'pendente' ? 'nao_realizada' : s.status, status_reason: s.status_reason || '' });
  }
  patchStatus(k: 'status' | 'status_reason', v: string) { this.statusForm.update(f => ({ ...f, [k]: v })); }
  async saveStatus(s: EbdSession) {
    this.error.set(null);
    try {
      await this.svc.setSessionStatus(s.id, { status: this.statusForm().status, status_reason: this.statusForm().status_reason || undefined });
      this.statusEditing.set(null);
      await this.load();
    } catch (e: any) { this.error.set(e?.error?.message || 'Erro ao alterar status.'); }
  }

  typeLabel(t: string) { return ({ regular: 'Regular', especial: 'Especial', evento: 'Evento', outro: 'Outro' } as any)[t] || t; }
  statusLabel(s: string) {
    return ({ pendente:'Pendente', em_andamento:'Em andamento', finalizada:'Finalizada', cancelada:'Cancelada',
      classe_unificada:'Classe unificada', nao_realizada:'Não realizada', evento_especial:'Evento especial' } as any)[s] || s;
  }
}
