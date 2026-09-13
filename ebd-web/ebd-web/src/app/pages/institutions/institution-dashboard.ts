import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { ConsolidatedStats, CultRevenueItem, DrilldownStats, Institution, InstitutionSubordinateSummary } from '../../core/models';
import { InstitutionService } from '../../core/institution.service';
import { InstitutionBreadcrumbComponent } from '../../layout/institution-breadcrumb';

@Component({
  selector: 'app-institution-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, InstitutionBreadcrumbComponent],
  templateUrl: './institution-dashboard.html',
  styleUrl: './institution-dashboard.scss',
})
export class InstitutionDashboardPage implements OnInit {
  private route = inject(ActivatedRoute);
  private instService = inject(InstitutionService);

  institutionId = signal<number>(0);
  institutionData = signal<Institution | null>(null);
  stats = signal<ConsolidatedStats | null>(null);
  cultsData = signal<CultRevenueItem[]>([]);
  subordinates = signal<InstitutionSubordinateSummary[]>([]);

  consolidated = signal<boolean>(true);
  loading = signal<boolean>(true);

  // Drilldown modal
  showDrilldown = signal<boolean>(false);
  drilldownTitle = signal<string>('');
  drilldownData = signal<DrilldownStats | null>(null);
  currentDrilldownInstId = signal<number>(0);
  currentDrilldownMetric = signal<string>('members');

  ngOnInit(): void {
    this.route.params.subscribe((params) => {
      const id = Number(params['id']);
      this.institutionId.set(id);
      this.loadAll(id);
    });
  }

  loadAll(id: number): void {
    this.loading.set(true);
    this.instService.get(id).subscribe({
      next: (res) => {
        this.institutionData.set(res.data);
        this.loadDashboardData(id);
      },
      error: () => this.loading.set(false),
    });
  }

  loadDashboardData(id: number): void {
    this.instService.getDashboardSummary(id, this.consolidated()).subscribe({
      next: (data) => this.stats.set(data),
    });

    this.instService.getCultByCult(id, this.consolidated()).subscribe({
      next: (cults) => this.cultsData.set(cults),
    });

    this.instService.getSubordinates(id).subscribe({
      next: (subRes) => {
        this.subordinates.set(subRes.subordinates);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  toggleConsolidated(val: boolean): void {
    this.consolidated.set(val);
    this.loadDashboardData(this.institutionId());
  }

  openDrilldown(metric: string, title: string): void {
    this.drilldownTitle.set(title);
    this.currentDrilldownMetric.set(metric);
    this.currentDrilldownInstId.set(this.institutionId());
    this.loadDrilldown(this.institutionId(), metric);
  }

  loadDrilldown(instId: number, metric: string): void {
    this.instService.getDashboardDrilldown(instId, metric).subscribe({
      next: (res) => {
        this.drilldownData.set(res);
        this.showDrilldown.set(true);
      },
    });
  }

  drilldownDeeper(childInstId: number): void {
    this.currentDrilldownInstId.set(childInstId);
    this.loadDrilldown(childInstId, this.currentDrilldownMetric());
  }

  closeDrilldown(): void {
    this.showDrilldown.set(false);
  }
}
