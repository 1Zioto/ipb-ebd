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

import { Component, inject, OnInit } from '@angular/core';
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
    layoutService = inject(LayoutService);

    model: MenuItem[] = [];
    searchQuery = '';

    ngOnInit() {
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
                    { label: 'Classes EBD', icon: 'pi pi-fw pi-book', routerLink: ['/classes'], visible: this.can('class.view') },
                    { label: 'Calendário', icon: 'pi pi-fw pi-calendar', routerLink: ['/calendario'], visible: this.can('event.view') },
                    { label: 'Escalas de Serviço', icon: 'pi pi-fw pi-list', routerLink: ['/escalas'], visible: this.can('schedule.view') },
                    { label: 'Relatórios EBD', icon: 'pi pi-fw pi-chart-bar', routerLink: ['/relatorios'], visible: this.can('report.view') },
                    { label: 'Relatório Anual IPB', icon: 'pi pi-fw pi-chart-pie', routerLink: ['/relatorios/anual'], visible: this.can('report.view') },
                    { label: 'Sociedades Internas', icon: 'pi pi-fw pi-id-card', routerLink: ['/sociedades'], visible: this.can('person.view') },
                    { label: 'Catecúmenos & Biblioteca', icon: 'pi pi-fw pi-bookmark', routerLink: ['/discipulado-biblioteca'], visible: this.can('person.view') },
                ],
            },
            {
                label: 'Secretaria & Membresia',
                items: [
                    { label: 'Pessoas Cadastradas', icon: 'pi pi-fw pi-users', routerLink: ['/pessoas'], visible: this.can('person.view') },
                    { label: 'Famílias', icon: 'pi pi-fw pi-users', routerLink: ['/familias'], visible: this.can('family.view') },
                    { label: 'Rol Canônico de Membros', icon: 'pi pi-fw pi-address-book', routerLink: ['/secretaria/membros'], visible: this.can('person.view') },
                    { label: 'Código de Disciplina', icon: 'pi pi-fw pi-shield', routerLink: ['/secretaria/disciplina'], visible: this.can('person.view') },
                    { label: 'Estatística do Presbitério', icon: 'pi pi-fw pi-percentage', routerLink: ['/secretaria/estatistica-presbiterio'], visible: this.can('person.view') },
                    { label: 'Cartas de Transferência', icon: 'pi pi-fw pi-envelope', routerLink: ['/secretaria/cartas'], visible: this.can('person.view') },
                    { label: 'Livro de Atas do Conselho', icon: 'pi pi-fw pi-book', routerLink: ['/secretaria/atas'], visible: this.can('person.view') },
                ],
            },
            {
                label: 'Finanças & Diaconia',
                items: [
                    { label: 'Livro Caixa (Tesouraria)', icon: 'pi pi-fw pi-wallet', routerLink: ['/financeiro/transacoes'], visible: this.can('financial.view') },
                    { label: 'Contabilidade & Balancete', icon: 'pi pi-fw pi-file-excel', routerLink: ['/financeiro/contabilidade'], visible: this.can('financial.accounting.view') },
                    { label: 'Termo com Assinaturas', icon: 'pi pi-fw pi-file-edit', routerLink: ['/financeiro/termo-balancete'], visible: this.can('financial.accounting.view') },
                    { label: 'Cotas & Orçamento Anual', icon: 'pi pi-fw pi-chart-line', routerLink: ['/financeiro/cotas-orcamento'], visible: this.can('financial.view') },
                    { label: 'Parecer do Exame de Contas', icon: 'pi pi-fw pi-verified', routerLink: ['/relatorios/parecer-exame-contas'], visible: this.can('financial.accounting.view') },
                    { label: 'Contas & Caixas', icon: 'pi pi-fw pi-building-columns', routerLink: ['/financeiro/contas'], visible: this.can('financial.view') },
                    { label: 'Plano de Contas & Custos', icon: 'pi pi-fw pi-tags', routerLink: ['/financeiro/categorias-custos'], visible: this.can('financial.view') },
                    { label: 'Coletas & Dízimos', icon: 'pi pi-fw pi-inbox', routerLink: ['/dizimos/coletas'], visible: this.can('dizimos.coleta.operar') },
                    { label: 'Acompanhamento Pastoral', icon: 'pi pi-fw pi-heart', routerLink: ['/dizimos/alertas'], visible: this.can('dizimos.alertas.manage') },
                    { label: 'Patrimônio & Livro Tombo', icon: 'pi pi-fw pi-box', routerLink: ['/diaconia/patrimonio'], visible: this.can('person.view') },
                    { label: 'Assistência Diaconal', icon: 'pi pi-fw pi-hand-heart', routerLink: ['/dizimos/diaconato'], visible: this.can('dizimos.diaconato.atender') },
                    { label: 'Configurações de Dízimos', icon: 'pi pi-fw pi-cog', routerLink: ['/dizimos/config'], visible: this.can('dizimos.config.manage') },
                ],
            },
            {
                label: 'Administração & Sistema',
                items: [
                    { label: 'Gestão de Usuários', icon: 'pi pi-fw pi-user-edit', routerLink: ['/admin/usuarios'], visible: this.can('user.manage') },
                    { label: 'Auditoria do Sistema', icon: 'pi pi-fw pi-search', routerLink: ['/admin/auditoria'], visible: this.can('audit.view') },
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

    private visibleGroups(groups: MenuItem[]): MenuItem[] {
        return groups
            .map((group) => ({
                ...group,
                items: (group.items || []).filter((item) => item.visible !== false),
            }))
            .filter((group) => (group.items || []).length > 0);
    }
}
