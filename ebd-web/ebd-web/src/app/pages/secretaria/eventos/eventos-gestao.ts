import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { ToastModule } from 'primeng/toast';
import { TooltipModule } from 'primeng/tooltip';
import { ProgressBarModule } from 'primeng/progressbar';
import { MessageService } from 'primeng/api';
import { 
  ChurchEventsService, 
  ChurchEvent, 
  ChurchEventRegistration, 
  ChurchEventStats 
} from '@/app/core/church-events.service';

@Component({
  selector: 'app-eventos-gestao',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    TableModule,
    ButtonModule,
    TagModule,
    DialogModule,
    InputTextModule,
    ToastModule,
    TooltipModule,
    ProgressBarModule,
  ],
  providers: [MessageService],
  templateUrl: './eventos-gestao.html',
})
export class EventosGestaoPage implements OnInit {
  Number = Number;
  private eventsService = inject(ChurchEventsService);
  private msg = inject(MessageService);

  events = signal<ChurchEvent[]>([]);
  loading = signal<boolean>(true);
  searchQuery = '';
  statusFilter = '';

  // KPI globais calculados
  totalEvents = signal<number>(0);
  totalRegistrations = signal<number>(0);
  totalConfirmedPayments = signal<number>(0);
  totalCheckedIn = signal<number>(0);

  // Modal Novo/Edição de Evento
  eventDialog = false;
  isEditing = false;
  currentEventId: number | null = null;
  formEvent: Partial<ChurchEvent> = this.resetEventForm();

  // Modal de Gestão de Inscritos
  participantsDialog = false;
  selectedEvent = signal<ChurchEvent | null>(null);
  selectedEventStats = signal<ChurchEventStats | null>(null);
  registrations = signal<ChurchEventRegistration[]>([]);
  loadingParticipants = signal<boolean>(false);
  participantSearch = '';
  participantPaymentFilter = '';

  ngOnInit(): void {
    this.carregarEventos();
  }

  carregarEventos(): void {
    this.loading.set(true);
    this.eventsService.getEvents({
      search: this.searchQuery || undefined,
      status: this.statusFilter || undefined,
      per_page: 50,
    }).subscribe({
      next: (res) => {
        const list: ChurchEvent[] = res.data || res;
        this.events.set(list);
        this.calcularKpis(list);
        this.loading.set(false);
      },
      error: () => {
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao carregar eventos.' });
        this.loading.set(false);
      },
    });
  }

  calcularKpis(list: ChurchEvent[]): void {
    this.totalEvents.set(list.length);
    let totalReg = 0;
    let totalPaid = 0;
    let totalCheck = 0;

    for (const e of list) {
      totalReg += e.total_registrations || 0;
      totalCheck += e.checked_in_count || 0;
      totalPaid += (e.confirmed_payments || 0) * (e.price || 0);
    }

    this.totalRegistrations.set(totalReg);
    this.totalConfirmedPayments.set(totalPaid);
    this.totalCheckedIn.set(totalCheck);
  }

  resetEventForm(): Partial<ChurchEvent> {
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    return {
      title: '',
      theme: '',
      event_type: 'Retiro / Acampamento',
      target_audience: 'Geral',
      description: '',
      location_name: '',
      location_address: '',
      location_maps_url: '',
      departure_meeting_point: 'Templo da Igreja Presbiteriana',
      departure_time: '19:30',
      starts_at: today.toISOString().substring(0, 16),
      ends_at: tomorrow.toISOString().substring(0, 16),
      max_capacity: 80,
      is_paid: false,
      price: 0,
      pix_key: '',
      pix_key_type: 'Chave Aleatória',
      pix_receiver_name: 'Igreja Presbiteriana do Brasil',
      instructions: 'O que levar: Bíblia, caderno de anotações, roupa de cama e banho, itens de higiene pessoal, casaco e remédios de uso contínuo.',
      contact_phone: '',
      contact_email: '',
      require_medical_info: true,
      allow_non_members: true,
      status: 'published',
    };
  }

