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
import { Router, RouterModule } from '@angular/router';
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
            <!-- Alternador de Contexto (Área do Membro x Gestão Administrativa) -->
            @if (auth.hasManagementAccess()) {
                <button
                    type="button"
                    (click)="toggleContext()"
                    class="h-9 px-3 rounded-full text-xs font-bold border transition-all cursor-pointer flex items-center gap-1.5 select-none"
                    [ngClass]="auth.isMemberContext() 
                        ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-700 dark:text-emerald-300 hover:bg-emerald-500/20' 
                        : 'bg-surface-100 dark:bg-surface-800 border-surface-200 dark:border-surface-700 text-surface-700 dark:text-surface-200 hover:bg-surface-hover'"
                    [title]="auth.isMemberContext() ? 'Clique para alternar para Gestão Administrativa' : 'Clique para alternar para Área do Membro'"
                >
                    <i [ngClass]="auth.isMemberContext() ? 'pi pi-user' : 'pi pi-shield'" class="text-xs"></i>
                    <span class="hidden sm:inline">{{ auth.isMemberContext() ? 'Área do Membro' : 'Gestão Oficial' }}</span>
                </button>
            }

            <!-- Botão de Acesso Rápido Super Admin (Exclusivo Usuário Master no modo Gestão) -->
            @if (auth.isMasterUser() && !auth.isMemberContext()) {
                <a
                    routerLink="/admin/super-admin"
                    class="layout-topbar-action relative"
                    title="Painel Super Admin: Liberar Telas & Igrejas"
                    aria-label="Painel Super Admin"
                >
                    <i class="pi pi-sliders-h"></i>
                    @if (auth.isSuperAdmin()) {
                        <span class="absolute top-2 right-2 w-2 h-2 rounded-full bg-primary ring-2 ring-surface-0 dark:ring-surface-900"></span>
                    }
                </a>
            }

            <!-- Alternador Rápido de Tema Claro/Escuro -->
            <button
                type="button"
                class="layout-topbar-action"
                (click)="toggleDarkMode()"
                [title]="layoutService.isDarkTheme() ? 'Mudar para tema claro' : 'Mudar para tema escuro'"
                aria-label="Alternar tema de cores"
            >
                <i [ngClass]="layoutService.isDarkTheme() ? 'pi pi-moon' : 'pi pi-sun'"></i>
            </button>

            <!-- Menu de Usuário Responsivo (Desktop & Mobile) -->
            <div class="relative flex items-center">
                <button
                    type="button"
                    class="w-10 h-10 rounded-full flex items-center justify-center cursor-pointer transition-all border border-surface-200 dark:border-surface-700 bg-surface-50 dark:bg-surface-800 hover:border-primary focus:outline-none p-0 shadow-xs"
                    [class.ring-2]="userMenuOpen()"
                    [class.ring-primary]="userMenuOpen()"
                    [class.ring-offset-2]="userMenuOpen()"
                    (click)="toggleUserMenu($event)"
                    [title]="user()?.name || 'Perfil do Usuário'"
                    aria-label="Menu do usuário"
                >
                    <div class="w-8 h-8 rounded-full bg-primary text-primary-contrast flex items-center justify-center font-bold text-xs uppercase shadow-sm select-none">
                        {{ userInitials() }}
                    </div>
                </button>

                <!-- Dropdown Card Flutuante Premium -->
                @if (userMenuOpen()) {
                    <div
                        class="absolute right-0 top-12 mt-2 w-72 sm:w-80 p-3 rounded-2xl shadow-2xl flex flex-col gap-2 animate-scalein"
                        style="background-color: var(--surface-overlay, #ffffff); border: 1px solid var(--surface-border, #e2e8f0); z-index: 1050;"
                        (click)="$event.stopPropagation()"
                    >
                        <!-- Identificação do Usuário -->
                        <div 
                            class="flex items-center gap-3 p-3 rounded-xl border"
                            style="background-color: var(--surface-ground, #f8fafc); border-color: var(--surface-border, #e2e8f0);"
                        >
                            <div class="w-11 h-11 rounded-full bg-primary text-primary-contrast flex items-center justify-center font-bold text-sm shadow-sm ring-2 ring-primary/20 shrink-0">
                                {{ userInitials() }}
                            </div>
                            <div class="min-w-0 flex-1">
                                <div class="font-bold text-sm text-surface-900 dark:text-surface-0 truncate leading-snug" [title]="user()?.name">
                                    {{ user()?.name || 'Usuário' }}
                                </div>
                                <div class="text-xs text-muted-color truncate">
                                    &#64;{{ user()?.username || 'usuario' }}
                                </div>
                                @if (auth.isMasterUser()) {
                                    <div class="mt-1">
                                        <span class="inline-flex items-center gap-1 text-[10px] font-bold tracking-wide uppercase px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border border-emerald-500/20">
                                            Super Administrador
                                        </span>
                                    </div>
                                }
                            </div>
                        </div>

                        <!-- Opções do Menu -->
                        <div 
                            class="flex flex-col gap-1 pt-1 border-t"
                            style="border-top-color: var(--surface-border, #e2e8f0);"
                        >
                            <!-- Alternador de Contexto (Apenas quem tem acesso à Gestão) -->
                            @if (auth.hasManagementAccess()) {
                                <button
                                    type="button"
                                    (click)="toggleContext()"
                                    class="w-full flex items-center justify-between px-3 py-2 rounded-xl text-surface-800 dark:text-surface-100 hover:bg-surface-100 dark:hover:bg-surface-800 transition-colors cursor-pointer group"
                                >
                                    <span class="flex items-center gap-2.5">
                                        <div class="w-7 h-7 rounded-lg bg-surface-200/70 dark:bg-surface-700 text-surface-700 dark:text-surface-300 flex items-center justify-center">
                                            <i [ngClass]="auth.isMemberContext() ? 'pi pi-shield text-xs' : 'pi pi-user text-xs'"></i>
                                        </div>
                                        <span class="text-xs font-medium">Ambiente Ativo</span>
                                    </span>
                                    <span
                                        class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase transition-all"
                                        [ngClass]="auth.isMemberContext() ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20' : 'bg-blue-500/15 text-blue-600 dark:text-blue-400 border border-blue-500/20'"
                                    >
                                        {{ auth.isMemberContext() ? 'Área do Membro' : 'Gestão Oficial' }}
                                    </span>
                                </button>
                            }

                            @if (auth.isMasterUser() && !auth.isMemberContext()) {
                                <!-- Link Super Admin (Apenas Usuário Master no modo Gestão) -->
                                <a
                                    routerLink="/admin/super-admin"
                                    (click)="userMenuOpen.set(false)"
                                    class="w-full flex items-center justify-between px-3 py-2 rounded-xl text-surface-800 dark:text-surface-100 hover:bg-surface-100 dark:hover:bg-surface-800 transition-colors cursor-pointer group"
                                >
                                    <span class="flex items-center gap-2.5">
                                        <div class="w-7 h-7 rounded-lg bg-primary/10 text-primary flex items-center justify-center transition-colors group-hover:bg-primary group-hover:text-primary-contrast">
                                            <i class="pi pi-sliders-h text-xs"></i>
                                        </div>
                                        <span class="text-xs font-semibold">Painel Super Admin</span>
                                    </span>
                                    <i class="pi pi-chevron-right text-[10px] text-muted-color group-hover:text-primary transition-colors"></i>
                                </a>

                                <!-- Alternador Modo Super Admin -->
                                <button
                                    type="button"
                                    (click)="toggleSuperAdminMode()"
                                    class="w-full flex items-center justify-between px-3 py-2 rounded-xl text-surface-800 dark:text-surface-100 hover:bg-surface-100 dark:hover:bg-surface-800 transition-colors cursor-pointer group"
                                >
                                    <span class="flex items-center gap-2.5">
                                        <div class="w-7 h-7 rounded-lg bg-surface-200/70 dark:bg-surface-700 text-surface-700 dark:text-surface-300 flex items-center justify-center">
                                            <i class="pi pi-shield text-xs"></i>
                                        </div>
                                        <span class="text-xs font-medium">Modo Super Admin</span>
                                    </span>
                                    <span
                                        class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase transition-all"
                                        [ngClass]="auth.isSuperAdmin() ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20' : 'bg-surface-200 dark:bg-surface-700 text-muted-color'"
                                    >
                                        {{ auth.isSuperAdmin() ? 'Ativo' : 'Inativo' }}
                                    </span>
                                </button>
                            }

                            <!-- Alternador de Tema Claro/Escuro -->
                            <button
                                type="button"
                                (click)="toggleDarkMode()"
                                class="w-full flex items-center justify-between px-3 py-2 rounded-xl text-surface-800 dark:text-surface-100 hover:bg-surface-100 dark:hover:bg-surface-800 transition-colors cursor-pointer group"
                            >
                                <span class="flex items-center gap-2.5">
                                    <div class="w-7 h-7 rounded-lg bg-surface-200/70 dark:bg-surface-700 text-surface-700 dark:text-surface-300 flex items-center justify-center">
                                        <i [ngClass]="layoutService.isDarkTheme() ? 'pi pi-moon text-xs' : 'pi pi-sun text-xs'"></i>
                                    </div>
                                    <span class="text-xs font-medium">Tema Visual</span>
                                </span>
                                <span class="flex items-center gap-1.5 text-[11px] font-semibold text-muted-color group-hover:text-surface-900 dark:group-hover:text-surface-0 transition-colors">
                                    <i [ngClass]="layoutService.isDarkTheme() ? 'pi pi-moon' : 'pi pi-sun'" class="text-[10px]"></i>
                                    <span>{{ layoutService.isDarkTheme() ? 'Escuro' : 'Claro' }}</span>
                                </span>
                            </button>

                            <!-- Divisor Sutil -->
                            <div class="h-px my-1" style="background-color: var(--surface-border, #e2e8f0);"></div>

                            <!-- Botão de Sair do Sistema -->
                            <button
                                type="button"
                                (click)="logout()"
                                class="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-semibold text-rose-600 dark:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition-colors cursor-pointer group"
                            >
                                <div class="w-7 h-7 rounded-lg bg-rose-500/10 text-rose-600 dark:text-rose-400 flex items-center justify-center group-hover:bg-rose-600 group-hover:text-white transition-colors">
                                    <i class="pi pi-sign-out text-xs"></i>
                                </div>
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
    auth = inject(AuthService);
    router = inject(Router);
    user = this.auth.user;

    userMenuOpen = signal(false);

    toggleContext() {
        const next = this.auth.isMemberContext() ? 'admin' : 'membro';
        this.auth.setContext(next);
        this.userMenuOpen.set(false);
        this.router.navigate(['/dashboard']);
    }

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

    toggleSuperAdminMode() {
        const next = !this.auth.isSuperAdmin();
        this.auth.setSuperAdminMode(next);
        this.userMenuOpen.set(false);
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

