import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { InputTextModule } from 'primeng/inputtext';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { Institution, IpbCatalogItem, Paginated } from '../../core/models';
import { InstitutionService } from '../../core/institution.service';
import { InstitutionContextService } from '../../core/institution-context.service';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-institution-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, ButtonModule, TableModule, InputTextModule, TagModule, DialogModule],
  templateUrl: './institution-list.html',
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

  // Catálogo Oficial IPB
  catalogDialogVisible = signal<boolean>(false);
  catalogLoading = signal<boolean>(false);
  catalogSearchQuery = signal<string>('');
  catalogSelectedUf = signal<string>('');
  catalogSelectedTipo = signal<string>('');
  catalogItems = signal<IpbCatalogItem[]>([]);
  catalogTotal = signal<number>(0);
  catalogCurrentPage = signal<number>(1);
  selectedCatalogItem = signal<IpbCatalogItem | null>(null);
  importingCatalog = signal<boolean>(false);

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

  // --- Catálogo IPB ---
  openCatalogDialog(): void {
    this.catalogDialogVisible.set(true);
    this.selectedCatalogItem.set(null);
    if (!this.catalogSearchQuery()) {
      this.catalogSearchQuery.set('Campo Verde');
    }
    this.searchCatalog(1);
  }

  searchCatalog(page: number = 1): void {
    this.catalogLoading.set(true);
    this.catalogCurrentPage.set(page);

    this.instService
      .getCatalogoIpb({
        q: this.catalogSearchQuery().trim(),
        uf: this.catalogSelectedUf() || undefined,
        tipo: this.catalogSelectedTipo() || undefined,
        page,
        per_page: 15,
      })
      .subscribe({
        next: (res: any) => {
          this.catalogItems.set(res.data || []);
          this.catalogTotal.set(res.total || 0);
          this.catalogLoading.set(false);
        },
        error: () => this.catalogLoading.set(false),
      });
  }

  importCatalogItem(item: IpbCatalogItem): void {
    this.importingCatalog.set(true);
    this.instService.importarCatalogo(item.id).subscribe({
      next: (res) => {
        this.importingCatalog.set(false);
        this.catalogDialogVisible.set(false);
        this.router.navigate(['/instituicoes', res.data.id]);
      },
      error: () => this.importingCatalog.set(false),
    });
  }
}
