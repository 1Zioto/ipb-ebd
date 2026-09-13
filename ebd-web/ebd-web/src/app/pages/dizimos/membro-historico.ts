import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { ActivatedRoute } from '@angular/router';
import { DizimosService } from '../../core/dizimos.service';
import { MemberFinancialHistory } from '../../core/models';

@Component({
  selector: 'app-membro-historico',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './membro-historico.html',
  styleUrl: './membro-historico.scss',
})
export class MembroHistoricoPage implements OnInit {
  private route = inject(ActivatedRoute);
  private location = inject(Location);
  private dizimosService = inject(DizimosService);

  history = signal<MemberFinancialHistory | null>(null);
  loading = signal<boolean>(true);
  errorMsg = signal<string | null>(null);
  personId = 0;

  /** Valor máximo calculado uma única vez ao receber os dados (computed signal). */
  maxBarAmount = computed<number>(() => {
    const data = this.history()?.chart_data || [];
    if (data.length === 0) return 1000;
    const max = Math.max(...data.map((d) => d.total_amount));
    return max > 0 ? max : 1000;
  });

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.personId = +id;
      this.loadMemberHistory();
    }
  }

  loadMemberHistory(): void {
    this.loading.set(true);
    this.dizimosService.getMemberHistory(this.personId).subscribe({
      next: (res) => {
        this.history.set(res);
        this.loading.set(false);
      },
      error: (err) => {
        this.errorMsg.set(err.error?.message || 'Acesso não autorizado ou erro ao carregar histórico.');
        this.loading.set(false);
      },
    });
  }

  goBack(): void {
    this.location.back();
  }

  getBarHeightPercentage(amount: number): number {
    const max = this.maxBarAmount();
    return Math.round((amount / max) * 100);
  }

  getTrendBadgeClass(trend: string): string {
    switch (trend) {
      case 'Crescimento':
        return 'badge-success';
      case 'Estável':
        return 'badge-info';
      case 'Pequena redução':
        return 'badge-warning';
      case 'Queda significativa':
      case 'Sem contribuição recente':
        return 'badge-danger';
      default:
        return 'badge-secondary';
    }
  }
}
