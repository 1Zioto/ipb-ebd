import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { TagModule } from 'primeng/tag';
import { InstitutionTreeNode } from '../../core/models';
import { InstitutionService } from '../../core/institution.service';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-institution-tree',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, ButtonModule, InputTextModule, TagModule],
  templateUrl: './institution-tree.html',
})
export class InstitutionTreePage implements OnInit {
  private instService = inject(InstitutionService);
  private auth = inject(AuthService);
  private router = inject(Router);

  treeData = signal<InstitutionTreeNode[]>([]);
  loading = signal<boolean>(true);
  searchTerm = signal<string>('');

  ngOnInit(): void {
    this.loadTree();
  }

  get userInstId(): number | null | undefined {
    return this.auth.user()?.institution_id;
  }

  get isProgrammer(): boolean {
    return Boolean(this.auth.user()?.is_programmer);
  }

  isSelf(node: InstitutionTreeNode): boolean {
    if (node.is_self !== undefined) return Boolean(node.is_self);
    return Boolean(this.userInstId && node.id === this.userInstId);
  }

  canEdit(node: InstitutionTreeNode): boolean {
    if (this.isProgrammer) return true;
    if (node.can_edit !== undefined) return Boolean(node.can_edit);
    return this.isSelf(node);
  }

  canViewDashboard(node: InstitutionTreeNode): boolean {
    if (this.isProgrammer) return true;
    if (node.can_view_metrics !== undefined) return Boolean(node.can_view_metrics);
    return this.isSelf(node);
  }

  loadTree(): void {
    this.loading.set(true);
    this.instService.getTree().subscribe({
      next: (res) => {
        // Por padrão expande todos os nós para visualização completa da estrutura conciliar
        const tree = this.setExpansion(res.tree, true);
        this.treeData.set(tree);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  setExpansion(nodes: InstitutionTreeNode[], expanded: boolean): InstitutionTreeNode[] {
    return nodes.map((node) => ({
      ...node,
      expanded,
      children: this.setExpansion(node.children || [], expanded),
    }));
  }

  toggleAll(expanded: boolean): void {
    this.treeData.set(this.setExpansion(this.treeData(), expanded));
  }

  toggleNode(node: InstitutionTreeNode, event: Event): void {
    event.stopPropagation();
    node.expanded = !node.expanded;
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

  getTypeBadgeClass(type: string): string {
    const map: Record<string, string> = {
      supremo_concilio: 'badge-purple',
      sinodo: 'badge-indigo',
      presbiterio: 'badge-blue',
      igreja: 'badge-emerald',
      congregacao: 'badge-amber',
    };
    return map[type] || 'badge-gray';
  }

  matchesSearch(node: InstitutionTreeNode): boolean {
    const term = this.searchTerm().toLowerCase().trim();
    if (!term) return true;
    return Boolean(
      node.name.toLowerCase().includes(term) ||
      node.short_name.toLowerCase().includes(term) ||
      this.getTypeLabel(node.type).toLowerCase().includes(term) ||
      (node.city && node.city.toLowerCase().includes(term))
    );
  }
}
