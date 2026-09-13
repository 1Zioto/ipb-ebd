import { Component, inject } from '@angular/core';
import { InstitutionContextService } from '../core/institution-context.service';

@Component({
  selector: 'app-institution-context-banner',
  standalone: true,
  templateUrl: './institution-context-banner.html',
  styleUrl: './institution-context-banner.scss',
})
export class InstitutionContextBanner {
  contextService = inject(InstitutionContextService);

  reset() {
    this.contextService.resetContext();
  }
}
