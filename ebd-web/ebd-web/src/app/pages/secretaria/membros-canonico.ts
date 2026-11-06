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
import { RouterModule } from '@angular/router';
import { MessageService } from 'primeng/api';
import { SecretariaService, MembroRol, RolMembrosStats, FichaMinisterial } from '../../core/secretaria.service';
import { PastorInfo } from '../../core/models';
import { PdfService } from '../../core/pdf.service';

import { StatCardComponent } from '../../shared/components/stat-card';

@Component({
  selector: 'app-membros-rol',
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
    RouterModule,
    StatCardComponent,
  ],
  providers: [MessageService],
  templateUrl: './membros-canonico.html',
})
export class MembrosRolPage implements OnInit {
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);
  private pdfSvc = inject(PdfService);

  membros = signal<MembroRol[]>([]);
  stats = signal<RolMembrosStats>({
    total: 0,
    comungantes: 0,
    nao_comungantes: 0,
    sob_disciplina: 0,
    jurisdicao_especial: 0,
    falecidos: 0,
  });
  loading = signal<boolean>(true);

  // Filtros
  statusFilter = '';
  searchQuery = '';

  statusOptions = [
    { label: 'Todos os Status', value: '' },
    { label: 'Comungantes', value: 'comungante' },
    { label: 'Não-comungantes', value: 'nao_comungante' },
    { label: 'Sob disciplina', value: 'sob_disciplina' },
    { label: 'Jurisdição especial', value: 'jurisdicao_especial' },
    { label: 'Falecidos', value: 'falecido' },
  ];

  // Modal Edição de Membro
  editDialog = false;
  selectedMembro: Partial<MembroRol> = {};

  // Modal Ficha Ministerial
  fichaDialog = false;
  fichaLoading = signal<boolean>(false);
  fichaData = signal<FichaMinisterial | null>(null);
  pastoresDisponiveis = signal<PastorInfo[]>([]);
  selectedPastorId = signal<number | null>(null);

  // Aba Ativa (Rol vs Solicitações)
  activeTab = signal<'rol' | 'solicitacoes'>('rol');

  // Solicitações de Cadastro (Link Público)
  solicitacoes = signal<any[]>([]);
  totalSolicitacoesPendentes = signal<number>(0);
  loadingSolicitacoes = signal<boolean>(false);
  selectedSolicitacao = signal<any | null>(null);
  detalheSolicitacaoDialog = false;
  rejeitarDialog = false;
  motivoRejeicao = '';

  // Modal Gerar Link de Cadastro
  linkPublicoDialog = false;
  linkPublicoUrl = signal<string>('');
  linkCopiado = signal<boolean>(false);

  ngOnInit(): void {
    this.carregarMembros();
    this.carregarSolicitacoes();
  }

  carregarSolicitacoes(): void {
    this.loadingSolicitacoes.set(true);
    this.secService.getMemberApplications().subscribe({
      next: (res) => {
        const data = res.data || [];
        this.solicitacoes.set(data);
        const pendentes = data.filter((x: any) => x.status === 'pendente').length;
        this.totalSolicitacoesPendentes.set(pendentes);
        this.loadingSolicitacoes.set(false);
      },
      error: () => {
        this.loadingSolicitacoes.set(false);
      },
    });
  }

  abrirModalLinkPublico(): void {
    const origin = window.location.origin;
    // O link público leva à rota de cadastro público de membros
    this.linkPublicoUrl.set(`${origin}/cadastro-membro`);
    this.linkCopiado.set(false);
    this.linkPublicoDialog = true;
  }

  copiarLinkPublico(): void {
    if (!this.linkPublicoUrl()) return;
    navigator.clipboard.writeText(this.linkPublicoUrl()).then(() => {
      this.linkCopiado.set(true);
      this.msg.add({
        severity: 'success',
        summary: 'Link Copiado!',
        detail: 'O endereço de cadastro de novos membros foi copiado para sua área de transferência.',
      });
      setTimeout(() => this.linkCopiado.set(false), 3000);
    });
  }

  abrirWhatsAppLink(): void {
    const texto = encodeURIComponent(
      `Paz do Senhor! Segue o link oficial para realizar o cadastro de membro em nossa Igreja Presbiteriana: ${this.linkPublicoUrl()}`
    );
    window.open(`https://wa.me/?text=${texto}`, '_blank');
  }

  verDetalhesSolicitacao(app: any): void {
    this.selectedSolicitacao.set(app);
    this.detalheSolicitacaoDialog = true;
  }

  aprovarSolicitacao(app: any): void {
    if (!app || !app.id) return;
    this.secService.approveMemberApplication(app.id).subscribe({
      next: (res) => {
        this.msg.add({
          severity: 'success',
          summary: 'Cadastro Aprovado!',
          detail: `${app.full_name} agora faz parte do Rol de Membros da igreja.`,
        });
        this.detalheSolicitacaoDialog = false;
        this.carregarSolicitacoes();
        this.carregarMembros();
      },
      error: (err) => {
        this.msg.add({
          severity: 'error',
          summary: 'Erro ao Aprovar',
          detail: err.error?.message || 'Falha ao processar a aprovação da solicitação.',
        });
      },
    });
  }

  abrirDialogRejeitar(app: any): void {
    this.selectedSolicitacao.set(app);
    this.motivoRejeicao = '';
    this.rejeitarDialog = true;
  }

  confirmarRejeicao(): void {
    const app = this.selectedSolicitacao();
    if (!app || !this.motivoRejeicao.trim()) {
      this.msg.add({
        severity: 'warn',
        summary: 'Atenção',
        detail: 'Informe o motivo da rejeição da solicitação.',
      });
      return;
    }

    this.secService.rejectMemberApplication(app.id, this.motivoRejeicao).subscribe({
      next: () => {
        this.msg.add({
          severity: 'info',
          summary: 'Solicitação Rejeitada',
          detail: 'O registro foi arquivado como rejeitado com o motivo informado.',
        });
        this.rejeitarDialog = false;
        this.detalheSolicitacaoDialog = false;
        this.carregarSolicitacoes();
      },
      error: (err) => {
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: err.error?.message || 'Falha ao rejeitar solicitação.',
        });
      },
    });
  }

  carregarMembros(): void {
    this.loading.set(true);
    this.secService
      .getMembros({
        status: this.statusFilter || undefined,
        search: this.searchQuery || undefined,
      })
      .subscribe({
        next: (res) => {
          this.membros.set(res.membros.data);
          this.stats.set(res.stats);
          this.loading.set(false);
        },
        error: () => {
          this.loading.set(false);
          this.msg.add({
            severity: 'error',
            summary: 'Erro',
            detail: 'Não foi possível carregar o rol de membros.',
          });
        },
      });
  }

  filtrarPorStatus(st: string): void {
    this.statusFilter = st;
    this.carregarMembros();
  }

  abrirEdicao(membro: MembroRol): void {
    this.selectedMembro = { ...membro };
    this.editDialog = true;
  }

  salvarEdicao(): void {
    if (!this.selectedMembro.id) return;
    this.secService.updateMembro(this.selectedMembro.id, this.selectedMembro).subscribe({
      next: (res) => {
        this.msg.add({
          severity: 'success',
          summary: 'Sucesso',
          detail: 'Dados do membro atualizados com sucesso.',
        });
        this.editDialog = false;
        this.carregarMembros();
      },
      error: () => {
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: 'Falha ao salvar dados do membro.',
        });
      },
    });
  }

  abrirFichaMinisterial(membro: MembroRol): void {
    this.fichaDialog = true;
    this.fichaLoading.set(true);
    this.secService.getFichaMinisterial(membro.id, this.selectedPastorId() || undefined).subscribe({
      next: (data) => {
        this.fichaData.set(data);
        if (data.pastores && data.pastores.length > 0) {
          this.pastoresDisponiveis.set(data.pastores);
        }
        if (data.pastor_responsavel?.id) {
          this.selectedPastorId.set(data.pastor_responsavel.id);
        }
        this.fichaLoading.set(false);
      },
      error: () => {
        this.fichaLoading.set(false);
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: 'Não foi possível carregar a ficha ministerial.',
        });
      },
    });
  }

  trocarPastor(pastorId: any): void {
    const id = Number(pastorId);
    this.selectedPastorId.set(id);
    const pastor = this.pastoresDisponiveis().find((x) => x.id === id);
    if (pastor && this.fichaData()) {
      const cur = this.fichaData()!;
      this.fichaData.set({
        ...cur,
        pastor_presidente: pastor.titulo_pastoral || pastor.nome,
        pastor_responsavel: {
          id: pastor.id,
          nome: pastor.titulo_pastoral || pastor.nome,
          cargo: pastor.cargo_pastoral || 'Pastor da Igreja',
          is_titular: pastor.is_pastor_titular,
        },
      });
    }
  }

  imprimirFicha(): void {
    const membro = this.fichaData()?.membro || this.fichaData()?.person;
    const nome = membro?.full_name ? membro.full_name.trim().replace(/\s+/g, '-').toLowerCase() : 'membro';
    this.pdfSvc.gerarPdfEmNovaAba('ficha-impressao-ipb', `ficha-ministerial-${nome}`);
  }

  abrirEdicaoDeFicha(): void {
    const data = this.fichaData();
    const membro = data?.membro || data?.person;
    if (membro) {
      this.fichaDialog = false;
      this.abrirEdicao(membro);
    }
  }

  getIniciais(nome?: string): string {
    if (!nome) return 'MB';
    const parts = nome.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  abrirWhatsApp(telefone?: string): void {
    if (!telefone) return;
    const num = telefone.replace(/\D/g, '');
    if (num) {
      window.open(`https://wa.me/55${num}`, '_blank');
    }
  }

  getStatusBadge(st: string): { label: string; severity: 'success' | 'info' | 'warn' | 'danger' | 'secondary' } {
    switch (st) {
      case 'comungante':
        return { label: 'Comungante', severity: 'success' };
      case 'nao_comungante':
        return { label: 'Não-comungante', severity: 'info' };
      case 'sob_disciplina':
        return { label: 'Sob Disciplina', severity: 'danger' };
      case 'jurisdicao_especial':
        return { label: 'Jurisdição Especial', severity: 'warn' };
      case 'falecido':
        return { label: 'Falecido', severity: 'secondary' };
      default:
        return { label: st || 'Comungante', severity: 'secondary' };
    }
  }

  getModoRecepcaoLabel(tp?: string): string {
    switch (tp) {
      case 'profissao_fe_batismo':
        return 'Profissão de Fé e Batismo';
      case 'profissao_fe':
        return 'Profissão de Fé';
      case 'transferencia':
        return 'Carta de Transferência';
      case 'batismo_infantil':
        return 'Batismo Infantil';
      case 'jurisdicao':
        return 'Jurisdição do Conselho';
      default:
        return tp || 'Não informado';
    }
  }
}

/**
 * Exportação de compatibilidade: MembrosCanonicoPage -> MembrosRolPage
 */
export { MembrosRolPage as MembrosCanonicoPage };

