import { CommonModule } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { MessageModule } from 'primeng/message';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { ToastModule } from 'primeng/toast';
import { SelectModule } from 'primeng/select';
import { MessageService } from 'primeng/api';
import { AuthService } from '../../../core/auth.service';
import { BRAZILIAN_STATES, ChurchInfo, SYSTEM_SCREENS, ScreenConfigService, ScreenModuleDef } from '../../../core/screen-config.service';

@Component({
  selector: 'app-super-admin',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterModule,
    ButtonModule,
    TableModule,
    DialogModule,
    InputTextModule,
    SelectModule,
    TagModule,
    TooltipModule,
    MessageModule,
    IconFieldModule,
    InputIconModule,
    ToastModule,
  ],
  providers: [MessageService],
  templateUrl: './super-admin.html',
})
export class SuperAdminPage implements OnInit {
  auth = inject(AuthService);
  screenConfig = inject(ScreenConfigService);
  private messageService = inject(MessageService);
  private router = inject(Router);

  // Lista oficial de Estados Brasileiros (UFs) para seleção padronizada no cadastro
  readonly brazilianStates = BRAZILIAN_STATES;

  // Aba ativa: 'screens' | 'churches'
  activeTab = signal<'screens' | 'churches'>('screens');

  // Filtros de telas
  screenSearch = signal('');
  selectedGroup = signal('Todos');

  // Filtros de igrejas
  churchSearch = signal('');
  selectedChurchStatus = signal('Todos');

  // Se as alterações de tela devem ser aplicadas a todas as igrejas de uma vez
  applyGlobal = signal(false);

  // Modal de Igreja (Cadastro / Edição)
  showChurchModal = signal(false);
  editingChurchId = signal<number | null>(null);
  churchForm: {
    name: string;
    short_name: string;
    cnpj: string;
    city: string;
    state: string;
    presbiterio: string;
    sinodo: string;
    pastor_titular: string;
    total_membros: number;
    classes_ebd: number;
    status: 'Ativa' | 'Em Implantação' | 'Congregação';
  } = {
    name: '',
    short_name: '',
    cnpj: '',
    city: '',
    state: '',
    presbiterio: '',
    sinodo: '',
    pastor_titular: '',
    total_membros: 0,
    classes_ebd: 0,
    status: 'Ativa',
  };

  // Grupos únicos de telas para filtro
  availableGroups = computed(() => {
    const set = new Set<string>();
    SYSTEM_SCREENS.forEach((s) => set.add(s.group));
    return ['Todos', ...Array.from(set)];
  });

  // Lista de telas filtrada
  filteredScreens = computed(() => {
    const q = this.screenSearch().trim().toLowerCase();
    const g = this.selectedGroup();

    return SYSTEM_SCREENS.filter((s) => {
      const matchSearch =
        !q ||
        s.label.toLowerCase().includes(q) ||
        s.key.toLowerCase().includes(q) ||
        s.description.toLowerCase().includes(q) ||
        s.route.toLowerCase().includes(q);

      const matchGroup = g === 'Todos' || s.group === g;
      return matchSearch && matchGroup;
    });
  });

  // Lista de igrejas filtrada
  filteredChurches = computed(() => {
    const q = this.churchSearch().trim().toLowerCase();
    const st = this.selectedChurchStatus();
    const list = this.screenConfig.churches();

    return list.filter((c) => {
      const matchSearch =
        !q ||
        c.name.toLowerCase().includes(q) ||
        c.short_name.toLowerCase().includes(q) ||
        c.city.toLowerCase().includes(q) ||
        c.state.toLowerCase().includes(q) ||
        c.pastor_titular.toLowerCase().includes(q) ||
        c.presbiterio.toLowerCase().includes(q) ||
        (c.cnpj && c.cnpj.includes(q));

      const matchStatus = st === 'Todos' || c.status === st;
      return matchSearch && matchStatus;
    });
  });

