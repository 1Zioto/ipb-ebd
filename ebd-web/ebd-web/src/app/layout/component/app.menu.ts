/**
 * ============================================================================
 * DIRETRIZ ARQUITETURAL MANDATÓRIA - GOVERNANÇA DO TEMPLATE SAKAI (PrimeNG)
 * ============================================================================
 * ⚠️ REGRA CRÍTICA:
 * ESTE ARQUIVO FAZ PARTE DO NÚCLEO DO TEMPLATE OFICIAL SAKAI (PrimeNG).
 * PRESERVA A ESTRUTURA BASE, ANIMAÇÕES E NAVEGAÇÃO HIERÁRQUICA DO SAKAI.
 * ============================================================================
 */

import { Component, ElementRef, HostListener, ViewChild, effect, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { InputTextModule } from 'primeng/inputtext';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { RippleModule } from 'primeng/ripple';
import { MenuItem } from 'primeng/api';
import { AppMenuitem } from './app.menuitem';
import { AuthService } from '@/app/core/auth.service';
import { LayoutService } from '@/app/layout/service/layout.service';
import { ScreenConfigService } from '@/app/core/screen-config.service';
import { MenuPreferencesService } from '@/app/core/menu-preferences.service';
import { PendingIndicatorsService } from '@/app/core/pending-indicators.service';

export interface AppMenuItemConfig extends MenuItem {
    id?: string;
    keywords?: string[];
    categoryLabel?: string;
    items?: AppMenuItemConfig[];
}

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
        RippleModule,
        AppMenuitem,
    ],
    template: `
        @if (!layoutService.layoutState().sidebarCollapsed) {
            <!-- BARRA DE BUSCA INTELIGENTE -->
            <div class="menu-search-wrapper">
                <p-iconfield styleClass="w-full relative">
                    <p-inputicon styleClass="pi pi-search text-muted-color text-xs" />
                    <input
                        #searchInput
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

        <!-- RESULTADOS DA BUSCA INTELIGENTE (QUANDO HOUVER CONSULTA) -->
        @if (searchQuery.trim()) {
            <div class="menu-search-results">
                <div class="search-results-header">
                    <span>Resultados da busca</span>
                    <span class="results-count">{{ searchResults.length }}</span>
                </div>
                <ul class="search-results-list">
                    @for (item of searchResults; track item.routerLink?.[0]) {
                        <li>
                            <a
                                (click)="navigateToSearchResult(item)"
                                [routerLink]="item.routerLink"
                                class="search-result-item"
                                pRipple
                            >
                                <i [ngClass]="item.icon" class="search-result-icon"></i>
                                <div class="search-result-info">
                                    <span class="search-result-title">{{ item.label }}</span>
                                    <span class="search-result-category">{{ item.categoryLabel }}</span>
                                </div>
                                <i class="pi pi-arrow-right text-xs text-muted-color search-result-arrow"></i>
                            </a>
                        </li>
                    } @empty {
                        <li class="p-4 text-center text-xs text-muted-color">
                            <i class="pi pi-search text-lg block mb-1 opacity-50"></i>
                            Nenhuma funcionalidade encontrada para "{{ searchQuery }}"
                        </li>
                    }
                </ul>
            </div>
        } @else {
            <!-- NAVEGAÇÃO PRINCIPAL HIERÁRQUICA E LIMPA (SEM CABEÇALHOS REDUNDANTES) -->
            <ul class="layout-menu">
                @for (item of model; track item.label) {
                    <li app-menuitem [item]="item" [root]="false"></li>
                }
            </ul>
        }
    `,
})
export class AppMenu implements OnInit {
    private auth = inject(AuthService);
    private router = inject(Router);
    private screenConfig = inject(ScreenConfigService);
    layoutService = inject(LayoutService);
    menuPrefs = inject(MenuPreferencesService);
    pendingIndicators = inject(PendingIndicatorsService);

