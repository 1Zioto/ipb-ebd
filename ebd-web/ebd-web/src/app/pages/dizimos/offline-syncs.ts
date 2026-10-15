import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule, CurrencyPipe, DatePipe } from '@angular/common';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { DizimosService } from '../../core/dizimos.service';
import { OfflineColetaSync } from '../../core/models';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';

@Component({
  selector: 'app-offline-syncs',
  standalone: true,
  imports: [CommonModule, ButtonModule, TagModule, CurrencyPipe, DatePipe],
  templateUrl: './offline-syncs.html',
})
export class OfflineSyncsPage implements OnInit {
  private dizimos = inject(DizimosService);
  private toast = inject(ToastService);
  auth = inject(AuthService);

  lots = signal<OfflineColetaSync[]>([]);
  loading = signal(false);
  processingId = signal<number | null>(null);

  ngOnInit(): void { this.load(); }

  load(): void {
    this.loading.set(true);
    this.dizimos.getOfflineSyncs().subscribe({
      next: (response) => { this.lots.set(response.data); this.loading.set(false); },
      error: () => { this.loading.set(false); this.toast.error('Não foi possível carregar os lotes offline.'); },
    });
  }

  canReview(): boolean { return this.auth.can('dizimos.coleta.approve'); }

  approve(lot: OfflineColetaSync): void {
    const notes = window.prompt('Observação da aprovação (opcional):') ?? undefined;
    this.processingId.set(lot.id);
    this.dizimos.approveOfflineSync(lot.id, notes).subscribe({
      next: (response) => { this.toast.success(response.message); this.processingId.set(null); this.load(); },
      error: (error) => { this.processingId.set(null); this.toast.error(error?.error?.message ?? 'Não foi possível aprovar o lote.'); },
    });
  }

  reject(lot: OfflineColetaSync): void {
    const notes = window.prompt('Informe a divergência encontrada (obrigatório):')?.trim();
    if (!notes || notes.length < 5) {
      this.toast.warning('A recusa exige uma justificativa de pelo menos cinco caracteres.');
      return;
    }
    this.processingId.set(lot.id);
    this.dizimos.rejectOfflineSync(lot.id, notes).subscribe({
      next: (response) => { this.toast.success(response.message); this.processingId.set(null); this.load(); },
      error: (error) => { this.processingId.set(null); this.toast.error(error?.error?.message ?? 'Não foi possível recusar o lote.'); },
    });
  }

  total(lot: OfflineColetaSync): number {
    return (lot.payload?.entries ?? []).reduce((sum, entry) => sum + Number(entry.amount || 0), 0);
  }
}
