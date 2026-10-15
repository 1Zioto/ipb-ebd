import { Injectable, inject, signal } from '@angular/core';
import { AuthService } from './auth.service';
import { ScreenConfigService } from './screen-config.service';
import { EbdService } from './ebd.service';
import { DizimosService } from './dizimos.service';
import { CanonicExtraService } from './canonic-extra.service';
import { catchError, of } from 'rxjs';

export interface PendingCounts {
  pendingCalls: number;
  pendingDiaconato: number;
  pendingOS: number;
}

@Injectable({ providedIn: 'root' })
export class PendingIndicatorsService {
  private auth = inject(AuthService);
  private screenConfig = inject(ScreenConfigService);
  private ebdService = inject(EbdService);
  private dizimosService = inject(DizimosService);
  private canonicExtraService = inject(CanonicExtraService);

  private counts = signal<PendingCounts>({
    pendingCalls: 0,
    pendingDiaconato: 0,
    pendingOS: 0,
  });

  private lastFetch = 0;
  private readonly CACHE_TTL_MS = 3 * 60 * 1000; // 3 minutos

  constructor() {
    this.refreshIfStale();
  }

  get indicators() {
    return this.counts.asReadonly();
  }

  getPendingCalls(): number {
    return this.counts().pendingCalls;
  }

  getPendingDiaconato(): number {
    return this.counts().pendingDiaconato;
  }

  getPendingOS(): number {
    return this.counts().pendingOS;
  }

  refreshIfStale(): void {
    const now = Date.now();
    if (now - this.lastFetch > this.CACHE_TTL_MS) {
      this.refresh();
    }
  }

  refresh(): void {
    this.lastFetch = Date.now();

    // 1. Chamadas pendentes da EBD
    if (this.can('call.view') || this.can('class.view')) {
      if (this.screenConfig.isScreenEnabled('classes')) {
        this.ebdService
          .getDashboardSummary()
          .pipe(catchError(() => of(null)))
          .subscribe((summary) => {
            if (summary?.metrics?.pending_calls !== undefined) {
              this.counts.update((c) => ({ ...c, pendingCalls: summary.metrics.pending_calls || 0 }));
            }
          });
      }
    }

    // 2. Solicitações de diaconato pendentes
    if (this.can('dizimos.diaconato.atender')) {
      if (this.screenConfig.isScreenEnabled('diaconato')) {
        this.dizimosService
          .getDiaconatoRequests({ status: 'Pendente', page: 1 })
          .pipe(catchError(() => of(null)))
          .subscribe((res: any) => {
            if (res) {
              const total = res.total ?? res.data?.length ?? (Array.isArray(res) ? res.length : 0);
              this.counts.update((c) => ({ ...c, pendingDiaconato: Number(total) || 0 }));
            }
          });
      }
    }

    // 3. Ordens de serviço patrimoniais pendentes
    if (this.can('person.view')) {
      if (this.screenConfig.isScreenEnabled('patrimonio')) {
        this.canonicExtraService
          .getOrdensServico({ status: 'Pendente' })
          .pipe(catchError(() => of(null)))
          .subscribe((res: any) => {
            if (res) {
              const total = res.total ?? res.data?.length ?? (Array.isArray(res) ? res.length : 0);
              this.counts.update((c) => ({ ...c, pendingOS: Number(total) || 0 }));
            }
          });
      }
    }
  }

  private can(permission: string): boolean {
    return this.auth.can(permission);
  }
}