  abrirNovoEvento(): void {
    this.isEditing = false;
    this.currentEventId = null;
    this.formEvent = this.resetEventForm();
    this.eventDialog = true;
  }

  editarEvento(event: ChurchEvent): void {
    this.isEditing = true;
    this.currentEventId = event.id;
    this.formEvent = {
      ...event,
      starts_at: event.starts_at ? new Date(event.starts_at).toISOString().substring(0, 16) : '',
      ends_at: event.ends_at ? new Date(event.ends_at).toISOString().substring(0, 16) : '',
    };
    this.eventDialog = true;
  }

  salvarEvento(): void {
    if (!this.formEvent.title || !this.formEvent.starts_at) {
      this.msg.add({ severity: 'warn', summary: 'Campos Obrigatórios', detail: 'Informe o título e a data de início do evento.' });
      return;
    }

    if (this.isEditing && this.currentEventId) {
      this.eventsService.updateEvent(this.currentEventId, this.formEvent).subscribe({
        next: () => {
          this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Evento atualizado com sucesso!' });
          this.eventDialog = false;
          this.carregarEventos();
        },
        error: (err) => {
          this.msg.add({ severity: 'error', summary: 'Erro', detail: err.error?.message || 'Falha ao atualizar evento.' });
        },
      });
    } else {
      this.eventsService.createEvent(this.formEvent).subscribe({
        next: () => {
          this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Evento criado com sucesso! Link gerado automaticamente.' });
          this.eventDialog = false;
          this.carregarEventos();
        },
        error: (err) => {
          this.msg.add({ severity: 'error', summary: 'Erro', detail: err.error?.message || 'Falha ao criar evento.' });
        },
      });
    }
  }

