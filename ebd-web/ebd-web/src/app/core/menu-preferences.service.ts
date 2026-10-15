import { Injectable, inject, signal } from '@angular/core';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';
import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class MenuPreferencesService {
  private auth = inject(AuthService);
  private router = inject(Router);

  // Categorias expandidas (Set de strings com os IDs das categorias abertas)
  expandedCategories = signal<Set<string>>(new Set());

  // Rotas favoritas do usuário (array de URLs, ex: ['/classes', '/dizimos/coletas'])
  favorites = signal<string[]>([]);

  // Acessos recentes do usuário (últimas 4 rotas acessadas)
  recents = signal<string[]>([]);

  constructor() {
    this.loadPreferences();

    // Rastreia navegação para registrar acessos recentes e manter preferências sincronizadas
    this.router.events
      .pipe(filter((event): event is NavigationEnd => event instanceof NavigationEnd))
      .subscribe((event) => {
        this.recordRecent(event.urlAfterRedirects.split('?')[0]);
      });
  }

  private getUserKey(prefix: string): string {
    const user = this.auth.user();
    const userId = user?.id || 'guest';
    return `${prefix}_${userId}`;
  }

  loadPreferences(): void {
    if (typeof localStorage === 'undefined') return;

    try {
      // 1. Carrega favoritos
      const favKey = this.getUserKey('ebd_menu_favorites');
      const savedFavs = localStorage.getItem(favKey);
      if (savedFavs) {
        this.favorites.set(JSON.parse(savedFavs));
      } else {
        // Favoritos padrão para novos usuários
        this.favorites.set(['/dashboard', '/classes', '/financeiro/transacoes']);
      }

      // 2. Carrega categorias expandidas
      const expKey = this.getUserKey('ebd_menu_expanded');
      const savedExp = localStorage.getItem(expKey);
      if (savedExp) {
        const arr = JSON.parse(savedExp);
        this.expandedCategories.set(new Set(arr));
      } else {
        // Por padrão, abre Educação Cristã e Painel
        this.expandedCategories.set(new Set(['painel', 'educacao']));
      }

      // 3. Carrega acessos recentes
      const recKey = this.getUserKey('ebd_menu_recents');
      const savedRecents = localStorage.getItem(recKey);
      if (savedRecents) {
        this.recents.set(JSON.parse(savedRecents));
      }
    } catch {
      // Fallback seguro em caso de falha de parsing no storage
    }
  }

  // ==========================================
  // GESTÃO DE EXPANSÃO / RECOLHIMENTO (ACCORDION)
  // ==========================================
  isExpanded(categoryId: string): boolean {
    return this.expandedCategories().has(categoryId);
  }

  toggleCategory(categoryId: string): void {
    const current = new Set(this.expandedCategories());
    if (current.has(categoryId)) {
      current.delete(categoryId);
    } else {
      current.add(categoryId);
    }
    this.setExpandedCategories(current);
  }

  expandCategory(categoryId: string): void {
    const current = new Set(this.expandedCategories());
    if (!current.has(categoryId)) {
      current.add(categoryId);
      this.setExpandedCategories(current);
    }
  }

  collapseCategory(categoryId: string): void {
    const current = new Set(this.expandedCategories());
    if (current.has(categoryId)) {
      current.delete(categoryId);
      this.setExpandedCategories(current);
    }
  }

  private setExpandedCategories(newSet: Set<string>): void {
    this.expandedCategories.set(newSet);
    if (typeof localStorage !== 'undefined') {
      try {
        localStorage.setItem(this.getUserKey('ebd_menu_expanded'), JSON.stringify(Array.from(newSet)));
      } catch {}
    }
  }

  // ==========================================
  // GESTÃO DE FAVORITOS
  // ==========================================
  isFavorite(route: string): boolean {
    return this.favorites().includes(route);
  }

  toggleFavorite(route: string): void {
    const current = [...this.favorites()];
    const index = current.indexOf(route);
    if (index >= 0) {
      current.splice(index, 1);
    } else {
      current.push(route);
    }
    this.favorites.set(current);
    if (typeof localStorage !== 'undefined') {
      try {
        localStorage.setItem(this.getUserKey('ebd_menu_favorites'), JSON.stringify(current));
      } catch {}
    }
  }

  // ==========================================
  // GESTÃO DE ACESSOS RECENTES
  // ==========================================
  private recordRecent(path: string): void {
    if (!path || path === '/' || path === '/login') return;

    const current = this.recents().filter((r) => r !== path);
    // Adiciona no início e limita aos últimos 4
    current.unshift(path);
    const updated = current.slice(0, 4);

    this.recents.set(updated);
    if (typeof localStorage !== 'undefined') {
      try {
        localStorage.setItem(this.getUserKey('ebd_menu_recents'), JSON.stringify(updated));
      } catch {}
    }
  }
}
