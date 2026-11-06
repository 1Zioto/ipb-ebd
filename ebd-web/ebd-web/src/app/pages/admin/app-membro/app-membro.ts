import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { ButtonModule } from 'primeng/button';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { environment } from '@/environments/environment';

export interface ModuleItem {
  key: string;
  name: string;
  category: string;
  icon: string;
  description: string;
  enabled: boolean;
}

@Component({
  selector: 'app-membro-config',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    ToggleSwitchModule,
    ToastModule,
  ],
  providers: [MessageService],
  templateUrl: './app-membro.html',
})
export class AppMembroConfigPage implements OnInit {
  private http = inject(HttpClient);
  private msg = inject(MessageService);

  loading = signal<boolean>(true);
  saving = signal<boolean>(false);

  modules = signal<ModuleItem[]>([
    {
      key: 'mural',
      name: '1. Início e Painel Informativo',
      category: 'Geral',
      icon: 'pi pi-home',
      description: 'Avisos, comunicados oficiais, versículo do dia e próximos eventos no painel inicial.',
      enabled: true,
    },
    {
      key: 'minha_igreja',
      name: '2. Minha Igreja',
      category: 'Institucional',
      icon: 'pi pi-building',
      description: 'História da igreja, pastor, oficiais do conselho, congregações e endereço institucional.',
      enabled: true,
    },
    {
      key: 'ebd',
      name: '3. Escola Bíblica Dominical (EBD)',
      category: 'Educação Cristã',
      icon: 'pi pi-book',
      description: 'Minha classe, lição do domingo, mural da turma e materiais da classe do aluno.',
      enabled: true,
    },
    {
      key: 'biblia_hinario',
      name: '4. Bíblia e Hinário Novo Cântico',
      category: 'Liturgia',
      icon: 'pi pi-bookmark',
      description: 'Bíblia Sagrada digital e Hinário Novo Cântico oficial com busca rápida e favoritos.',
      enabled: true,
    },
    {
      key: 'agenda_eventos',
      name: '5. Agenda e Eventos',
      category: 'Atividades',
      icon: 'pi pi-calendar',
      description: 'Calendário geral de cultos, eventos especiais, programações e inscrições.',
      enabled: true,
    },
    {
      key: 'vida_crista',
      name: '6. Vida Cristã & Devocionais',
      category: 'Espiritualidade',
      icon: 'pi pi-heart',
      description: 'Planos de leitura bíblica, devocionais diários e acompanhamento de progresso espiritual.',
      enabled: true,
    },
    {
      key: 'biblioteca',
      name: '7. Biblioteca da Igreja',
      category: 'Educação Cristã',
      icon: 'pi pi-folder',
      description: 'Acervo de livros, estudos bíblicos, revistas e publicações disponíveis para empréstimo.',
      enabled: true,
    },
    {
      key: 'minha_participacao',
      name: '8. Minha Participação',
      category: 'Eclesiástico',
      icon: 'pi pi-users',
      description: 'Escalas de serviço (somente as escalas do membro), sociedades internas e atribuições.',
      enabled: true,
    },
    {
      key: 'minha_ficha',
      name: '9. Minha Conta e Família',
      category: 'Cadastro',
      icon: 'pi pi-id-card',
      description: 'Ficha cadastral do membro, dados de dependentes/família e carteirinha digital oficial.',
      enabled: true,
    },
    {
      key: 'dizimos_ofertas',
      name: '10. Comunicação & Contribuições',
      category: 'Serviços',
      icon: 'pi pi-wallet',
      description: 'Pedidos de oração, solicitações à secretaria, chave Pix oficial e comprovantes.',
      enabled: true,
    },
    {
      key: 'prestacao_contas',
      name: '11. Prestação de Contas (Exame Anual)',
      category: 'Transparência',
      icon: 'pi pi-chart-pie',
      description: 'Resumo financeiro simplificado dos exercícios homologados pelo Conselho da igreja.',
      enabled: true,
    },
    {
      key: 'solicitacoes_secretaria',
      name: '12. Configurações da Conta',
      category: 'Geral',
      icon: 'pi pi-cog',
      description: 'Preferências do aplicativo, gerenciamento de dispositivos, tema e encerramento de sessão.',
      enabled: true,
    },
  ]);

  ngOnInit(): void {
    this.carregarConfiguracoes();
  }

  carregarConfiguracoes(): void {
    this.loading.set(true);
    this.http.get<{ modules: Record<string, boolean> }>(`${environment.apiUrl}/church-app-config`).subscribe({
      next: (res) => {
        const configMap = res.modules || {};
        const updated = this.modules().map((m) => ({
          ...m,
          enabled: configMap[m.key] !== undefined ? configMap[m.key] : true,
        }));
        this.modules.set(updated);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
      },
    });
  }

  salvar(): void {
    this.saving.set(true);
    const payload: Record<string, boolean> = {};
    for (const m of this.modules()) {
      payload[m.key] = m.enabled;
    }

    this.http.put(`${environment.apiUrl}/church-app-config`, { modules: payload }).subscribe({
      next: () => {
        this.saving.set(false);
        this.msg.add({
          severity: 'success',
          summary: 'Configurações Salvas',
          detail: 'Os módulos da Área do Membro foram atualizados em tempo real para a sua igreja.',
        });
      },
      error: (err) => {
        this.saving.set(false);
        this.msg.add({
          severity: 'error',
          summary: 'Erro ao Salvar',
          detail: err.error?.message || 'Falha ao gravar configurações do aplicativo do membro.',
        });
      },
    });
  }
}

