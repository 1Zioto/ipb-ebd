import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../core/auth.service';
import { EventsService } from '../../core/events.service';
import { EbdEvent } from '../../core/models';

@Component({
  selector: 'app-calendar-month',
  imports: [FormsModule, RouterLink],
  templateUrl: './calendar-month.html',
  styleUrl: './calendar.scss',
})
export class CalendarMonthPage implements OnInit {
  private svc = inject(EventsService);
  private auth = inject(AuthService);

  readonly monthNames = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
  year = signal(2026);
  month = signal(8);
  events = signal<EbdEvent[]>([]);
  loading = signal(false);
  msg = signal<string | null>(null);
  error = signal<string | null>(null);

  canGenerate = computed(() => this.auth.can('event.generate'));
  canAdhoc = computed(() => this.auth.can('event.create_adhoc'));

  showAdhoc = signal(false);
  adhoc = signal<{ event_date: string; type: string; notes: string }>({ event_date: '', type: 'especial', notes: '' });
  savingAdhoc = signal(false);

  async ngOnInit() { await this.load(); }

  async load() {
    this.loading.set(true); this.error.set(null);
    try { this.events.set((await this.svc.listMonth(this.year(), this.month())).data); }
    catch { this.error.set('Erro ao carregar encontros.'); }
    finally { this.loading.set(false); }
  }

  prevMonth() { if (this.month() === 1) { this.month.set(12); this.year.update(y => y - 1); } else this.month.update(m => m - 1); this.load(); }
  nextMonth() { if (this.month() === 12) { this.month.set(1); this.year.update(y => y + 1); } else this.month.update(m => m + 1); this.load(); }

  async generate() {
    this.msg.set(null); this.error.set(null);
    try {
      const r = await this.svc.generate(this.year(), this.month());
      this.msg.set(`${r.createdEvents} encontros criados, ${r.existingEvents} já existiam, ${r.createdSessions} sessões preparadas.`);
      await this.load();
    } catch (e: any) { this.error.set(e?.error?.message || 'Erro ao gerar mês.'); }
  }

  openAdhoc() {
    this.adhoc.set({ event_date: `${this.year()}-${String(this.month()).padStart(2,'0')}-01`, type: 'especial', notes: '' });
    this.showAdhoc.set(true);
  }
  patchAdhoc(k: 'event_date' | 'type' | 'notes', v: string) { this.adhoc.update(a => ({ ...a, [k]: v })); }
  async saveAdhoc() {
    const a = this.adhoc();
    if (!a.event_date) { this.error.set('Informe a data.'); return; }
    this.savingAdhoc.set(true); this.error.set(null);
    try {
      await this.svc.createAdhoc({ event_date: a.event_date, type: a.type, notes: a.notes || undefined });
      this.showAdhoc.set(false);
      await this.load();
    } catch (e: any) { this.error.set(e?.error?.message || 'Erro ao criar encontro.'); }
    finally { this.savingAdhoc.set(false); }
  }

  typeLabel(t: string) { return ({ regular: 'Regular', especial: 'Especial', evento: 'Evento', outro: 'Outro' } as any)[t] || t; }
  statusLabel(s: string) { return ({ pendente: 'Pendente', em_andamento: 'Em andamento', finalizada: 'Finalizada', cancelada: 'Cancelada' } as any)[s] || s; }
}