  // Estatísticas globais
  globalStats = computed(() => this.screenConfig.getGlobalStats());

  // Estatísticas da igreja selecionada
  activeChurchStats = computed(() => {
    const church = this.screenConfig.activeChurch();
    if (!church) return { enabled: 0, total: SYSTEM_SCREENS.length };
    return this.screenConfig.getEnabledCount(church.id);
  });

  ngOnInit() {
    // A Central Super Admin é restrita exclusivamente ao Usuário Master do sistema
    if (!this.auth.isMasterUser()) {
      this.router.navigate(['/']);
      return;
    }
  }

  // --- CONTROLE DE TELAS ---

  isScreenActive(screenKey: string): boolean {
    return this.screenConfig.isScreenEnabled(screenKey);
  }

  toggleScreen(screen: ScreenModuleDef): void {
    const current = this.isScreenActive(screen.key);
    const next = !current;

    if (this.applyGlobal()) {
      this.screenConfig.applyToAllChurches(screen.key, next);
      this.messageService.add({
        severity: next ? 'success' : 'warn',
        summary: next ? 'Tela Liberada Globalmente' : 'Tela Desativada Globalmente',
        detail: `Módulo "${screen.label}" foi ${next ? 'liberado' : 'desativado'} em TODAS as igrejas cadastradas.`,
        life: 3500,
      });
    } else {
      const activeChurch = this.screenConfig.activeChurch();
      this.screenConfig.setScreenEnabled(screen.key, next);
      this.messageService.add({
        severity: next ? 'success' : 'warn',
        summary: next ? 'Tela Liberada' : 'Tela Ocultada do Menu',
        detail: `Módulo "${screen.label}" ${next ? 'agora está visível' : 'foi desativado e removido do menu'} para "${activeChurch?.short_name || 'Igreja'}".`,
        life: 3000,
      });
    }
  }

  enableAllScreens(): void {
    if (this.applyGlobal()) {
      SYSTEM_SCREENS.forEach((s) => this.screenConfig.applyToAllChurches(s.key, true));
      this.messageService.add({
        severity: 'success',
        summary: 'Todas as Telas Liberadas',
        detail: 'Todas as telas foram ativadas para todas as igrejas.',
      });
    } else {
      this.screenConfig.setAllScreens(true);
      this.messageService.add({
        severity: 'success',
        summary: 'Telas Liberadas',
        detail: `Todas as telas foram liberadas para "${this.screenConfig.activeChurch()?.short_name}".`,
      });
    }
  }

  disableAllScreens(): void {
    if (this.applyGlobal()) {
      SYSTEM_SCREENS.forEach((s) => this.screenConfig.applyToAllChurches(s.key, false));
      this.messageService.add({
        severity: 'warn',
        summary: 'Telas Desativadas Globalmente',
        detail: 'Todos os módulos foram ocultados.',
      });
    } else {
      this.screenConfig.setAllScreens(false);
      this.messageService.add({
        severity: 'warn',
        summary: 'Telas Desativadas',
        detail: `Todos os módulos foram desativados para "${this.screenConfig.activeChurch()?.short_name}".`,
      });
    }
  }

  resetDefaults(): void {
    this.screenConfig.resetToDefaults();
    this.messageService.add({
      severity: 'info',
      summary: 'Padrão Restaurado',
      detail: 'Configurações de fábrica da IPB restauradas.',
    });
  }

  // --- CONTROLE DE IGREJAS ---

  selectChurchToConfigure(church: ChurchInfo): void {
    this.screenConfig.switchChurch(church.id);
    this.activeTab.set('screens');
    this.messageService.add({
      severity: 'info',
      summary: 'Igreja Selecionada',
      detail: `Agora configurando telas para: ${church.name}`,
      life: 2500,
    });
  }

  getChurchScreenCount(churchId: number): { enabled: number; total: number } {
    return this.screenConfig.getEnabledCount(churchId);
  }

