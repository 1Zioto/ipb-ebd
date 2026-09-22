import { Component, inject } from '@angular/core';
import { ButtonModule } from 'primeng/button';
import { InstitutionContextService } from '../core/institution-context.service';

@Component({
  selector: 'app-institution-context-banner',
  standalone: true,
  imports: [ButtonModule],
  template: `
    @if (contextService.isContextSwitched()) {
      <div class="mb-4 p-3 rounded-border flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 bg-primary-50 dark:bg-primary-400/10 border border-primary">
        <div class="flex items-center gap-2 text-sm">
          <i class="pi pi-eye text-primary"></i>
          <span>
            Você está visualizando como: <strong>{{ contextService.activeInstitution()?.name }}</strong>
            <span class="text-muted-color"> (Acesso através de: {{ contextService.originInstitution()?.name }})</span>
          </span>
        </div>
        <p-button label="Restaurar visão original" icon="pi pi-replay" size="small" (onClick)="reset()" />
      </div>
    }
  `,
})
export class InstitutionContextBanner {
  contextService = inject(InstitutionContextService);

  reset() {
    this.contextService.resetContext();
  }
}
