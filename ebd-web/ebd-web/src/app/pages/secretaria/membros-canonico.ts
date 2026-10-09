import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { InputTextModule } from 'primeng/inputtext';
import { DialogModule } from 'primeng/dialog';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { SecretariaService, CanonicalMember, CanonicalStats, FichaMinisterial } from '../../core/secretaria.service';

import { StatCardComponent } from '../../shared/components/stat-card';

@Component({
  selector: 'app-membros-canonico',
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
    StatCardComponent,
  ],
  providers: [MessageService],
  templateUrl: './membros-canonico.html',
})
export class MembrosCanonicoPage implements OnInit {
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);

  membros = signal<CanonicalMember[]>([]);
  stats = signal<CanonicalStats>({
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

  // Modal Edição Canônica
  editDialog = false;
  selectedMembro: Partial<CanonicalMember> = {};

  // Modal Ficha Ministerial
  fichaDialog = false;
  fichaLoading = signal<boolean>(false);
  fichaData = signal<FichaMinisterial | null>(null);

  ngOnInit(): void {
    this.carregarMembros();
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
            detail: 'Não foi possível carregar o rol canônico.',
          });
        },
      });
  }

  filtrarPorStatus(st: string): void {
    this.statusFilter = st;
    this.carregarMembros();
  }

  abrirEdicao(membro: CanonicalMember): void {
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
          detail: 'Dados canônicos atualizados com sucesso.',
        });
        this.editDialog = false;
        this.carregarMembros();
      },
      error: () => {
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: 'Falha ao salvar dados canônicos.',
        });
      },
    });
  }

  abrirFichaMinisterial(membro: CanonicalMember): void {
    this.fichaDialog = true;
    this.fichaLoading.set(true);
    this.secService.getFichaMinisterial(membro.id).subscribe({
      next: (data) => {
        this.fichaData.set(data);
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

  imprimirFicha(): void {
    window.print();
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
