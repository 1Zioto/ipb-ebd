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
import {
  CanonicExtraService,
  PatrimonioBem,
  OrdemServicoDiaconia,
  EscalaDiacono,
} from '@/app/core/canonic-extra.service';

@Component({
  selector: 'app-diaconia-patrimonio',
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
  templateUrl: './diaconia-patrimonio.html',
})
export class DiaconiaPatrimonioPage implements OnInit {
  private service = inject(CanonicExtraService);
  private msg = inject(MessageService);

  abaAtiva: 'bens' | 'os' | 'escalas' = 'bens';

  // 1. Bens
  bens = signal<PatrimonioBem[]>([]);
  statsBens = signal({
    total_itens: 0,
    ativos: 0,
    em_manutencao: 0,
    valor_total_aquisicao: 0,
    valor_total_atual: 0,
  });
  categoriaFilter = '';
  searchBem = '';
  dialogBem = false;
  formBem: Partial<PatrimonioBem> = {
    nome: '',
    categoria: 'Som & Áudio',
    localizacao: 'Templo Principal',
    valor_aquisicao: 0,
    valor_atual: 0,
    estado_conservacao: 'Bom',
    status: 'Ativo',
    responsavel_diacono: '',
  };

  // 2. Ordens de Serviço
  ordens = signal<OrdemServicoDiaconia[]>([]);
  statsOS = signal({
    total: 0,
    pendentes: 0,
    em_andamento: 0,
    concluidas: 0,
    custo_total_real: 0,
  });
  statusOSFilter = '';
  dialogOS = false;
  dialogConcluirOS = false;
  selectedOS: OrdemServicoDiaconia | null = null;
  formOS: Partial<OrdemServicoDiaconia> = {
    titulo: '',
    descricao: '',
    tipo_servico: 'Elétrica',
    localizacao: 'Templo Principal',
    prioridade: 'Média',
    status: 'Pendente',
    solicitante: '',
    diacono_responsavel: '',
    data_solicitacao: new Date().toISOString().split('T')[0],
    custo_estimado: 0,
  };
  formConclusaoOS = {
    data_conclusao: new Date().toISOString().split('T')[0],
    custo_real: 0,
    observacoes: '',
  };

  // 3. Escalas
  escalas = signal<EscalaDiacono[]>([]);
  dialogEscala = false;
  formEscala: Partial<EscalaDiacono> = {
    data_culto: new Date().toISOString().split('T')[0],
    periodo: 'Noite',
    recepcao_porta: '',
    recolhimento_ofertas: '',
    apoio_pulpito_ceia: '',
    seguranca_patio: '',
    diacono_coordenador: '',
  };

  loading = signal<boolean>(true);

  ngOnInit(): void {
    this.carregarBens();
    this.carregarOS();
    this.carregarEscalas();
  }

  // Métodos Bens
  carregarBens(): void {
    this.loading.set(true);
    this.service.getBens({ categoria: this.categoriaFilter, search: this.searchBem }).subscribe({
      next: (res) => {
        this.bens.set(res.bens.data || []);
        if (res.stats) this.statsBens.set(res.stats);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  abrirNovoBem(): void {
    this.formBem = {
      nome: '',
      categoria: 'Som & Áudio',
      localizacao: 'Templo Principal',
      valor_aquisicao: 0,
      valor_atual: 0,
      estado_conservacao: 'Bom',
      status: 'Ativo',
      responsavel_diacono: '',
    };
    this.dialogBem = true;
  }

  salvarBem(): void {
    if (!this.formBem.nome || !this.formBem.categoria) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Preencha o nome e a categoria do bem.' });
      return;
    }

    this.service.createBem(this.formBem).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Bem Tombado', detail: 'Patrimônio registrado no Livro Tombo.' });
        this.dialogBem = false;
        this.carregarBens();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao salvar bem.' }),
    });
  }

  // Métodos OS
  carregarOS(): void {
    this.service.getOrdensServico({ status: this.statusOSFilter }).subscribe({
      next: (res) => {
        this.ordens.set(res.ordens.data || []);
        if (res.stats) this.statsOS.set(res.stats);
      },
    });
  }

  abrirNovaOS(): void {
    this.formOS = {
      titulo: '',
      descricao: '',
      tipo_servico: 'Elétrica',
      localizacao: 'Templo Principal',
      prioridade: 'Média',
      status: 'Pendente',
      solicitante: '',
      diacono_responsavel: '',
      data_solicitacao: new Date().toISOString().split('T')[0],
      custo_estimado: 0,
    };
    this.dialogOS = true;
  }

  salvarOS(): void {
    if (!this.formOS.titulo || !this.formOS.solicitante) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Informe o título e o solicitante da OS.' });
      return;
    }

    this.service.createOS(this.formOS).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'OS Aberta', detail: 'Ordem de serviço aberta na Junta Diaconal.' });
        this.dialogOS = false;
        this.carregarOS();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao abrir ordem de serviço.' }),
    });
  }

  abrirConcluirOS(os: OrdemServicoDiaconia): void {
    this.selectedOS = os;
    this.formConclusaoOS = {
      data_conclusao: new Date().toISOString().split('T')[0],
      custo_real: os.custo_estimado || 0,
      observacoes: 'Serviço inspecionado e aprovado pela Junta Diaconal.',
    };
    this.dialogConcluirOS = true;
  }

  confirmarConclusaoOS(): void {
    if (!this.selectedOS) return;

    this.service.concluirOS(this.selectedOS.id, this.formConclusaoOS).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'OS Concluída', detail: 'Manutenção registrada como finalizada.' });
        this.dialogConcluirOS = false;
        this.carregarOS();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao concluir ordem.' }),
    });
  }

  // Métodos Escalas
  carregarEscalas(): void {
    this.service.getEscalasDiaconos().subscribe({
      next: (escalas) => this.escalas.set(escalas),
    });
  }

  abrirNovaEscala(): void {
    this.formEscala = {
      data_culto: new Date().toISOString().split('T')[0],
      periodo: 'Noite',
      recepcao_porta: '',
      recolhimento_ofertas: '',
      apoio_pulpito_ceia: '',
      seguranca_patio: '',
      diacono_coordenador: '',
    };
    this.dialogEscala = true;
  }

  salvarEscala(): void {
    this.service.createEscalaDiacono(this.formEscala).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Escala Registrada', detail: 'Plantão diaconal registrado.' });
        this.dialogEscala = false;
        this.carregarEscalas();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao salvar escala.' }),
    });
  }

  getEstadoSeverity(estado: string): 'success' | 'info' | 'warn' | 'danger' {
    switch (estado) {
      case 'Excelente': return 'success';
      case 'Bom': return 'info';
      case 'Regular': return 'warn';
      case 'Danificado': return 'danger';
      default: return 'info';
    }
  }

  getPrioridadeSeverity(p: string): 'success' | 'info' | 'warn' | 'danger' {
    switch (p) {
      case 'Baixa': return 'info';
      case 'Média': return 'success';
      case 'Alta': return 'warn';
      case 'Urgente': return 'danger';
      default: return 'info';
    }
  }

  getStatusOSSeverity(s: string): 'success' | 'info' | 'warn' | 'danger' {
    switch (s) {
      case 'Concluída': return 'success';
      case 'Em Andamento': return 'info';
      case 'Pendente': return 'warn';
      case 'Cancelada': return 'danger';
      default: return 'info';
    }
  }
}
