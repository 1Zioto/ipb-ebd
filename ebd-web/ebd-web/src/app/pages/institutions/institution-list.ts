import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { Institution, Paginated } from '../../core/models';
import { InstitutionService } from '../../core/institution.service';
import { InstitutionContextService } from '../../core/institution-context.service';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-institution-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './institution-list.html',
  styleUrl: './institution-list.scss',
})
export class InstitutionListPage implements OnInit {
  private instService = inject(InstitutionService);
  private contextService = inject(InstitutionContextService);
  private auth = inject(AuthService);
  private router = inject(Router);

  institutions = signal<Institution[]>([]);
  meta = signal<Paginated<Institution>['meta'] | null>(null);
  loading = signal<boolean>(true);

  // Filtros
  search = signal<string>('');
  typeFilter = signal<string>('');
  statusFilter = signal<string>('');
  page = signal<number>(1);

  ngOnInit(): void {
    const userInstId = this.auth.user()?.institution_id;
    if (userInstId) {
      // Redireciona diretamente para a página da instituição do usuário (sem lista pública)
      this.router.navigate(['/instituicoes', userInstId]);
      return;
    }
    this.loadData();
  }

  loadData(): void {
    this.loading.set(true);
    this.instService
      .list({
        search: this.search(),
        type: this.typeFilter(),
        status: this.statusFilter(),
        page: this.page(),
      })
      .subscribe({
        next: (res) => {
          this.institutions.set(res.data);
          this.meta.set(res.meta);
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
  }

  onSearch(): void {
    this.page.set(1);
    this.loadData();
  }

  setPage(p: number): void {
    this.page.set(p);
    this.loadData();
  }

  switchToContext(inst: Institution): void {
    this.contextService.switchContext(inst);
    this.router.navigate(['/dashboard']);
  }

  getTypeLabel(type: string): string {
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
