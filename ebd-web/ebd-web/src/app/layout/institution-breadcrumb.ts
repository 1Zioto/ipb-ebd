import { Component, Input, OnChanges, SimpleChanges, inject, signal } from '@angular/core';
import { InstitutionBreadcrumb } from '../core/models';
import { InstitutionService } from '../core/institution.service';

@Component({
  selector: 'app-institution-breadcrumb',
  standalone: true,
  imports: [],
  templateUrl: './institution-breadcrumb.html',
  styleUrl: './institution-breadcrumb.scss',
})
export class InstitutionBreadcrumbComponent implements OnChanges {
  @Input() institutionId?: number | null;

  private instService = inject(InstitutionService);
  breadcrumbs = signal<InstitutionBreadcrumb[]>([]);

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['institutionId'] && this.institutionId) {
      this.loadBreadcrumbs(this.institutionId);
    }
  }

  private loadBreadcrumbs(id: number) {
    this.instService.getBreadcrumbs(id).subscribe({
      next: (crumbs) => this.breadcrumbs.set(crumbs),
      error: () => this.breadcrumbs.set([]),
    });
  }

  formatType(type: string): string {
    const map: Record<string, string> = {
      supremo_concilio: 'Supremo Concílio',
      sinodo: 'Sínodo',
      presbiterio: 'Presbitério',
      igreja: 'Igreja',
      congregacao: 'Congregação',
    };
    return map[type] || type;
  }
}
