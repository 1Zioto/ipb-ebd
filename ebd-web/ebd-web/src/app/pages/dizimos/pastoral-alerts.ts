import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { DizimosService } from '../../core/dizimos.service';
import { ToastService } from '../../core/toast.service';
import { AlertaDizimo, PastoralDashboardStats } from '../../core/models';

@Component({
  selector: 'app-pastoral-alerts',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './pastoral-alerts.html',
  styleUrl: './pastoral-alerts.scss',
})
export class PastoralAlertsPage implements OnInit {
  private dizimosService = inject(DizimosService);
  private toast = inject(ToastService);
  private router = inject(Router);

  stats = signal<PastoralDashboardStats | null>(null);
  alerts = signal<AlertaDizimo[]>([]);
  loading = signal<boolean>(true);

  // Filtro de status
  filterStatus = signal<string>('');
  filteredAlerts = computed(() => {
    const status = this.filterStatus();
    if (!status) return this.alerts();
    return this.alerts().filter((a) => a.status === status);
  });

  // Modal Acompanhamento Pastoral
  selectedAlert = signal<AlertaDizimo | null>(null);
  showAcompModal = signal<boolean>(false);
  savingAcomp = signal<boolean>(false);
  notes = '';
  nextAction = '';
  reviewDate = '';
  alertaStatus = 'Em acompanhamento';
  conclusion = '';

  // Modal Encaminhar Diaconato
  showDiaconatoModal = signal<boolean>(false);
  savingDiaconato = signal<boolean>(false);
  pastorNotesDiaconato = '';

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.loading.set(true);
    forkJoin({
      stats: this.dizimosService.getPastoralDashboard(),
      alerts: this.dizimosService.getAlerts(),
    }).subscribe({
      next: ({ stats, alerts }) => {
        this.stats.set(stats);
        this.alerts.set(alerts.data);
        this.loading.set(false);
      },
      error: () => {
        this.toast.error('Erro ao carregar dados pastorais. Verifique sua conexão e tente novamente.');
        this.loading.set(false);
      },
    });
  }

  openAcompModal(a: AlertaDizimo): void {
    this.selectedAlert.set(a);
    this.alertaStatus = a.status === 'Novo' ? 'Em acompanhamento' : a.status;
    this.notes = '';
    this.nextAction = '';
    this.reviewDate = '';
    this.conclusion = '';
    this.showAcompModal.set(true);
  }

  closeAcompModal(): void {
    this.showAcompModal.set(false);
  }

  saveAcompanhamento(): void {
    const alert = this.selectedAlert();
    if (!alert || !this.notes.trim() || this.savingAcomp()) return;

    this.savingAcomp.set(true);
    this.dizimosService
      .addAcompanhamento(alert.id, {
        notes: this.notes,
        next_action: this.nextAction,
        review_date: this.reviewDate,
        alerta_status: this.alertaStatus,
        conclusion: this.conclusion,
      })
      .subscribe({
        next: () => {
          this.savingAcomp.set(false);
          this.closeAcompModal();
          this.toast.success('Acompanhamento pastoral registrado com sucesso.');
          this.loadData();
        },
        error: (err) => {
          this.savingAcomp.set(false);
          this.toast.error(err.error?.message || 'Erro ao salvar acompanhamento. Tente novamente.');
        },
      });
  }

  openDiaconatoModal(a: AlertaDizimo): void {
    this.selectedAlert.set(a);
    this.pastorNotesDiaconato = 'Por favor, realizar visita de acompanhamento e apoio a este irmão(ã).';
    this.showDiaconatoModal.set(true);
  }

  sendToDiaconato(): void {
    const selected = this.selectedAlert();
    if (!selected || !this.pastorNotesDiaconato.trim() || this.savingDiaconato()) return;

    this.savingDiaconato.set(true);
    this.dizimosService
      .createDiaconatoRequest({
        person_id: selected.person_id,
        pastor_notes: this.pastorNotesDiaconato,
      })
      .subscribe({
        next: () => {
          this.savingDiaconato.set(false);
          this.showDiaconatoModal.set(false);
          this.toast.success('Solicitação enviada ao Diaconato com sucesso. (Dados financeiros mantidos em sigilo)');
        },
        error: (err) => {
          this.savingDiaconato.set(false);
          this.toast.error(err.error?.message || 'Erro ao encaminhar ao Diaconato. Tente novamente.');
        },
      });
  }

  runEngine(): void {
    this.dizimosService.runAlertEngine().subscribe({
      next: (res) => {
        this.toast.info(`Processamento concluído. Gerados: ${res.alerts_created}, Atualizados: ${res.alerts_updated}`);
        this.loadData();
      },
      error: () => {
        this.toast.error('Erro ao executar análise mensal. Tente novamente.');
      },
    });
  }

  countByStatus(status: string): number {
    return this.alerts().filter((a) => a.status === status).length;
  }
}
