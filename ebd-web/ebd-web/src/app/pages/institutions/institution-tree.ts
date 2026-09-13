import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { InstitutionTreeNode } from '../../core/models';
import { InstitutionService } from '../../core/institution.service';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-institution-tree',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './institution-tree.html',
  styleUrl: './institution-tree.scss',
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
    return Boolean(this.userInstId && node.id === this.userInstId);
  }

  canEdit(node: InstitutionTreeNode): boolean {
    return this.isProgrammer || this.isSelf(node);
  }

  canViewDashboard(node: InstitutionTreeNode): boolean {
    return this.isProgrammer || this.isSelf(node) || true; // Dashboard de métricas é visível para a árvore permitida
  }

  loadTree(): void {
    this.loading.set(true);
    this.instService.getTree().subscribe({
      next: (res) => {
        // Expandir por padrão o primeiro nível
        const tree = this.expandNodes(res.tree, true);
        this.treeData.set(tree);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  private expandNodes(nodes: InstitutionTreeNode[], expandCurrent: boolean): InstitutionTreeNode[] {
    return nodes.map((node) => ({
      ...node,
      expanded: expandCurrent,
      children: this.expandNodes(node.children || [], false),
    }));
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
