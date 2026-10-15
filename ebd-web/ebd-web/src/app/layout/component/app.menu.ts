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

import { Component, effect, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { InputTextModule } from 'primeng/inputtext';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { MenuItem } from 'primeng/api';
import { AppMenuitem } from './app.menuitem';
import { AuthService } from '@/app/core/auth.service';
import { LayoutService } from '@/app/layout/service/layout.service';
import { ScreenConfigService } from '@/app/core/screen-config.service';

@Component({
    selector: 'app-menu',
    standalone: true,
    imports: [
        CommonModule,
        FormsModule,
        RouterModule,
        InputTextModule,
        IconFieldModule,
        InputIconModule,
        AppMenuitem,
    ],
    template: `
        @if (!layoutService.layoutState().sidebarCollapsed) {
            <div class="menu-search-wrapper">
                <p-iconfield styleClass="w-full relative">
                    <p-inputicon styleClass="pi pi-search text-muted-color text-xs" />
                    <input
                        pInputText
                        type="text"
                        [(ngModel)]="searchQuery"
                        (keydown.enter)="onSearchEnter()"
                        (keydown.escape)="clearSearch()"
                        placeholder="Buscar no menu..."
                        class="w-full text-xs py-2 pl-8 pr-7 rounded-xl bg-surface-ground text-surface-900 dark:text-surface-0 border border-surface focus:border-primary transition-all outline-none"
                    />
                    @if (searchQuery) {
                        <button
                            type="button"
                            (click)="clearSearch()"
                            class="absolute right-2 top-1/2 -translate-y-1/2 bg-transparent border-none p-1 text-muted-color hover:text-surface-900 dark:hover:text-surface-0 cursor-pointer flex items-center justify-center transition-colors"
                            title="Limpar busca"
                            aria-label="Limpar busca"
                        >
                            <i class="pi pi-times text-xs"></i>
                        </button>
                    }
                </p-iconfield>
            </div>
        }

        <ul class="layout-menu">
            @for (item of filteredModel; track item.label) {
                @if (!item.separator) {
                    <li app-menuitem [item]="item" [root]="true"></li>
                } @else {
                    <li class="menu-separator"></li>
                }
            } @empty {
                <li class="p-4 text-center text-xs text-muted-color">
                    <i class="pi pi-search text-lg block mb-1 opacity-50"></i>
                    Nenhum item encontrado para "{{ searchQuery }}"
                </li>
            }
        </ul>
    `,
})
export class AppMenu implements OnInit {
    private auth = inject(AuthService);
    private router = inject(Router);
    private screenConfig = inject(ScreenConfigService);
    layoutService = inject(LayoutService);

    model: MenuItem[] = [];
    searchQuery = '';

    constructor() {
        // Re-renderiza o menu instantaneamente quando qualquer tela for ativada ou desativada no Super Admin
        effect(() => {
            this.screenConfig.version();
            this.rebuildMenu();
        });
    }

    ngOnInit() {
        this.rebuildMenu();
    }

    rebuildMenu(): void {
        this.model = this.visibleGroups([
            {
                label: 'Visão Geral & Igreja',
                items: [
                    { label: 'Dashboard', icon: 'pi pi-fw pi-home', routerLink: ['/dashboard'], visible: this.can('person.view') },
                    { label: 'Estrutura Institucional', icon: 'pi pi-fw pi-sitemap', routerLink: ['/instituicoes/arvore'], visible: this.can('institution.tree.view') },
                    { label: 'Instituições', icon: 'pi pi-fw pi-building', routerLink: ['/instituicoes'], visible: this.can('institution.view') },
                ],
            },
            {
                label: 'Educação & Ministérios',
                items: [
                    { label: 'Classes EBD', icon: 'pi pi-fw pi-book', routerLink: ['/classes'], visible: this.isScreenVisible('classes', 'class.view') },
                    { label: 'Calendário', icon: 'pi pi-fw pi-calendar', routerLink: ['/calendario'], visible: this.isScreenVisible('calendario', 'event.view') },
                    { label: 'Escalas de Serviço', icon: 'pi pi-fw pi-list', routerLink: ['/escalas'], visible: this.isScreenVisible('escalas', 'schedule.view') },
                    { label: 'Relatórios EBD', icon: 'pi pi-fw pi-chart-bar', routerLink: ['/relatorios'], visible: this.isScreenVisible('relatorios_ebd', 'report.view') },
                    { label: 'Relatório Anual IPB', icon: 'pi pi-fw pi-chart-pie', routerLink: ['/relatorios/anual'], visible: this.isScreenVisible('relatorio_anual', 'report.view') },
                    { label: 'Sociedades Internas', icon: 'pi pi-fw pi-id-card', routerLink: ['/sociedades'], visible: this.isScreenVisible('sociedades', 'person.view') },
                    { label: 'Catecúmenos & Biblioteca', icon: 'pi pi-fw pi-bookmark', routerLink: ['/discipulado-biblioteca'], visible: this.isScreenVisible('discipulado_biblioteca', 'person.view') },
                ],
            },
            {
                label: 'Secretaria & Membresia',
                items: [
                    { label: 'Pessoas Cadastradas', icon: 'pi pi-fw pi-users', routerLink: ['/pessoas'], visible: this.isScreenVisible('pessoas', 'person.view') },
                    { label: 'Famílias', icon: 'pi pi-fw pi-users', routerLink: ['/familias'], visible: this.isScreenVisible('familias', 'family.view') },
                    { label: 'Rol de Membros', icon: 'pi pi-fw pi-address-book', routerLink: ['/secretaria/membros'], visible: this.isScreenVisible('membros', 'secretaria.rol.view') },
                    { label: 'Oficiais & Secretarias', icon: 'pi pi-fw pi-shield', routerLink: ['/secretaria/oficiais-lideranca'], visible: this.isScreenVisible('oficiais', 'person.view') },
                    { label: 'Código de Disciplina', icon: 'pi pi-fw pi-shield', routerLink: ['/secretaria/disciplina'], visible: this.isScreenVisible('disciplina', 'person.view') },
                    { label: 'Estatística do Presbitério', icon: 'pi pi-fw pi-percentage', routerLink: ['/secretaria/estatistica-presbiterio'], visible: this.isScreenVisible('estatistica_presbiterio', 'presbiterio.consolidated.view') },
                    { label: 'Cartas de Transferência', icon: 'pi pi-fw pi-envelope', routerLink: ['/secretaria/cartas'], visible: this.isScreenVisible('cartas', 'secretaria.rol.view') },
                    { label: 'Livro de Atas do Conselho', icon: 'pi pi-fw pi-book', routerLink: ['/secretaria/atas'], visible: this.isScreenVisibleAny('atas', 'secretaria.atas.view', 'conselho.approve') },
                    { label: 'Boletim Informativo Semanal', icon: 'pi pi-fw pi-file-edit', routerLink: ['/secretaria/boletim'], visible: this.isScreenVisible('boletim', 'person.view') },
                ],
            },
            {
                label: 'Finanças & Diaconia',
                items: [
                    { label: 'Livro Caixa (Tesouraria)', icon: 'pi pi-fw pi-wallet', routerLink: ['/financeiro/transacoes'], visible: this.isScreenVisible('financeiro', 'financial.view') },
                    { label: 'Contabilidade & Balancete', icon: 'pi pi-fw pi-file-excel', routerLink: ['/financeiro/contabilidade'], visible: this.isScreenVisible('contabilidade', 'financial.accounting.view') },
                    { label: 'Termo com Assinaturas', icon: 'pi pi-fw pi-file-edit', routerLink: ['/financeiro/termo-balancete'], visible: this.isScreenVisible('termo_balancete', 'financial.accounting.view') },
                    { label: 'Cotas & Orçamento Anual', icon: 'pi pi-fw pi-chart-line', routerLink: ['/financeiro/cotas-orcamento'], visible: this.isScreenVisible('cotas_orcamento', 'financial.view') },
                    { label: 'Parecer do Exame de Contas', icon: 'pi pi-fw pi-verified', routerLink: ['/relatorios/parecer-exame-contas'], visible: this.isScreenVisible('parecer_exame_contas', 'financial.accounting.view') },
                    { label: 'Contas & Caixas', icon: 'pi pi-fw pi-building-columns', routerLink: ['/financeiro/contas'], visible: this.isScreenVisible('contas_bancarias', 'financial.view') },
                    { label: 'Plano de Contas & Custos', icon: 'pi pi-fw pi-tags', routerLink: ['/financeiro/categorias-custos'], visible: this.isScreenVisible('plano_contas', 'financial.view') },
                    { label: 'Coletas & Dízimos', icon: 'pi pi-fw pi-inbox', routerLink: ['/dizimos/coletas'], visible: this.isScreenVisible('dizimos', 'dizimos.coleta.operar') },
                    { label: 'Lotes Offline para Revisão', icon: 'pi pi-fw pi-check-square', routerLink: ['/dizimos/aprovacoes-offline'], visible: this.isScreenVisible('dizimos', 'dizimos.offline_sync.view') },
                    { label: 'Acompanhamento Pastoral', icon: 'pi pi-fw pi-heart', routerLink: ['/dizimos/alertas'], visible: this.isScreenVisible('alertas_pastorais', 'dizimos.alertas.manage') },
                    { label: 'Patrimônio & Livro Tombo', icon: 'pi pi-fw pi-box', routerLink: ['/diaconia/patrimonio'], visible: this.isScreenVisible('patrimonio', 'person.view') },
                    { label: 'Assistência Diaconal', icon: 'pi pi-fw pi-hand-heart', routerLink: ['/dizimos/diaconato'], visible: this.isScreenVisible('diaconato', 'dizimos.diaconato.atender') },
                    { label: 'Configurações de Dízimos', icon: 'pi pi-fw pi-cog', routerLink: ['/dizimos/config'], visible: this.isScreenVisible('dizimos_config', 'dizimos.config.manage') },
                ],
            },
            {
                label: 'Administração & Sistema',
                items: [
                    {
                        label: 'Super Admin: Telas & Igrejas',
                        icon: 'pi pi-fw pi-sliders-h',
                        routerLink: ['/admin/super-admin'],
                        visible: this.auth.isSuperAdmin(),
                    },
                    { label: 'Gestão de Usuários', icon: 'pi pi-fw pi-user-edit', routerLink: ['/admin/usuarios'], visible: this.isScreenVisible('usuarios', 'user.manage') },
                    { label: 'Auditoria do Sistema', icon: 'pi pi-fw pi-search', routerLink: ['/admin/auditoria'], visible: this.isScreenVisible('auditoria', 'audit.view') },
                ],
            },
        ]);
    }

    get filteredModel(): MenuItem[] {
        const q = this.normalize(this.searchQuery.trim());
        if (!q) {
            return this.model;
        }

        return this.model
            .map((group) => {
                const matchingItems = (group.items || []).filter((item) => {
                    const label = this.normalize(item.label || '');
                    return label.includes(q);
                });
                return {
                    ...group,
                    items: matchingItems,
                };
            })
            .filter((group) => (group.items || []).length > 0);
    }

    onSearchEnter(): void {
        const results = this.filteredModel;
        if (results.length > 0 && results[0].items && results[0].items.length > 0) {
            const first = results[0].items[0];
            if (first.routerLink) {
                this.router.navigate(first.routerLink);
                this.clearSearch();
            }
        }
    }

    clearSearch(): void {
        this.searchQuery = '';
    }

    private normalize(str: string): string {
        return str
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '');
    }

    private can(perm: string): boolean {
        return this.auth.can(perm);
    }

    private isScreenVisible(screenKey: string, perm: string): boolean {
        // Se a tela estiver desativada pelo Super Admin para esta igreja, não aparece no menu
        if (!this.screenConfig.isScreenEnabled(screenKey)) {
            return false;
        }
        return this.can(perm);
    }

    private isScreenVisibleAny(screenKey: string, ...permissions: string[]): boolean {
        return this.screenConfig.isScreenEnabled(screenKey) && permissions.some((permission) => this.can(permission));
    }

    private visibleGroups(groups: MenuItem[]): MenuItem[] {
        return groups
            .map((group) => ({
                ...group,
                items: (group.items || []).filter((item) => item.visible !== false),
            }))
            .filter((group) => (group.items || []).length > 0);
    }
}
