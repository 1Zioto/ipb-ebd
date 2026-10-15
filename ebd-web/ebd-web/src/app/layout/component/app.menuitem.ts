/**
 * ============================================================================
 * DIRETRIZ ARQUITETURAL MANDATÓRIA - GOVERNANÇA DO TEMPLATE SAKAI (PrimeNG)
 * ============================================================================
 * ⚠️ REGRA CRÍTICA:
 * ESTE ARQUIVO FAZ PARTE DO NÚCLEO DO TEMPLATE OFICIAL SAKAI (PrimeNG).
 * PRESERVA A ESTRUTURA BASE, ANIMAÇÕES E NAVEGAÇÃO HIERÁRQUICA DO SAKAI.
 * ============================================================================
 */

import { Component, computed, inject, input, signal } from '@angular/core';
import { NavigationEnd, Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { RippleModule } from 'primeng/ripple';
import { LayoutService } from '@/app/layout/service/layout.service';
import { MenuPreferencesService } from '@/app/core/menu-preferences.service';
import { filter } from 'rxjs/operators';

@Component({
    selector: '[app-menuitem]',
    imports: [CommonModule, RouterModule, RippleModule],
    template: `
        @if (root() && isVisible()) {
            <div class="layout-menuitem-root-text">{{ item().label }}</div>
        }
        @if ((!hasRouterLink() || hasChildren()) && isVisible()) {
            <a
                [attr.href]="item().url"
                (click)="itemClick($event)"
                [ngClass]="item().class"
                [attr.target]="item().target"
                tabindex="0"
                pRipple
                [attr.data-tooltip]="item().label"
                [attr.title]="item().label"
                class="category-toggle-item"
            >
                <i [ngClass]="item().icon" class="layout-menuitem-icon"></i>
                <span class="layout-menuitem-text">{{ item().label }}</span>

                @if (item().badge) {
                    <span class="layout-menuitem-badge" [ngClass]="item().badgeClass">{{ item().badge }}</span>
                }

                @if (hasChildren()) {
                    <i class="pi pi-fw pi-angle-down layout-submenu-toggler" [class.is-expanded]="isExpanded()"></i>
                }
            </a>
        }
        @if (hasRouterLink() && !hasChildren() && isVisible()) {
            <a
                (click)="itemClick($event)"
                [ngClass]="item().class"
                [routerLink]="item().routerLink"
                routerLinkActive="active-route"
                [routerLinkActiveOptions]="item().routerLinkActiveOptions || { paths: 'exact', queryParams: 'ignored', matrixParams: 'ignored', fragment: 'ignored' }"
                [fragment]="item().fragment"
                [queryParamsHandling]="item().queryParamsHandling"
                [preserveFragment]="item().preserveFragment"
                [skipLocationChange]="item().skipLocationChange"
                [replaceUrl]="item().replaceUrl"
                [state]="item().state"
                [queryParams]="item().queryParams"
                [attr.target]="item().target"
                tabindex="0"
                pRipple
                [attr.data-tooltip]="item().label"
                [attr.title]="item().label"
                class="menu-link-item"
            >
                <i [ngClass]="item().icon" class="layout-menuitem-icon"></i>
                <span class="layout-menuitem-text">{{ item().label }}</span>

                @if (item().badge) {
                    <span class="layout-menuitem-badge" [ngClass]="item().badgeClass">{{ item().badge }}</span>
                }
            </a>
        }
        @if (hasChildren() && isVisible() && (root() || isExpanded())) {
            <ul [animate.enter]="initialized() ? 'p-submenu-enter' : null" [animate.leave]="'p-submenu-leave'" [class.layout-root-submenulist]="root()">
                @for (child of item().items; track child?.label) {
                    <li
                        app-menuitem
                        [item]="child"
                        [categoryId]="item().id || categoryId()"
                        [parentPath]="fullPath()"
                        [root]="false"
                        [class]="child['badgeClass']"
                    ></li>
                }
            </ul>
        }
    `,
    host: {
        '[class.active-menuitem]': 'isItemActive()',
        '[class.layout-root-menuitem]': 'root()'
    },
    styles: [
        `
            .p-submenu-enter {
                animation: p-animate-submenu-expand 250ms cubic-bezier(0.86, 0, 0.07, 1) forwards;
            }

            .p-submenu-leave {
                animation: p-animate-submenu-collapse 200ms cubic-bezier(0.86, 0, 0.07, 1) forwards;
            }

            @keyframes p-animate-submenu-expand {
                from {
                    max-height: 0;
                    opacity: 0;
                    overflow: hidden;
                }
                to {
                    max-height: 1200px;
                    opacity: 1;
                    overflow: visible;
                }
            }

            @keyframes p-animate-submenu-collapse {
                from {
                    max-height: 1200px;
                    opacity: 1;
                    overflow: hidden;
                }
                to {
                    max-height: 0;
                    opacity: 0;
                    overflow: hidden;
                }
            }
        `
    ]
})
export class AppMenuitem {
    layoutService = inject(LayoutService);
    menuPrefs = inject(MenuPreferencesService);
    router = inject(Router);

    item = input<any>(null);
    root = input<boolean>(false);
    parentPath = input<string | null>(null);
    categoryId = input<string | null>(null);

    isVisible = computed(() => this.item()?.visible !== false);
    hasChildren = computed(() => this.item()?.items && this.item()?.items.length > 0);
    hasRouterLink = computed(() => !!this.item()?.routerLink);

    fullPath = computed(() => {
        const itemPath = this.item()?.path;
        if (!itemPath) return this.parentPath();
        const parent = this.parentPath();
        if (parent && !itemPath.startsWith(parent)) {
            return parent + itemPath;
        }
        return itemPath;
    });

    isExpanded = computed(() => {
        if (!this.hasChildren()) return false;
        const id = this.item()?.id || this.item()?.label;
        return this.menuPrefs.isExpanded(id);
    });

    isItemActive = computed(() => {
        if (this.hasChildren()) {
            return this.isExpanded();
        }
        const activePath = this.layoutService.layoutState().activePath;
        if (this.item()?.path) {
            return activePath?.startsWith(this.fullPath() ?? '') ?? false;
        }
        return false;
    });

    initialized = signal<boolean>(false);

    constructor() {
        this.router.events.pipe(filter((event) => event instanceof NavigationEnd)).subscribe(() => {
            if (this.item()?.routerLink) {
                this.updateActiveStateFromRoute();
            }
        });
    }

    ngOnInit() {
        if (this.item()?.routerLink) {
            this.updateActiveStateFromRoute();
        }
    }

    ngAfterViewInit() {
        setTimeout(() => {
            this.initialized.set(true);
        });
    }

    updateActiveStateFromRoute() {
        const item = this.item();
        if (!item?.routerLink) return;

        const isRouteActive = this.router.isActive(item.routerLink[0], {
            paths: 'exact',
            queryParams: 'ignored',
            matrixParams: 'ignored',
            fragment: 'ignored'
        });

        if (isRouteActive) {
            // Garante que a categoria pai que contém este item permaneça expandida
            const catId = this.categoryId();
            if (catId) {
                this.menuPrefs.expandCategory(catId);
            }
        }
    }

    itemClick(event: Event) {
        const item = this.item();

        if (item?.disabled) {
            event.preventDefault();
            return;
        }

        if (item?.command) {
            item.command({ originalEvent: event, item: item });
        }

        if (this.hasChildren()) {
            const id = item?.id || item?.label;
            this.menuPrefs.toggleCategory(id);
        } else {
            // Em mobile ou overlay, fecha o menu após o clique de navegação
            this.layoutService.layoutState.update((val) => ({
                ...val,
                overlayMenuActive: false,
                staticMenuMobileActive: false,
                mobileMenuActive: false,
                menuHoverActive: false
            }));
        }
    }
}