    @ViewChild('searchInput') searchInputRef!: ElementRef<HTMLInputElement>;

    model: AppMenuItemConfig[] = [];
    allFlatItems: AppMenuItemConfig[] = [];
    searchQuery = '';

    constructor() {
        // Re-renderiza o menu instantaneamente quando qualquer tela for ativada ou desativada no Super Admin
        effect(() => {
            this.screenConfig.version();
            this.rebuildMenu();
        });

        // Atualiza indicadores de pendências
        effect(() => {
            this.pendingIndicators.indicators();
            this.rebuildMenu();
        });
    }

    ngOnInit() {
        this.rebuildMenu();
    }

    // Atalho global de teclado Ctrl + K ou Cmd + K para busca rápida
    @HostListener('window:keydown', ['$event'])
    handleKeyboardShortcut(event: KeyboardEvent) {
        if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
            event.preventDefault();
            if (this.searchInputRef) {
                this.searchInputRef.nativeElement.focus();
                this.searchInputRef.nativeElement.select();
            }
        }
    }

    rebuildMenu(): void {
        const pendingCalls = this.pendingIndicators.getPendingCalls();
        const pendingDiaconato = this.pendingIndicators.getPendingDiaconato();
        const pendingOS = this.pendingIndicators.getPendingOS();

        const rawStructure: AppMenuItemConfig[] = [
            // 1. Visão Geral (Itens diretos na raiz, configuráveis pelo Super Admin)
            {
                label: 'Tela de Boas-vindas',
                icon: 'pi pi-fw pi-home',
                routerLink: ['/dashboard'],
                visible: this.isScreenVisible('dashboard', 'person.view'),
                keywords: ['inicio', 'home', 'painel', 'resumo', 'indicadores', 'metricas', 'live', 'ebd', 'boas vindas', 'tela de boas vindas'],
            },
            {
                label: 'Dashboards e Informações da Congregação',
                icon: 'pi pi-fw pi-chart-bar',
                routerLink: ['/inteligencia'],
                visible: this.isScreenVisible('inteligencia', 'person.view'),
                keywords: ['dashboard', 'congregacao', 'informacoes', 'membros', 'inteligencia', 'indicadores', 'demografia', 'estatisticas', 'graficos', 'rol'],
            },

            // 2. Educação Cristã (Categoria sanfona / accordion)
            {
                label: 'Educação Cristã',
                id: 'educacao',
                icon: 'pi pi-fw pi-book',
                badge: pendingCalls > 0 ? String(pendingCalls) : undefined,
                badgeClass: 'badge-warn',
                items: [
                    {
                        label: 'Classes da EBD',
                        icon: 'pi pi-fw pi-users',
                        routerLink: ['/classes'],
                        visible: this.isScreenVisible('classes', 'class.view'),
                        badge: pendingCalls > 0 ? `${pendingCalls} pendentes` : undefined,
                        badgeClass: 'badge-warn',
                        keywords: ['ebd', 'classes', 'turmas', 'chamada', 'chamadas', 'frequencia', 'alunos', 'professores'],
                    },
                    {
                        label: 'Calendário da EBD',
                        icon: 'pi pi-fw pi-calendar',
                        routerLink: ['/calendario'],
                        visible: this.isScreenVisible('calendario', 'event.view'),
                        keywords: ['calendario', 'aulas', 'eventos', 'domingos', 'datas', 'trimestre'],
                    },
                    {
                        label: 'Escalas de Serviço',
                        icon: 'pi pi-fw pi-list-check',
                        routerLink: ['/escalas'],
                        visible: this.isScreenVisible('escalas', 'schedule.view'),
                        keywords: ['professores', 'escalas', 'servico', 'plantao', 'equipe'],
                    },
                    {
                        label: 'Relatórios da EBD',
                        icon: 'pi pi-fw pi-chart-bar',
                        routerLink: ['/relatorios'],
                        visible: this.isScreenVisible('relatorios_ebd', 'report.view'),
                        keywords: ['relatorios', 'frequencia', 'graficos', 'estatisticas', 'presenca'],
                    },
                    {
                        label: 'Relatório Anual IPB',
                        icon: 'pi pi-fw pi-chart-pie',
                        routerLink: ['/relatorios/anual'],
                        visible: this.isScreenVisible('relatorio_anual', 'report.view'),
                        keywords: ['relatorio anual', 'sinodal', 'estatistica', 'ipb', 'consolidado'],
                    },
                    {
                        label: 'Catecúmenos & Biblioteca',
                        icon: 'pi pi-fw pi-bookmark',
                        routerLink: ['/discipulado-biblioteca'],
                        visible: this.isScreenVisible('discipulado_biblioteca', 'person.view'),
                        keywords: ['catecumenos', 'discipulado', 'biblioteca', 'livros', 'leitura'],
                    },
                ],
            },

            // 3. Secretaria e Membresia (Categoria sanfona / accordion)
            {
                label: 'Secretaria & Membresia',
                id: 'secretaria',
                icon: 'pi pi-fw pi-address-book',
                items: [
                    {
                        label: 'Pessoas Cadastradas',
                        icon: 'pi pi-fw pi-users',
                        routerLink: ['/pessoas'],
                        visible: this.isScreenVisible('pessoas', 'person.view'),
                        keywords: ['membros', 'pessoas', 'contatos', 'cadastro', 'telefones', 'enderecos'],
                    },
                    {
                        label: 'Núcleos Familiares',
                        icon: 'pi pi-fw pi-users',
                        routerLink: ['/familias'],
                        visible: this.isScreenVisible('familias', 'family.view'),
                        keywords: ['familias', 'nucleos familiares', 'lares', 'casais', 'filhos', 'parentesco'],
                    },
                    {
                        label: 'Rol de Membros',
                        icon: 'pi pi-fw pi-id-card',
                        routerLink: ['/secretaria/membros'],
                        visible: this.isScreenVisible('membros', 'secretaria.rol.view'),
                        keywords: ['rol', 'membros', 'comungantes', 'nao comungantes', 'certidao', 'filiacao'],
                    },
                    {
                        label: 'Cartas de Transferência',
                        icon: 'pi pi-fw pi-envelope',
                        routerLink: ['/secretaria/cartas'],
                        visible: this.isScreenVisible('cartas', 'secretaria.rol.view'),
                        keywords: ['cartas', 'transferencia', 'recepcao', 'demissao', 'oficio'],
                    },
                    {
                        label: 'Estatística do Presbitério',
                        icon: 'pi pi-fw pi-percentage',
                        routerLink: ['/secretaria/estatistica-presbiterio'],
                        visible: this.isScreenVisible('estatistica_presbiterio', 'presbiterio.consolidated.view'),
                        keywords: ['presbiterio', 'estatistica', 'censo', 'sinodo', 'igreja presbiteriana'],
                    },
                    {
                        label: 'Boletim Informativo Semanal',
                        icon: 'pi pi-fw pi-file-edit',
                        routerLink: ['/secretaria/boletim'],
                        visible: this.isScreenVisible('boletim', 'person.view'),
                        keywords: ['boletim', 'informativo', 'liturgia', 'avisos', 'publicacao', 'culto'],
                    },
                ],
            },

            // 4. Conselho e Administração (Categoria sanfona / accordion)
            {
                label: 'Conselho & Administração',
                id: 'conselho',
                icon: 'pi pi-fw pi-shield',
                items: [
                    {
                        label: 'Oficiais & Secretarias',
                        icon: 'pi pi-fw pi-users',
                        routerLink: ['/secretaria/oficiais-lideranca'],
                        visible: this.isScreenVisible('oficiais', 'person.view'),
                        keywords: ['oficiais', 'presbiteros', 'diaconos', 'pastor', 'secretarios', 'lideranca'],
                    },
                    {
                        label: 'Livro de Atas do Conselho',
                        icon: 'pi pi-fw pi-book',
                        routerLink: ['/secretaria/atas'],
                        visible: this.isScreenVisibleAny('atas', 'secretaria.atas.view', 'conselho.approve'),
                        keywords: ['atas', 'reuniao', 'resolucoes', 'conselho', 'livro de atas'],
                    },
                    {
                        label: 'Código de Disciplina',
                        icon: 'pi pi-fw pi-file-check',
                        routerLink: ['/secretaria/disciplina'],
                        visible: this.isScreenVisible('disciplina', 'person.view'),
                        keywords: ['disciplina', 'jurisdicao pastoral', 'processo disciplinar', 'restauracao'],
                    },
                    {
                        label: 'Sociedades Internas',
                        icon: 'pi pi-fw pi-sitemap',
                        routerLink: ['/sociedades'],
                        visible: this.isScreenVisible('sociedades', 'person.view'),
                        keywords: ['sociedades internas', 'saf', 'ump', 'upa', 'uph', 'departamentos'],
                    },
                    {
                        label: 'Estrutura Institucional',
                        icon: 'pi pi-fw pi-sitemap',
                        routerLink: ['/instituicoes/arvore'],
                        visible: this.can('institution.tree.view'),
                        keywords: ['estrutura institucional', 'arvore hierarquica', 'sinodo', 'presbiterio'],
                    },
                    {
                        label: 'Instituições',
                        icon: 'pi pi-fw pi-building',
                        routerLink: ['/instituicoes'],
                        visible: this.can('institution.view'),
                        keywords: ['instituicoes', 'congregacoes', 'pontos de pregacao', 'igrejas federadas'],
                    },
                ],
            },

            // 5. Tesouraria e Finanças (Categoria sanfona / accordion)
            {
                label: 'Tesouraria & Finanças',
                id: 'tesouraria',
                icon: 'pi pi-fw pi-wallet',
                items: [
                    {
                        label: 'Livro Caixa (Tesouraria)',
                        icon: 'pi pi-fw pi-wallet',
                        routerLink: ['/financeiro/transacoes'],
                        visible: this.isScreenVisible('financeiro', 'financial.view'),
                        keywords: ['caixa', 'livro caixa', 'entradas', 'saidas', 'despesas', 'receitas', 'tesouraria'],
                    },
                    {
                        label: 'Contabilidade & Balancete',
                        icon: 'pi pi-fw pi-file-excel',
                        routerLink: ['/financeiro/contabilidade'],
                        visible: this.isScreenVisible('contabilidade', 'financial.accounting.view'),
                        keywords: ['contabilidade', 'balancete', 'demonstrativo', 'dre', 'relatorio financeiro'],
                    },
                    {
                        label: 'Coletas & Dízimos',
                        icon: 'pi pi-fw pi-inbox',
                        routerLink: ['/dizimos/coletas'],
                        visible: this.isScreenVisible('dizimos', 'dizimos.coleta.operar'),
                        keywords: ['dizimos', 'ofertas', 'coletas', 'conferencia', 'envelopes', 'culto'],
                    },
                    {
                        label: 'Lotes Offline para Revisão',
                        icon: 'pi pi-fw pi-check-square',
                        routerLink: ['/dizimos/aprovacoes-offline'],
                        visible: this.isScreenVisible('dizimos', 'dizimos.offline_sync.view'),
                        keywords: ['lotes offline', 'sincronizacao', 'aprovacao de coletas', 'revisao offline'],
                    },
                    {
                        label: 'Contas & Caixas',
                        icon: 'pi pi-fw pi-building-columns',
                        routerLink: ['/financeiro/contas'],
                        visible: this.isScreenVisible('contas_bancarias', 'financial.view'),
                        keywords: ['contas bancarias', 'bancos', 'contas correntes', 'aplicacoes', 'saldo'],
                    },
                    {
                        label: 'Cotas & Orçamento Anual',
                        icon: 'pi pi-fw pi-chart-line',
                        routerLink: ['/financeiro/cotas-orcamento'],
                        visible: this.isScreenVisible('cotas_orcamento', 'financial.view'),
                        keywords: ['cotas', 'orcamento', 'presbiterio', 'sinodo', 'supremo concilio'],
                    },
                    {
                        label: 'Plano de Contas & Custos',
                        icon: 'pi pi-fw pi-tags',
                        routerLink: ['/financeiro/categorias-custos'],
                        visible: this.isScreenVisible('plano_contas', 'financial.view'),
                        keywords: ['plano de contas', 'centros de custo', 'categorias', 'classificacao financeira'],
                    },
                    {
                        label: 'Termo com Assinaturas',
                        icon: 'pi pi-fw pi-file-edit',
                        routerLink: ['/financeiro/termo-balancete'],
                        visible: this.isScreenVisible('termo_balancete', 'financial.accounting.view'),
                        keywords: ['termo balancete', 'assinaturas', 'tesoureiro', 'pastor', 'conselho fiscal'],
                    },
                    {
                        label: 'Parecer do Exame de Contas',
                        icon: 'pi pi-fw pi-verified',
                        routerLink: ['/relatorios/parecer-exame-contas'],
                        visible: this.isScreenVisible('parecer_exame_contas', 'financial.accounting.view'),
                        keywords: ['parecer', 'auditoria', 'comissao de exame de contas', 'aprovacao assembleia'],
                    },
                    {
                        label: 'Configurações de Dízimos',
                        icon: 'pi pi-fw pi-cog',
                        routerLink: ['/dizimos/config'],
                        visible: this.isScreenVisible('dizimos_config', 'dizimos.config.manage'),
                        keywords: ['configuracao dizimos', 'parametros', 'taxas', 'regras de dizimos'],
                    },
                ],
            },

            // 6. Diaconia & Patrimônio (Categoria sanfona / accordion)
            {
                label: 'Diaconia & Patrimônio',
                id: 'diaconia',
                icon: 'pi pi-fw pi-box',
                badge: pendingDiaconato + pendingOS > 0 ? String(pendingDiaconato + pendingOS) : undefined,
                badgeClass: 'badge-warn',
                items: [
                    {
                        label: 'Assistência Diaconal',
                        icon: 'pi pi-fw pi-heart',
                        routerLink: ['/dizimos/diaconato'],
                        visible: this.isScreenVisible('diaconato', 'dizimos.diaconato.atender'),
                        badge: pendingDiaconato > 0 ? `${pendingDiaconato} pendentes` : undefined,
                        badgeClass: 'badge-warn',
                        keywords: ['diaconato', 'assistencia diaconal', 'socorro', 'cesta basica', 'ajuda'],
                    },
                    {
                        label: 'Acompanhamento Pastoral',
                        icon: 'pi pi-fw pi-heart',
                        routerLink: ['/dizimos/alertas'],
                        visible: this.isScreenVisible('alertas_pastorais', 'dizimos.alertas.manage'),
                        keywords: ['pastoral', 'acompanhamento pastoral', 'visitas', 'alertas', 'cuidado'],
                    },
                    {
                        label: 'Patrimônio & Livro Tombo',
                        icon: 'pi pi-fw pi-box',
                        routerLink: ['/diaconia/patrimonio'],
                        visible: this.isScreenVisible('patrimonio', 'person.view'),
                        badge: pendingOS > 0 ? `${pendingOS} OS pendentes` : undefined,
                        badgeClass: 'badge-warn',
                        keywords: ['patrimonio', 'livro tombo', 'bens', 'inventario', 'ordens de servico'],
                    },
                ],
            },

            // 7. Gestão do Sistema (Categoria sanfona / accordion)
            {
                label: 'Gestão do Sistema',
                id: 'admin',
                icon: 'pi pi-fw pi-cog',
                items: [
                    {
                        label: 'Super Admin: Telas & Igrejas',
                        icon: 'pi pi-fw pi-sliders-h',
                        routerLink: ['/admin/super-admin'],
                        visible: this.auth.isSuperAdmin(),
                        keywords: ['super admin', 'master', 'telas', 'modulos', 'igrejas ativas'],
                    },
                    {
                        label: 'Gestão de Usuários',
                        icon: 'pi pi-fw pi-user-edit',
                        routerLink: ['/admin/usuarios'],
                        visible: this.isScreenVisible('usuarios', 'user.manage'),
                        keywords: ['usuarios', 'senhas', 'permissoes', 'acessos', 'perfis'],
                    },
                    {
                        label: 'Auditoria do Sistema',
                        icon: 'pi pi-fw pi-search',
                        routerLink: ['/admin/auditoria'],
                        visible: this.isScreenVisible('auditoria', 'audit.view'),
                        keywords: ['auditoria', 'logs', 'historico', 'seguranca', 'rastreamento'],
                    },
                ],
            },
        ];

        // Filtra grupos e subitens com base nas permissões e visibilidade de tela
        this.model = this.filterVisibleHierarchy(rawStructure);

        // Prepara lista indexada de todas as páginas para pesquisa rápida
        this.allFlatItems = this.extractFlatItems(this.model);
    }

    /**
     * Retorna os resultados da busca inteligente ponderando nome, categoria e palavras-chave
     */
    get searchResults(): AppMenuItemConfig[] {
        const query = this.normalize(this.searchQuery.trim());
        if (!query) return [];

        return this.allFlatItems.filter((item) => {
            const label = this.normalize(item.label || '');
            const category = this.normalize(item.categoryLabel || '');
            const keywords = (item.keywords || []).map((k) => this.normalize(k));

            return (
                label.includes(query) ||
                category.includes(query) ||
                keywords.some((k) => k.includes(query) || query.includes(k))
            );
        });
    }

    navigateToSearchResult(item: AppMenuItemConfig): void {
        if (item.routerLink) {
            this.router.navigate(item.routerLink);
            this.clearSearch();

            // Em dispositivos móveis ou menu overlay, fecha o drawer lateral
            this.layoutService.layoutState.update((val) => ({
                ...val,
                overlayMenuActive: false,
                staticMenuMobileActive: false,
                mobileMenuActive: false,
            }));
        }
    }

    onSearchEnter(): void {
        const results = this.searchResults;
        if (results.length > 0) {
            this.navigateToSearchResult(results[0]);
        }
    }

    clearSearch(): void {
        this.searchQuery = '';
    }

    private extractFlatItems(items: AppMenuItemConfig[]): AppMenuItemConfig[] {
        const list: AppMenuItemConfig[] = [];

        for (const item of items) {
            if (item.items && item.items.length > 0) {
                // Categoria aninhada
                for (const sub of item.items) {
                    list.push({
                        ...sub,
                        categoryLabel: item.label,
                        id: item.id,
                    });
                }
            } else if (item.routerLink) {
                // Item direto
                list.push({
                    ...item,
                    categoryLabel: item.label,
                });
            }
        }

        return list;
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
        if (!this.screenConfig.isScreenEnabled(screenKey)) {
            return false;
        }
        return this.can(perm);
    }

    private isScreenVisibleAny(screenKey: string, ...permissions: string[]): boolean {
        return this.screenConfig.isScreenEnabled(screenKey) && permissions.some((permission) => this.can(permission));
    }

    private filterVisibleHierarchy(items: AppMenuItemConfig[]): AppMenuItemConfig[] {
        return items
            .map((item) => {
                if (item.items && item.items.length > 0) {
                    const subItems = item.items.filter((sub) => sub.visible !== false);
                    return {
                        ...item,
                        items: subItems,
                        visible: subItems.length > 0,
                    };
                }
                return item;
            })
            .filter((item) => item.visible !== false);
    }
}