  openNewChurchModal(): void {
    this.editingChurchId.set(null);
    this.churchForm = {
      name: '',
      short_name: '',
      cnpj: '',
      city: '',
      state: 'MT',
      presbiterio: '',
      sinodo: '',
      pastor_titular: '',
      total_membros: 0,
      classes_ebd: 0,
      status: 'Ativa',
    };
    this.showChurchModal.set(true);
  }

  openEditChurchModal(church: ChurchInfo): void {
    this.editingChurchId.set(church.id);
    this.churchForm = {
      name: church.name,
      short_name: church.short_name,
      cnpj: church.cnpj || '',
      city: church.city,
      state: church.state,
      presbiterio: church.presbiterio,
      sinodo: church.sinodo,
      pastor_titular: church.pastor_titular,
      total_membros: church.total_membros,
      classes_ebd: church.classes_ebd,
      status: church.status,
    };
    this.showChurchModal.set(true);
  }

  saveChurch(): void {
    if (!this.churchForm.name.trim() || !this.churchForm.short_name.trim()) {
      this.messageService.add({
        severity: 'error',
        summary: 'Atenção',
        detail: 'Preencha o Nome Oficial e o Nome Curto da Igreja.',
      });
      return;
    }

    const isEdit = this.editingChurchId() !== null;

    if (isEdit) {
      this.screenConfig.updateChurch(this.editingChurchId()!, {
        name: this.churchForm.name.trim(),
        short_name: this.churchForm.short_name.trim(),
        cnpj: this.churchForm.cnpj.trim() || undefined,
        city: this.churchForm.city.trim(),
        state: this.churchForm.state.trim().toUpperCase(),
        presbiterio: this.churchForm.presbiterio.trim(),
        sinodo: this.churchForm.sinodo.trim(),
        pastor_titular: this.churchForm.pastor_titular.trim(),
        total_membros: Number(this.churchForm.total_membros) || 0,
        classes_ebd: Number(this.churchForm.classes_ebd) || 0,
        status: this.churchForm.status,
      });
      this.messageService.add({
        severity: 'success',
        summary: 'Igreja Atualizada',
        detail: `Dados de "${this.churchForm.short_name}" atualizados com sucesso.`,
      });
    } else {
      const created = this.screenConfig.addChurch({
        name: this.churchForm.name.trim(),
        short_name: this.churchForm.short_name.trim(),
        cnpj: this.churchForm.cnpj.trim() || undefined,
        city: this.churchForm.city.trim(),
        state: this.churchForm.state.trim().toUpperCase(),
        presbiterio: this.churchForm.presbiterio.trim(),
        sinodo: this.churchForm.sinodo.trim(),
        pastor_titular: this.churchForm.pastor_titular.trim(),
        total_membros: Number(this.churchForm.total_membros) || 0,
        classes_ebd: Number(this.churchForm.classes_ebd) || 0,
        status: this.churchForm.status,
      });
      this.messageService.add({
        severity: 'success',
        summary: 'Igreja Cadastrada',
        detail: `"${created.name}" cadastrada com sucesso!`,
      });
    }

    this.showChurchModal.set(false);
  }

  deleteChurch(church: ChurchInfo): void {
    if (confirm(`Tem certeza que deseja remover o cadastro da igreja "${church.name}"?`)) {
      this.screenConfig.deleteChurch(church.id);
      this.messageService.add({
        severity: 'info',
        summary: 'Igreja Removida',
        detail: `Cadastro de "${church.short_name}" foi excluído.`,
      });
    }
  }

  toggleSuperAdminMode(): void {
    const next = !this.auth.isSuperAdmin();
    this.auth.setSuperAdminMode(next);
    this.messageService.add({
      severity: next ? 'success' : 'info',
      summary: next ? 'Super Admin Ativado' : 'Super Admin Desativado',
      detail: next
        ? 'Acesso total irrestrito para parametrização de telas e igrejas.'
        : 'Modo padrão de permissões ativado.',
    });
  }
}
