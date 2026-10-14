import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { TagModule } from 'primeng/tag';
import { MessageModule } from 'primeng/message';
import { TooltipModule } from 'primeng/tooltip';
import { DizimosService } from '../../core/dizimos.service';
import { ColetaDizimo, ComprovanteConferencia } from '../../core/models';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';

@Component({
  selector: 'app-coletas-list',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    ButtonModule,
    TableModule,
    DialogModule,
    InputTextModule,
    TextareaModule,
    TagModule,
    MessageModule,
    TooltipModule,
  ],
  templateUrl: './coletas-list.html',
})
export class ColetasListPage implements OnInit {
  private dizimosService = inject(DizimosService);
  private router = inject(Router);
  private toast = inject(ToastService);
  auth = inject(AuthService);

  coletas = signal<ColetaDizimo[]>([]);
  loading = signal<boolean>(false);
  showModal = signal<boolean>(false);
  creating = signal<boolean>(false);
  createError = signal<string | null>(null);

  // Filtros
  searchTerm = signal<string>('');
  statusFilter = signal<string>('todos'); // 'todos', 'em_andamento', 'encerrada'
  dateFrom = signal<string>('');
  dateTo = signal<string>('');

  // Form para nova conferência
  newDate = new Date().toISOString().substring(0, 10);
  newMeeting = 'Culto Noturno Dominical';
  newDesc = '';
  newNotes = '';

  // Visualizador e Reimpressão de Comprovante
  showComprovanteModal = signal<boolean>(false);
  comprovanteData = signal<ComprovanteConferencia | null>(null);
  carregandoComprovante = signal<boolean>(false);

  // Métricas computadas
  totalArrecadado = computed(() => {
    return this.coletas().reduce((acc, c) => acc + (Number(c.total_geral) || Number(c.total_amount) || 0), 0);
  });

  totalEmAndamento = computed(() => {
    return this.coletas().filter((c) => c.status === 'Aberta' || c.status === 'Reaberta para correção').length;
  });

  totalEncerradas = computed(() => {
    return this.coletas().filter((c) => c.status === 'Fechada').length;
  });

  ngOnInit(): void {
    this.loadColetas();
  }

  loadColetas(): void {
    this.loading.set(true);
    const params: { status?: string; date_from?: string; date_to?: string; search?: string } = {};

    if (this.statusFilter() !== 'todos') {
      params.status = this.statusFilter();
    }
    if (this.dateFrom()) {
      params.date_from = this.dateFrom();
    }
    if (this.dateTo()) {
      params.date_to = this.dateTo();
    }
    if (this.searchTerm().trim()) {
      params.search = this.searchTerm().trim();
    }

    this.dizimosService.getColetas(params).subscribe({
      next: (res) => {
        this.coletas.set(res.data);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.toast.error('Erro ao carregar lista de conferências.');
      },
    });
  }

  onFilterChange(): void {
    this.loadColetas();
  }

  limparFiltros(): void {
    this.searchTerm.set('');
    this.statusFilter.set('todos');
    this.dateFrom.set('');
    this.dateTo.set('');
    this.loadColetas();
  }

  openNewModal(): void {
    this.newDate = new Date().toISOString().substring(0, 10);
    this.newMeeting = 'Culto Noturno Dominical';
    this.newDesc = '';
    this.newNotes = '';
    this.createError.set(null);
    this.showModal.set(true);
  }

  closeModal(): void {
    this.showModal.set(false);
  }

  createColeta(): void {
    if (!this.newDate || this.creating()) return;
    this.creating.set(true);
    this.createError.set(null);

    this.dizimosService
      .openColeta({
        date: this.newDate,
        service_meeting: this.newMeeting,
        description: this.newDesc,
        notes: this.newNotes,
      })
      .subscribe({
        next: (c) => {
          this.creating.set(false);
          this.closeModal();
          this.toast.success(`Conferência ${c.code || '#' + c.id} criada com sucesso!`);
          void this.router.navigate(['/dizimos/coletas', c.id]);
        },
        error: (error: HttpErrorResponse) => {
          this.creating.set(false);
          const validationErrors = error.error?.errors
            ? Object.values(error.error.errors).flat().join(' ')
            : null;
          this.createError.set(
            validationErrors ||
              error.error?.message ||
              'Não foi possível criar a conferência. Verifique sua conexão e tente novamente.'
          );
        },
      });
  }

  abrirComprovante(coletaId: number, reimprimir = false): void {
    this.carregandoComprovante.set(true);
    this.showComprovanteModal.set(true);

    const call$ = reimprimir
      ? this.dizimosService.reimprimir(coletaId)
      : this.dizimosService.getComprovante(coletaId);

    call$.subscribe({
      next: (data) => {
        this.comprovanteData.set(data);
        this.carregandoComprovante.set(false);
      },
      error: () => {
        this.carregandoComprovante.set(false);
        this.toast.error('Erro ao gerar comprovante de conferência.');
      },
    });
  }

  imprimirComprovanteWeb(): void {
    // Na Web, permite imprimir normalmente em qualquer impressora (sem driver Bluetooth fixo)
    window.print();
  }

  isAberta(status: string): boolean {
    return status === 'Aberta' || status === 'Reaberta para correção' || status === 'EM ANDAMENTO';
  }
}
