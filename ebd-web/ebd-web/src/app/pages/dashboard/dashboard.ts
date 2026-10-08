import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { TooltipModule } from 'primeng/tooltip';
import { EbdDashboardSummary, EbdService, SuperintendentLiveMonitor, LiveSessionSummary } from '../../core/ebd.service';
import { ResponsiveService } from '../../core/responsive.service';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-ebd-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink, ButtonModule, TagModule, DialogModule, TooltipModule],
  templateUrl: './dashboard.html',
})
export class EbdDashboardPage implements OnInit {
  private ebdService = inject(EbdService);
  responsive = inject(ResponsiveService);
  auth = inject(AuthService);

  summary = signal<EbdDashboardSummary | null>(null);
  liveMonitor = signal<SuperintendentLiveMonitor | null>(null);
  loading = signal<boolean>(true);

  // Modal de Resumo da Classe
  selectedSession = signal<LiveSessionSummary | null>(null);
  sessionModalVisible = signal<boolean>(false);

  ngOnInit(): void {
    this.loadDashboard();
  }

  loadDashboard(): void {
    this.loading.set(true);
    this.ebdService.getDashboardSummary().subscribe({
      next: (res) => {
        this.summary.set(res);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });

    if (this.auth.can('call.view')) {
      this.ebdService.getSuperintendentLive().subscribe({
        next: (live) => this.liveMonitor.set(live),
      });
    }
  }

  getSessionStatusClass(status: string): string {
    switch (status) {
      case 'Finalizada':
        return 'status-finalized';
      case 'Em andamento':
        return 'status-in-progress';
      case 'Pendente':
        return 'status-pending';
      default:
        return 'status-canceled';
    }
  }

  openSessionSummary(session: LiveSessionSummary): void {
    this.selectedSession.set(session);
    this.sessionModalVisible.set(true);
  }

  closeSessionSummary(): void {
    this.sessionModalVisible.set(false);
  }
}
