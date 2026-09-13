import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DizimosService } from '../../core/dizimos.service';
import { SolicitacaoDiaconato } from '../../core/models';

@Component({
  selector: 'app-diaconato-solicitacoes',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './diaconato-solicitacoes.html',
  styleUrl: './diaconato-solicitacoes.scss',
})
export class DiaconatoSolicitacoesPage implements OnInit {
  private dizimosService = inject(DizimosService);

  requests = signal<SolicitacaoDiaconato[]>([]);
  loading = signal<boolean>(true);

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
      error: () => this.loading.set(false),
    });
  }

  updateStatus(req: SolicitacaoDiaconato, newStatus: string): void {
    this.dizimosService.updateDiaconatoRequest(req.id, newStatus).subscribe({
      next: () => this.loadRequests(),
    });
  }

  getStatusBadgeClass(status: string): string {
    switch (status) {
      case 'Pendente':
        return 'badge-warning';
      case 'Em atendimento':
        return 'badge-info';
      case 'Concluído':
        return 'badge-success';
      default:
        return 'badge-secondary';
    }
  }
}
