import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { InputTextModule } from 'primeng/inputtext';
import { DialogModule } from 'primeng/dialog';
import { ToastModule } from 'primeng/toast';
import { TooltipModule } from 'primeng/tooltip';
import { MessageService } from 'primeng/api';
import { CanonicExtraService, ProcessoDisciplinar } from '@/app/core/canonic-extra.service';
import { SecretariaService, CanonicalMember } from '@/app/core/secretaria.service';

@Component({
  selector: 'app-disciplina-pastoral',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    TableModule,
    ButtonModule,
    TagModule,
    InputTextModule,
    DialogModule,
    ToastModule,
    TooltipModule,
  ],
  providers: [MessageService],
  templateUrl: './disciplina-pastoral.html',
})
export class DisciplinaPastoralPage implements OnInit {
  private service = inject(CanonicExtraService);
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);

  processos = signal<ProcessoDisciplinar[]>([]);
  alertasAbandono = signal<any[]>([]);
  membrosDisponiveis = signal<CanonicalMember[]>([]);
  loading = signal<boolean>(true);

  stats = signal({
    total: 0,
    em_aberto: 0,
    cumprindo_disciplina: 0,
    restaurados: 0,
    sob_disciplina_membros: 0,
  });

  // Filtros
  statusFilter = '';
  searchQuery = '';

  // Modais
  dialogNovo = false;
  dialogDetalhe = false;
  dialogRestaurar = false;

  selectedProcesso: ProcessoDisciplinar | null = null;

  formProcesso: Partial<ProcessoDisciplinar> = {
    tipo_falta: 'Abandono de Comunhão',
    descricao_falta: '',
    medida_disciplinar: 'Em Instrução',
    data_abertura: new Date().toISOString().split('T')[0],
    relator_presbitero: '',
    status: 'Em Aberto',
    observacoes_pastorais: '',
  };

  formRestauracao = {
    data_restauracao: new Date().toISOString().split('T')[0],
    observacoes_pastorais: '',
  };

  ngOnInit(): void {
    this.carregarDados();
    this.carregarMembros();
    this.carregarAlertas();
  }

  carregarDados(): void {
    this.loading.set(true);
    this.service.getProcessos({ status: this.statusFilter, search: this.searchQuery }).subscribe({
      next: (res) => {
        this.processos.set(res.processos.data || []);
        if (res.stats) {
          this.stats.set(res.stats);
        }
        this.loading.set(false);
      },
      error: () => {
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao carregar processos disciplinares.' });
        this.loading.set(false);
      },
    });
  }

  carregarMembros(): void {
    this.secService.getMembros().subscribe({
      next: (res) => this.membrosDisponiveis.set(res.membros?.data || []),
    });
  }

  carregarAlertas(): void {
    this.service.getAlertasAbandono().subscribe({
      next: (alertas) => this.alertasAbandono.set(alertas),
    });
  }

  filtrarPorStatus(status: string): void {
    this.statusFilter = status;
    this.carregarDados();
  }

  abrirNovo(membroPreselecionado?: any): void {
    this.formProcesso = {
      person_id: membroPreselecionado ? membroPreselecionado.id : undefined,
      tipo_falta: membroPreselecionado ? 'Abandono de Comunhão' : 'Abandono de Comunhão',
      descricao_falta: membroPreselecionado ? 'Ausência e abandono de cultos e comunhão identificado pelo Conselho.' : '',
      medida_disciplinar: 'Em Instrução',
      data_abertura: new Date().toISOString().split('T')[0],
      relator_presbitero: '',
      status: 'Em Aberto',
      observacoes_pastorais: '',
    };
    this.dialogNovo = true;
  }

  salvarProcesso(): void {
    if (!this.formProcesso.person_id || !this.formProcesso.descricao_falta) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Selecione o membro e descreva os fatos/falta.' });
      return;
    }

    this.service.createProcesso(this.formProcesso).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Processo Registrado', detail: 'Procedimento registrado pelo Conselho.' });
        this.dialogNovo = false;
        this.carregarDados();
      },
      error: () => {
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao registrar processo.' });
      },
    });
  }

  verDetalhes(proc: ProcessoDisciplinar): void {
    this.selectedProcesso = proc;
    this.dialogDetalhe = true;
  }

  abrirRestauracao(proc: ProcessoDisciplinar): void {
    this.selectedProcesso = proc;
    this.formRestauracao = {
      data_restauracao: new Date().toISOString().split('T')[0],
      observacoes_pastorais: 'O membro manifestou arrependimento sincero, cumpriu o período estipulado e foi acolhido pelo Conselho com oração.',
    };
    this.dialogRestaurar = true;
  }

  confirmarRestauracao(): void {
    if (!this.selectedProcesso) return;

    this.service.restaurarMembro(this.selectedProcesso.id, this.formRestauracao).subscribe({
      next: () => {
        this.msg.add({
          severity: 'success',
          summary: 'Membro Restaurado',
          detail: 'Membro reintegrado à plena comunhão com aprovação do Conselho.',
        });
        this.dialogRestaurar = false;
        this.dialogDetalhe = false;
        this.carregarDados();
      },
      error: () => {
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao processar restauração.' });
      },
    });
  }

  getMedidaSeverity(medida: string): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
    switch (medida) {
      case 'Restaurado':
      case 'Absolvido':
        return 'success';
      case 'Em Instrução':
        return 'info';
      case 'Sob Admoestação':
      case 'Sob Censura':
        return 'warn';
      case 'Suspensão dos Sacramentos':
      case 'Exclusão do Rol':
        return 'danger';
      default:
        return 'secondary';
    }
  }

  getStatusSeverity(status: string): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
    switch (status) {
      case 'Restaurado':
        return 'success';
      case 'Em Aberto':
        return 'info';
      case 'Cumprindo Disciplina':
        return 'warn';
      case 'Arquivado':
        return 'secondary';
      default:
        return 'secondary';
    }
  }
}
