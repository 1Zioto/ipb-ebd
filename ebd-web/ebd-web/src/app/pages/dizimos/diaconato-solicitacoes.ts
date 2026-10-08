import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { MessageModule } from 'primeng/message';
import { DizimosService } from '../../core/dizimos.service';
import { PeopleService } from '../../core/people.service';
import { ToastService } from '../../core/toast.service';
import { SolicitacaoDiaconato, Person } from '../../core/models';

@Component({
  selector: 'app-diaconato-solicitacoes',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    TableModule,
    TagModule,
    ButtonModule,
    DialogModule,
    InputTextModule,
    TextareaModule,
    MessageModule,
  ],
  templateUrl: './diaconato-solicitacoes.html',
})
export class DiaconatoSolicitacoesPage implements OnInit {
  private dizimosService = inject(DizimosService);
  private peopleService = inject(PeopleService);
  private toast = inject(ToastService);

  requests = signal<SolicitacaoDiaconato[]>([]);
  loading = signal<boolean>(true);

  // Filtros
  statusFilter = signal<string>('');
  filteredRequests = computed(() => {
    const filter = this.statusFilter();
    if (!filter) return this.requests();
    return this.requests().filter((r) => r.status.toLowerCase() === filter.toLowerCase());
  });

  // Métricas
  totalCount = computed(() => this.requests().length);
  pendenteCount = computed(() => this.requests().filter((r) => r.status === 'Pendente').length);
  emAtendimentoCount = computed(() => this.requests().filter((r) => r.status === 'Em atendimento').length);
  concluidoCount = computed(() => this.requests().filter((r) => r.status === 'Concluído').length);

  // Modal Nova Solicitação
  showCreateModal = signal<boolean>(false);
  savingCreate = signal<boolean>(false);
  peopleList = signal<Person[]>([]);
  loadingPeople = signal<boolean>(false);
  selectedPersonId: number | null = null;
  newPastorNotes = '';
  newInitialStatus = 'Pendente';

  // Modal Detalhes da Solicitação
  selectedRequest = signal<SolicitacaoDiaconato | null>(null);
  showDetailModal = signal<boolean>(false);

  ngOnInit(): void {
    this.loadRequests();
  }

  loadRequests(): void {
    this.loading.set(true);
    this.dizimosService.getDiaconatoRequests().subscribe({
      next: (res) => {
        this.requests.set(res.data);
        this.loading.set(false);
      },
      error: () => {
        this.toast.error('Erro ao carregar solicitações do diaconato.');
        this.loading.set(false);
      },
    });
  }

  updateStatus(req: SolicitacaoDiaconato, newStatus: string): void {
    if (req.status === newStatus) return;

    this.dizimosService.updateDiaconatoRequest(req.id, newStatus).subscribe({
      next: () => {
        this.toast.success(`Status da solicitação de ${req.person?.full_name} atualizado para "${newStatus}".`);
        this.loadRequests();
      },
      error: (err) => {
        this.toast.error(err.error?.message || 'Erro ao atualizar status da solicitação.');
      },
    });
  }

  openCreateModal(): void {
    this.selectedPersonId = null;
    this.newPastorNotes = '';
    this.newInitialStatus = 'Pendente';
    this.showCreateModal.set(true);

    if (this.peopleList().length === 0) {
      this.loadPeople();
    }
  }

  loadPeople(): void {
    this.loadingPeople.set(true);
    this.peopleService.list({ per_page: 150 })
      .then((res) => {
        this.peopleList.set(res.data);
        this.loadingPeople.set(false);
      })
      .catch(() => {
        this.loadingPeople.set(false);
      });
  }

  saveNewRequest(): void {
    if (!this.selectedPersonId || !this.newPastorNotes.trim() || this.savingCreate()) return;

    this.savingCreate.set(true);
    this.dizimosService.createDirectDiaconatoRequest({
      person_id: Number(this.selectedPersonId),
      pastor_notes: this.newPastorNotes.trim(),
      status: this.newInitialStatus,
    }).subscribe({
      next: () => {
        this.savingCreate.set(false);
        this.showCreateModal.set(false);
        this.toast.success('Solicitação encaminhada ao Diaconato com sucesso!');
        this.loadRequests();
      },
      error: (err) => {
        this.savingCreate.set(false);
        this.toast.error(err.error?.message || 'Erro ao criar solicitação.');
      },
    });
  }

  openDetailModal(req: SolicitacaoDiaconato): void {
    this.selectedRequest.set(req);
    this.showDetailModal.set(true);
  }

  getStatusSeverity(status: string): 'warn' | 'info' | 'success' | 'secondary' {
    switch (status) {
      case 'Pendente':
        return 'warn';
      case 'Em atendimento':
        return 'info';
      case 'Concluído':
        return 'success';
      default:
        return 'secondary';
    }
  }
}
