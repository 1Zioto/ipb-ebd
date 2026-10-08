import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { SecretariaService, SociedadeInterna, CanonicalMember } from '../../core/secretaria.service';

@Component({
  selector: 'app-sociedades',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    TagModule,
    DialogModule,
    InputTextModule,
    ToastModule,
  ],
  providers: [MessageService],
  templateUrl: './sociedades.html',
})
export class SociedadesPage implements OnInit {
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);

  sociedades = signal<SociedadeInterna[]>([]);
  membrosPotenciais = signal<Record<string, number>>({});
  membros = signal<CanonicalMember[]>([]);
  loading = signal<boolean>(true);

  activeSigla = 'SAF';

  // Modal Nova Diretoria
  diretoriaDialog = false;
  novoOficial = {
    cargo: 'Presidente',
    person_id: null as number | null,
    ano: 2026,
  };

  // Modal Nova Atividade
  atividadeDialog = false;
  novaAtividade = {
    titulo: '',
    tipo: 'Reunião',
    data: new Date().toISOString().substring(0, 10),
    horario: '19:30',
    local: 'Salão Social',
    descricao: '',
  };

  cargosPadrao = [
    'Presidente',
    'Vice-Presidente',
    '1ª Secretária(o)',
    '2ª Secretária(o)',
    'Secretário(a) Executivo(a)',
    'Tesoureira(o)',
    'Conselheira(o) / Orientador(a)',
    'Presidente Mirim',
  ];

  tiposAtividade = [
    'Reunião Plenária',
    'Reunião de Oração',
    'Chá / Confraternização',
    'Culto com a Sociedade',
    'Congresso / Retiro',
    'Ação Social / Diaconal',
    'Estudo Bíblico',
  ];

  ngOnInit(): void {
    this.carregarSociedades();
    this.carregarMembros();
  }

  carregarSociedades(): void {
    this.loading.set(true);
    this.secService.getSociedades().subscribe({
      next: (res) => {
        this.sociedades.set(res.sociedades);
        this.membrosPotenciais.set(res.membros_potenciais);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Erro ao carregar sociedades internas.' });
      },
    });
  }

  carregarMembros(): void {
    this.secService.getMembros().subscribe({
      next: (res) => this.membros.set(res.membros.data),
    });
  }

  getSociedadeAtiva(): SociedadeInterna | undefined {
    return this.sociedades().find((s) => s.sigla === this.activeSigla);
  }

  selecionarSociedade(sigla: string): void {
    this.activeSigla = sigla;
  }

  abrirNovoOficial(): void {
    this.novoOficial = {
      cargo: 'Presidente',
      person_id: null,
      ano: 2026,
    };
    this.diretoriaDialog = true;
  }

  salvarOficial(): void {
    const soc = this.getSociedadeAtiva();
    if (!soc || !this.novoOficial.person_id) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Selecione um membro para o cargo.' });
      return;
    }

    this.secService.addSociedadeDiretoria(soc.id, {
      cargo: this.novoOficial.cargo,
      person_id: this.novoOficial.person_id,
      ano: this.novoOficial.ano,
    }).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Membro eleito adicionado à diretoria!' });
        this.diretoriaDialog = false;
        this.carregarSociedades();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao salvar membro da diretoria.' }),
    });
  }

  abrirNovaAtividade(): void {
    this.novaAtividade = {
      titulo: '',
      tipo: 'Reunião Plenária',
      data: new Date().toISOString().substring(0, 10),
      horario: '19:30',
      local: 'Salão Social',
      descricao: '',
    };
    this.atividadeDialog = true;
  }

  salvarAtividade(): void {
    const soc = this.getSociedadeAtiva();
    if (!soc || !this.novaAtividade.titulo || !this.novaAtividade.data) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Preencha o título e a data da atividade.' });
      return;
    }

    this.secService.addSociedadeAtividade(soc.id, this.novaAtividade).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Atividade registrada no calendário!' });
        this.atividadeDialog = false;
        this.carregarSociedades();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao cadastrar atividade.' }),
    });
  }
}
