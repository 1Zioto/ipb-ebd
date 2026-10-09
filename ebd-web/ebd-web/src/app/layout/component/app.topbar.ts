/**
 * ============================================================================
 * DIRETRIZ ARQUITETURAL MANDATÓRIA - GOVERNANÇA DO TEMPLATE SAKAI (PrimeNG)
 * ============================================================================
 * ⚠️ REGRA CRÍTICA:
 * ESTE ARQUIVO FAZ PARTE DO NÚCLEO DO TEMPLATE OFICIAL SAKAI (PrimeNG).
 * NUNCA MODIFIQUE A ESTRUTURA BASE, NEM REMOVA OU SUBSTITUA ESTE TEMPLATE.
 * 
 * CASO SEJA SOLICITADA QUALQUER ALTERAÇÃO ESTRUTURAL OU SUBSTITUIÇÃO DO TEMPLATE,
 * É OBRIGATÓRIO SOLICITAR AUTORIZAÇÃO PRÉVIA E EXPLÍCITA DO USUÁRIO ANTES DE PROSSEGUIR.
 * ============================================================================
 */

import { Component, HostListener, computed, inject, signal } from '@angular/core';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { LayoutService } from '@/app/layout/service/layout.service';
import { AuthService } from '@/app/core/auth.service';

@Component({
    selector: 'app-topbar',
    standalone: true,
    imports: [RouterModule, CommonModule],
    template: ` <div class="layout-topbar">
        <div class="layout-topbar-logo-container">
            <button 
                class="layout-menu-button layout-topbar-action" 
                (click)="layoutService.onMenuToggle()"
                [title]="layoutService.isSidebarCollapsed() ? 'Expandir menu lateral' : 'Recolher menu lateral'"
                aria-label="Alternar menu retrátil"
            >
                <i class="pi pi-bars"></i>
            </button>
            <a class="layout-topbar-logo" routerLink="/">
                <img src="ipb-logo.png" alt="Igreja Presbiteriana do Brasil" class="h-8" />
                <span class="font-bold tracking-tight">EBD</span>
            </a>
        </div>

        <div class="layout-topbar-actions">
            <!-- Alternador Rápido de Tema Claro/Escuro -->
            <button
                type="button"
                class="layout-topbar-action"
                (click)="toggleDarkMode()"
                [title]="layoutService.isDarkTheme() ? 'Mudar para tema claro' : 'Mudar para tema escuro'"
                aria-label="Alternar tema de cores"
            >
                <i [ngClass]="{ 'pi': true, 'pi-moon': layoutService.isDarkTheme(), 'pi-sun': !layoutService.isDarkTheme() }"></i>
            </button>

            <!-- Menu de Usuário Responsivo (Desktop & Mobile) -->
            <div class="relative">
                <button
                    type="button"
                    class="layout-topbar-action !w-auto !h-10 px-2.5 rounded-xl border border-surface flex items-center gap-2 hover:bg-surface-hover transition-all"
                    [class.layout-topbar-action-highlight]="userMenuOpen()"
                    (click)="toggleUserMenu($event)"
                    [title]="user()?.name || 'Perfil do Usuário'"
                    aria-label="Menu do usuário"
                >
                    <div class="w-6 h-6 rounded-lg bg-primary text-primary-contrast flex items-center justify-center font-bold text-xs uppercase shadow-sm">
                        {{ userInitials() }}
                    </div>
                    <span class="hidden sm:inline font-semibold text-xs max-w-[130px] truncate text-surface-900 dark:text-surface-0">
                        {{ user()?.name || 'Usuário' }}
                    </span>
                    <i class="pi pi-angle-down text-xs text-muted-color"></i>
                </button>

                <!-- Dropdown Card Flutuante -->
                @if (userMenuOpen()) {
                    <div
                        class="absolute right-0 top-12 w-64 p-3 bg-surface-card border border-surface rounded-2xl shadow-2xl z-50 flex flex-col gap-2 animate-scalein"
                        (click)="$event.stopPropagation()"
                    >
                        <!-- Identificação do Usuário -->
                        <div class="flex items-center gap-3 p-2.5 bg-surface-ground rounded-xl">
                            <div class="w-10 h-10 rounded-xl bg-primary text-primary-contrast flex items-center justify-center font-bold text-sm shadow-sm">
                                {{ userInitials() }}
                            </div>
                            <div class="min-w-0 flex-1">
                                <div class="font-bold text-sm text-surface-900 dark:text-surface-0 truncate">
                                    {{ user()?.name || 'Usuário' }}
                                </div>
                                <div class="text-xs text-muted-color truncate">
                                    &#64;{{ user()?.username || 'usuario' }}
                                </div>
                            </div>
                        </div>

                        <!-- Opções do Menu -->
                        <div class="flex flex-col gap-1 pt-1 border-t border-surface">
                            <button
                                type="button"
                                (click)="toggleDarkMode()"
                                class="w-full flex items-center justify-between px-3 py-2 text-xs font-medium rounded-lg text-surface-700 dark:text-surface-300 hover:bg-surface-hover transition-colors"
                            >
                                <span class="flex items-center gap-2">
                                    <i [ngClass]="layoutService.isDarkTheme() ? 'pi pi-moon' : 'pi pi-sun'"></i>
                                    {{ layoutService.isDarkTheme() ? 'Tema Escuro' : 'Tema Claro' }}
                                </span>
                                <span class="text-[10px] uppercase font-bold text-muted-color">Alternar</span>
                            </button>

                            <button
                                type="button"
                                (click)="logout()"
                                class="w-full flex items-center gap-2 px-3 py-2 text-xs font-semibold rounded-lg text-rose-600 dark:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition-colors"
                            >
                                <i class="pi pi-sign-out"></i>
                                <span>Sair do Sistema</span>
                            </button>
                        </div>
                    </div>
                }
            </div>
        </div>
    </div>`,
})
export class AppTopbar {
    layoutService = inject(LayoutService);
    private auth = inject(AuthService);
    user = this.auth.user;

    userMenuOpen = signal(false);

    userInitials = computed(() => {
        const name = this.user()?.name || 'U';
        const parts = name.trim().split(' ');
        if (parts.length >= 2) {
            return (parts[0][0] + parts[1][0]).toUpperCase();
        }
        return name.slice(0, 2).toUpperCase();
    });

    @HostListener('document:click')
    onDocumentClick() {
        if (this.userMenuOpen()) {
            this.userMenuOpen.set(false);
        }
    }

    toggleUserMenu(event: MouseEvent) {
        event.stopPropagation();
        this.userMenuOpen.update((v) => !v);
    }

    toggleDarkMode() {
        this.layoutService.layoutConfig.update((state) => ({
            ...state,
            darkTheme: !state.darkTheme,
        }));
    }

    logout() {
        this.userMenuOpen.set(false);
        this.auth.logout();
    }
}