  excluirEvento(event: ChurchEvent): void {
    if (!confirm(`Tem certeza que deseja excluir o evento "${event.title}" e todas as suas inscrições?`)) {
      return;
    }

    this.eventsService.deleteEvent(event.id).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Excluído', detail: 'Evento removido com sucesso.' });
        this.carregarEventos();
      },
      error: () => {
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Não foi possível excluir o evento.' });
      },
    });
  }

  // --- Gerenciamento de Links & WhatsApp ---
  getPublicUrl(event: ChurchEvent): string {
    const origin = window.location.origin;
    return `${origin}/inscricao/${event.slug}`;
  }

  copiarLink(event: ChurchEvent): void {
    const url = this.getPublicUrl(event);
    navigator.clipboard.writeText(url).then(() => {
      this.msg.add({ 
        severity: 'info', 
        summary: 'Link Copiado!', 
        detail: 'O link de inscrição foi copiado para a área de transferência.' 
      });
    });
  }

  compartilharWhatsApp(event: ChurchEvent): void {
    const link = this.getPublicUrl(event);
    const dataFormatada = new Date(event.starts_at).toLocaleDateString('pt-BR', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });

    const valorTexto = event.is_paid 
      ? `💰 Investimento: R$ ${Number(event.price).toFixed(2).replace('.', ',')}` 
      : '✨ Inscrição Gratuita!';

    const texto = `🏛️ *${event.title.toUpperCase()}*\n` +
      (event.theme ? `📖 *Tema:* "${event.theme}"\n` : '') +
      `📅 *Data:* ${dataFormatada}\n` +
      (event.location_name ? `📍 *Local:* ${event.location_name}\n` : '') +
      (event.departure_meeting_point ? `🚌 *Saída dos ônibus:* ${event.departure_meeting_point} às ${event.departure_time || '19:30'}\n` : '') +
      `${valorTexto}\n` +
      (event.max_capacity ? `⚠️ Vagas limitadas (${event.max_capacity} vagas)!\n\n` : '\n') +
      `🔗 *Faça sua inscrição pelo link abaixo:*\n${link}\n\n` +
      `_Igreja Presbiteriana do Brasil_`;

    const encoded = encodeURIComponent(texto);
    window.open(`https://api.whatsapp.com/send?text=${encoded}`, '_blank');
  }

  // --- Gestão de Inscritos ---
  abrirInscritos(event: ChurchEvent): void {
    this.selectedEvent.set(event);
    this.participantsDialog = true;
    this.participantSearch = '';
    this.participantPaymentFilter = '';
    this.carregarInscritos(event.id);
  }

  carregarInscritos(eventId: number): void {
    this.loadingParticipants.set(true);
    this.eventsService.getEvent(eventId, {
      search: this.participantSearch || undefined,
      payment_status: this.participantPaymentFilter || undefined,
    }).subscribe({
      next: (res) => {
        this.selectedEventStats.set(res.stats);
        this.registrations.set(res.registrations);
        this.loadingParticipants.set(false);
      },
      error: () => {
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao carregar participantes.' });
        this.loadingParticipants.set(false);
      },
    });
  }

  confirmarPagamento(reg: ChurchEventRegistration): void {
    if (!this.selectedEvent()) return;
    const eventId = this.selectedEvent()!.id;

    this.eventsService.updateRegistration(eventId, reg.id, {
      payment_status: 'confirmed',
      payment_amount: this.selectedEvent()!.price || 0,
    }).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Pagamento Baixado', detail: `Pagamento de ${reg.full_name} confirmado!` });
        this.carregarInscritos(eventId);
        this.carregarEventos();
      },
      error: () => {
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao confirmar pagamento.' });
      },
    });
  }

  alternarCheckIn(reg: ChurchEventRegistration): void {
    if (!this.selectedEvent()) return;
    const eventId = this.selectedEvent()!.id;
    const novoStatus = !reg.checked_in;

    this.eventsService.updateRegistration(eventId, reg.id, {
      checked_in: novoStatus,
    }).subscribe({
      next: () => {
        reg.checked_in = novoStatus;
        this.msg.add({ 
          severity: novoStatus ? 'success' : 'info', 
          summary: novoStatus ? 'Check-in Realizado' : 'Check-in Removido', 
          detail: `${reg.full_name} ${novoStatus ? 'marcado como presente!' : 'presença desmarcada.'}` 
        });
        this.carregarInscritos(eventId);
        this.carregarEventos();
      },
      error: () => {
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao registrar check-in.' });
      },
    });
  }

  excluirInscricao(reg: ChurchEventRegistration): void {
    if (!this.selectedEvent()) return;
    if (!confirm(`Remover inscrição de ${reg.full_name}?`)) return;

    const eventId = this.selectedEvent()!.id;
    this.eventsService.deleteRegistration(eventId, reg.id).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Removido', detail: 'Inscrição cancelada com sucesso.' });
        this.carregarInscritos(eventId);
        this.carregarEventos();
      },
      error: () => {
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao remover inscrição.' });
      },
    });
  }

  exportarCsv(event: ChurchEvent): void {
    const url = this.eventsService.getExportCsvUrl(event.id);
    window.open(url, '_blank');
  }

  // --- Auxiliares de visualização ---
  getStatusSeverity(status: string): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
    switch (status) {
      case 'published': return 'success';
      case 'draft': return 'warn';
      case 'closed': return 'secondary';
      case 'cancelled': return 'danger';
      default: return 'info';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'published': return 'Inscrições Abertas';
      case 'draft': return 'Rascunho';
      case 'closed': return 'Encerrado';
      case 'cancelled': return 'Cancelado';
      default: return status;
    }
  }

  getPaymentSeverity(status: string): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
    switch (status) {
      case 'confirmed': return 'success';
      case 'pending': return 'warn';
      case 'free': return 'info';
      case 'rejected': return 'danger';
      default: return 'secondary';
    }
  }

  getPaymentLabel(status: string): string {
    switch (status) {
      case 'confirmed': return 'Pago';
      case 'pending': return 'Pendente';
      case 'free': return 'Gratuito';
      case 'rejected': return 'Recusado';
      default: return status;
    }
  }

  formatDate(dateStr?: string): string {
    if (!dateStr) return '-';
    return new Date(dateStr).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }
}
