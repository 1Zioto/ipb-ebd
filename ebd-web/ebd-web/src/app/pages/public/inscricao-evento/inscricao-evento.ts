import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { TagModule } from 'primeng/tag';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { 
  ChurchEventsService, 
  PublicEventData, 
  RegistrationSubmission 
} from '@/app/core/church-events.service';

@Component({
  selector: 'app-inscricao-evento-publica',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterModule,
    ButtonModule,
    InputTextModule,
    TagModule,
    ToastModule,
  ],
  providers: [MessageService],
  templateUrl: './inscricao-evento.html',
})
export class InscricaoEventoPublicaPage implements OnInit {
  Number = Number;
  private route = inject(ActivatedRoute);
  private eventsService = inject(ChurchEventsService);
  private msg = inject(MessageService);

  slug = '';
  loading = signal<boolean>(true);
  submitting = signal<boolean>(false);
  eventData = signal<PublicEventData | null>(null);
  errorNotFound = signal<boolean>(false);

  // Estado após submissão com sucesso
  registrationSuccess = signal<boolean>(false);
  successData = signal<any>(null);
  pixCopied = signal<boolean>(false);

  // Formulário do Participante
  form: RegistrationSubmission = {
    full_name: '',
    phone: '',
    email: '',
    cpf: '',
    birth_date: '',
    gender: 'M',
    is_member: true,
    church_name: '',
    is_minor: false,
    guardian_name: '',
    guardian_phone: '',
    dietary_restrictions: '',
    medical_notes: '',
    emergency_contact_name: '',
    emergency_contact_phone: '',
    notes: '',
  };

  ngOnInit(): void {
    this.route.paramMap.subscribe((params) => {
      this.slug = params.get('slug') || '';
      if (this.slug) {
        this.carregarEvento();
      } else {
        this.errorNotFound.set(true);
        this.loading.set(false);
      }
    });
  }

  carregarEvento(): void {
    this.loading.set(true);
    this.eventsService.getPublicEvent(this.slug).subscribe({
      next: (data) => {
        this.eventData.set(data);
        this.loading.set(false);
      },
      error: () => {
        this.errorNotFound.set(true);
        this.loading.set(false);
      },
    });
  }

  submeterInscricao(): void {
    if (!this.form.full_name || !this.form.phone) {
      this.msg.add({ severity: 'warn', summary: 'Campos Obrigatórios', detail: 'Informe seu nome completo e WhatsApp.' });
      return;
    }

    if (this.form.is_minor && (!this.form.guardian_name || !this.form.guardian_phone)) {
      this.msg.add({ 
        severity: 'warn', 
        summary: 'Atenção aos Menores', 
        detail: 'Para menores de idade, o nome e WhatsApp do responsável são obrigatórios.' 
      });
      return;
    }

    this.submitting.set(true);
    this.eventsService.submitPublicRegistration(this.slug, this.form).subscribe({
      next: (res) => {
        this.successData.set(res);
        this.registrationSuccess.set(true);
        this.submitting.set(false);
        window.scrollTo({ top: 0, behavior: 'smooth' });
      },
      error: (err) => {
        this.msg.add({ 
          severity: 'error', 
          summary: 'Não foi possível inscrever', 
          detail: err.error?.message || 'Verifique as informações e tente novamente.' 
        });
        this.submitting.set(false);
      },
    });
  }

  copiarChavePix(pixKey: string): void {
    navigator.clipboard.writeText(pixKey).then(() => {
      this.pixCopied.set(true);
      this.msg.add({ severity: 'success', summary: 'Copiado!', detail: 'Chave Pix copiada com sucesso.' });
      setTimeout(() => this.pixCopied.set(false), 3000);
    });
  }

  formatDate(dateStr?: string): string {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString('pt-BR', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }
}
