import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MenuItem } from 'primeng/api';
import { AppMenuitem } from './app.menuitem';
import { AuthService } from '@/app/core/auth.service';

@Component({
    selector: 'app-menu',
    standalone: true,
    imports: [CommonModule, AppMenuitem, RouterModule],
    template: `<ul class="layout-menu">
        @for (item of model; track item.label) {
            @if (!item.separator) {
                <li app-menuitem [item]="item" [root]="true"></li>
            } @else {
                <li class="menu-separator"></li>
            }
        }
    </ul> `,
})
export class AppMenu implements OnInit {
    private auth = inject(AuthService);
    model: MenuItem[] = [];

    ngOnInit() {
        this.model = this.visibleGroups([
            {
                label: 'Home',
                items: [{ label: 'Dashboard', icon: 'pi pi-fw pi-home', routerLink: ['/dashboard'], visible: this.can('person.view') }],
            },
            {
                label: 'Institucional',
                items: [
                    { label: 'Estrutura Institucional', icon: 'pi pi-fw pi-sitemap', routerLink: ['/instituicoes/arvore'], visible: this.can('institution.tree.view') },
                    { label: 'Instituições', icon: 'pi pi-fw pi-building', routerLink: ['/instituicoes'], visible: this.can('institution.view') },
                ],
            },
            {
                label: 'Pessoas',
                items: [
                    { label: 'Pessoas', icon: 'pi pi-fw pi-users', routerLink: ['/pessoas'], visible: this.can('person.view') },
                    { label: 'Famílias', icon: 'pi pi-fw pi-home', routerLink: ['/familias'], visible: this.can('family.view') },
                ],
            },
            {
                label: 'EBD',
                items: [
                    { label: 'Classes', icon: 'pi pi-fw pi-book', routerLink: ['/classes'], visible: this.can('class.view') },
                    { label: 'Calendário', icon: 'pi pi-fw pi-calendar', routerLink: ['/calendario'], visible: this.can('event.view') },
                    { label: 'Escalas', icon: 'pi pi-fw pi-list', routerLink: ['/escalas'], visible: this.can('schedule.view') },
                    { label: 'Relatórios', icon: 'pi pi-fw pi-chart-bar', routerLink: ['/relatorios'], visible: this.can('report.view') },
                ],
            },
            {
                label: 'Dízimos',
                items: [
                    { label: 'Coletas', icon: 'pi pi-fw pi-inbox', routerLink: ['/dizimos/coletas'], visible: this.can('dizimos.coleta.operar') },
                    { label: 'Alertas Pastorais', icon: 'pi pi-fw pi-bell', routerLink: ['/dizimos/alertas'], visible: this.can('dizimos.alertas.manage') },
                    { label: 'Fila Diaconato', icon: 'pi pi-fw pi-heart', routerLink: ['/dizimos/diaconato'], visible: this.can('dizimos.diaconato.atender') },
                    { label: 'Config. Dízimos', icon: 'pi pi-fw pi-cog', routerLink: ['/dizimos/config'], visible: this.can('dizimos.config.manage') },
                ],
            },
            {
                label: 'Admin',
                items: [
                    { label: 'Usuários', icon: 'pi pi-fw pi-user-edit', routerLink: ['/admin/usuarios'], visible: this.can('user.manage') },
                    { label: 'Auditoria', icon: 'pi pi-fw pi-search', routerLink: ['/admin/auditoria'], visible: this.can('audit.view') },
                ],
            },
        ]);
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
