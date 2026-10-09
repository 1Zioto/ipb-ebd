import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TableModule } from 'primeng/table';
import { SelectModule } from 'primeng/select';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { TooltipModule } from 'primeng/tooltip';
import { MessageService } from 'primeng/api';
import { SecretariaService, SociedadeInterna, SociedadeMembro, SociedadeAta, CanonicalMember, FichaMinisterial } from '../../core/secretaria.service';
import { StatCardComponent } from '../../shared/components/stat-card';
import { AuthService } from '../../core/auth.service';

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
    TableModule,
    SelectModule,
    IconFieldModule,
    InputIconModule,
    TooltipModule,
  ],
  providers: [MessageService],
  templateUrl: './sociedades.html',
})
export class SociedadesPage implements OnInit {
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);
  auth = inject(AuthService);

  sociedades = signal<SociedadeInterna[]>([]);
  membrosPotenciais = signal<Record<string, number>>({});
  pessoas = signal<CanonicalMember[]>([]);
  loading = signal<boolean>(true);

  activeSigla = 'SAF';
  activeTab: 'membros' | 'atas' | 'diretoria' | 'atividades' = 'membros';

  // --- 🏛️ CRIAÇÃO DE NOVA SOCIEDADE INTERNA ---
  novaSociedadeDialog = false;
  salvandoSociedade = signal(false);
  novaSociedadeForm = {
    sigla: '',
    nome: '',
    lema: '',
    faixa_etaria: '',
    ano_exercicio: new Date().getFullYear(),
  };

  abrirNovaSociedade(): void {
    this.novaSociedadeForm = {
      sigla: '',
      nome: '',
      lema: '',
      faixa_etaria: '',
      ano_exercicio: new Date().getFullYear(),
    };
    this.novaSociedadeDialog = true;
  }

  salvarNovaSociedade(): void {
    if (!this.novaSociedadeForm.sigla.trim() || !this.novaSociedadeForm.nome.trim()) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Informe a sigla e o nome da sociedade.' });
      return;
    }

    this.salvandoSociedade.set(true);
    this.secService
      .createSociedade({
        sigla: this.novaSociedadeForm.sigla.toUpperCase().trim(),
        nome: this.novaSociedadeForm.nome.trim(),
        lema: this.novaSociedadeForm.lema.trim() || undefined,
        faixa_etaria: this.novaSociedadeForm.faixa_etaria.trim() || undefined,
        ano_exercicio: Number(this.novaSociedadeForm.ano_exercicio) || new Date().getFullYear(),
      })
      .subscribe({
        next: (nova) => {
          this.salvandoSociedade.set(false);
          this.msg.add({ severity: 'success', summary: 'Sucesso', detail: `Sociedade ${nova.sigla} criada com sucesso!` });
          this.novaSociedadeDialog = false;
          this.activeSigla = nova.sigla;
          this.carregarSociedades();
        },
        error: (err) => {
          this.salvandoSociedade.set(false);
          this.msg.add({
            severity: 'error',
            summary: 'Erro',
            detail: err?.error?.message || 'Não foi possível criar a nova sociedade.',
          });
        },
      });
  }

  // --- 👥 ROL DE SÓCIOS / MEMBROS ---
  membros = signal<SociedadeMembro[]>([]);
  membrosLoading = signal<boolean>(false);
  membroBusca = '';
  tipoFilter = '';

  membroDialog = false;
  novoMembro = {
    person_id: null as number | null,
    tipo_socio: 'efetivo' as 'efetivo' | 'cooperador',
    data_admissao: new Date().toISOString().substring(0, 10),
    cargo_atual: '',
    observacoes: '',
  };

  // Arrolamento em Lote
  loteDialog = false;
  loteTipo = 'efetivo';
  loteBusca = '';
  loteSelecionados: number[] = [];

  // --- 📖 LIVRO DE ATAS ---
  atas = signal<SociedadeAta[]>([]);
  atasLoading = signal<boolean>(false);
  ataDialog = false;
  visualizarAtaDialog = false;
  ataSelecionada = signal<SociedadeAta | null>(null);

  novaAta = {
    numero_ata: '',
    titulo: '',
    tipo_reuniao: 'Plenária Ordinária',
    data_reuniao: new Date().toISOString().substring(0, 10),
    horario: '19:30',
    local: 'Salão Social',
    presidente_id: null as number | null,
    secretario_id: null as number | null,
    pauta: '',
    conteudo: '',
    presentes_count: 0,
    status: 'Aprovada' as 'Rascunho' | 'Aprovada' | 'Assinada',
  };

  // --- 👥 DIRETORIA & ATIVIDADES ---
  diretoriaDialog = false;
  novoOficial = {
    cargo: 'Presidente',
    person_id: null as number | null,
    ano: 2026,
  };

  atividadeDialog = false;
  novaAtividade = {
    titulo: '',
    tipo: 'Reunião Plenária',
    data: new Date().toISOString().substring(0, 10),
    horario: '19:30',
    local: 'Salão Social',
    descricao: '',
  };

  tiposReuniaoAta = [
    { label: 'Plenária Ordinária', value: 'Plenária Ordinária' },
    { label: 'Plenária Extraordinária', value: 'Plenária Extraordinária' },
    { label: 'Reunião de Diretoria', value: 'Reunião de Diretoria' },
    { label: 'Assembleia Geral Eletiva', value: 'Assembleia Geral Eletiva' },
  ];

  cargosPadrao = [
    'Presidente',
    'Vice-Presidente',
    '1ª Secretária(o)',
    '2ª Secretária(o)',
    'Secretário(a) Executivo(a)',
    'Tesoureira(o)',
    'Conselheira(o) / Orientador(a)',
    'Secretária(o) de Espiritualidade',
    'Secretária(o) de Evangelização',
    'Secretária(o) de Ação Social',
    'Presidente Mirim (UCP)',
  ];

  tiposSocio = [
    { label: 'Sócio Efetivo (Comungante / Pleno)', value: 'efetivo' },
    { label: 'Sócio Cooperador (Não-comungante / Visitante)', value: 'cooperador' },
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
    this.carregarPessoas();
  }

  carregarSociedades(): void {
    this.loading.set(true);
    this.secService.getSociedades().subscribe({
      next: (res) => {
        this.sociedades.set(res.sociedades);
        this.membrosPotenciais.set(res.membros_potenciais);
        this.loading.set(false);

        // Carrega dados da sociedade ativa
        const ativa = this.getSociedadeAtiva();
        if (ativa) {
          this.carregarMembros(ativa.id);
          this.carregarAtas(ativa.id);
        }
      },
      error: () => {
        this.loading.set(false);
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Erro ao carregar sociedades internas.' });
      },
    });
  }

  carregarPessoas(): void {
    this.secService.getMembros().subscribe({
      next: (res) => this.pessoas.set(res.membros.data),
    });
  }

  getSociedadeAtiva(): SociedadeInterna | undefined {
    return this.sociedades().find((s) => s.sigla === this.activeSigla);
  }

  selecionarSociedade(sigla: string): void {
    this.activeSigla = sigla;
    const soc = this.getSociedadeAtiva();
    if (soc) {
      this.carregarMembros(soc.id);
      this.carregarAtas(soc.id);
    }
  }

  // --- 👥 MÉTODOS DE MEMBROS ---

  carregarMembros(sociedadeId: number): void {
    this.membrosLoading.set(true);
    this.secService.getSociedadeMembros(sociedadeId).subscribe({
      next: (res) => {
        this.membros.set(res.data);
        this.membrosLoading.set(false);
      },
      error: () => this.membrosLoading.set(false),
    });
  }

  membrosFiltrados = computed(() => {
    let list = this.membros();
    if (this.tipoFilter) {
      list = list.filter((m) => m.tipo_socio === this.tipoFilter);
    }
    if (this.membroBusca.trim()) {
      const q = this.membroBusca.toLowerCase();
      list = list.filter((m) => m.person?.full_name?.toLowerCase().includes(q) || m.cargo_atual?.toLowerCase().includes(q));
    }
    return list;
  });

  pessoasOpcoes = computed(() => {
    return this.pessoas().map((p) => ({
      label: `${p.full_name} (${p.canonical_status || 'Membro'}${p.age ? ' • ' + p.age + ' anos' : ''})`,
      value: p.id,
      name: p.full_name,
    }));
  });

  pessoasElegiveisParaLote = computed(() => {
    const inscritosIds = new Set(this.membros().map((m) => m.person_id));
    const all = this.pessoas().filter((p) => !inscritosIds.has(p.id));
    const sigla = this.activeSigla;

    return all.filter((p) => {
      const idade = p.age ?? 30;
      const notes = (p.notes ?? '').toLowerCase();
      switch (sigla) {
        case 'SAF':
          return idade >= 20 || notes.includes('feminino') || notes.includes('mulher');
        case 'UPH':
          return idade >= 18 && (notes.includes('masculino') || !notes.includes('feminino'));
        case 'UMP':
          return idade >= 18 && idade <= 35;
        case 'UPA':
          return idade >= 12 && idade <= 17;
        case 'UCP':
          return idade <= 11;
        default:
          return true;
      }
    });
  });

  pessoasElegiveisFiltradas = computed(() => {
    const list = this.pessoasElegiveisParaLote();
    if (!this.loteBusca.trim()) return list;
    const term = this.loteBusca.toLowerCase().trim();
    return list.filter((p) => p.full_name.toLowerCase().includes(term));
  });

  abrirNovoMembro(): void {
    this.novoMembro = {
      person_id: null,
      tipo_socio: 'efetivo',
      data_admissao: new Date().toISOString().substring(0, 10),
      cargo_atual: '',
      observacoes: '',
    };
    this.membroDialog = true;
  }

  salvarMembro(): void {
    const soc = this.getSociedadeAtiva();
    if (!soc || !this.novoMembro.person_id) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Selecione uma pessoa da igreja para arrolar.' });
      return;
    }

    this.secService.addSociedadeMembro(soc.id, this.novoMembro).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Membro arrolado com sucesso na sociedade!' });
        this.membroDialog = false;
        this.carregarMembros(soc.id);
        this.carregarSociedades();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao arrolar membro.' }),
    });
  }

  abrirLoteDialog(): void {
    this.loteTipo = 'efetivo';
    this.loteBusca = '';
    this.loteSelecionados = this.pessoasElegiveisParaLote().map((p) => p.id);
    this.loteDialog = true;
  }

  toggleSelecaoLote(personId: number): void {
    if (this.loteSelecionados.includes(personId)) {
      this.loteSelecionados = this.loteSelecionados.filter((id) => id !== personId);
    } else {
      this.loteSelecionados = [...this.loteSelecionados, personId];
    }
  }

  toggleSelecionarTodosLote(): void {
    const visiveis = this.pessoasElegiveisFiltradas().map((p) => p.id);
    const todosVisiveisInclusos = visiveis.length > 0 && visiveis.every((id) => this.loteSelecionados.includes(id));
    if (todosVisiveisInclusos) {
      this.loteSelecionados = this.loteSelecionados.filter((id) => !visiveis.includes(id));
    } else {
      this.loteSelecionados = Array.from(new Set([...this.loteSelecionados, ...visiveis]));
    }
  }

  salvarLote(): void {
    const soc = this.getSociedadeAtiva();
    if (!soc || this.loteSelecionados.length === 0) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Nenhuma pessoa selecionada para arrolamento.' });
      return;
    }

    this.secService.arrolarMembrosEmLote(soc.id, {
      person_ids: this.loteSelecionados,
      tipo_socio: this.loteTipo,
    }).subscribe({
      next: (res) => {
        this.msg.add({ severity: 'success', summary: 'Arrolamento Concluído', detail: res.message });
        this.loteDialog = false;
        this.carregarMembros(soc.id);
        this.carregarSociedades();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha no arrolamento em lote.' }),
    });
  }

  excluirMembro(m: SociedadeMembro): void {
    const soc = this.getSociedadeAtiva();
    if (!soc) return;

    if (confirm(`Deseja remover "${m.person?.full_name}" do rol de sócios da ${soc.sigla}?`)) {
      this.secService.removeSociedadeMembro(soc.id, m.id).subscribe({
        next: () => {
          this.msg.add({ severity: 'info', summary: 'Removido', detail: 'Sócio removido da sociedade.' });
          this.carregarMembros(soc.id);
          this.carregarSociedades();
        },
        error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao remover sócio.' }),
      });
    }
  }

  // --- 📖 MÉTODOS DE LIVRO DE ATAS ---

  carregarAtas(sociedadeId: number): void {
    this.atasLoading.set(true);
    this.secService.getSociedadeAtas(sociedadeId).subscribe({
      next: (res) => {
        this.atas.set(res.data);
        this.atasLoading.set(false);
      },
      error: () => this.atasLoading.set(false),
    });
  }

  abrirNovaAta(): void {
    const soc = this.getSociedadeAtiva();
    const proximaAta = (this.atas().length + 1).toString().padStart(2, '0');
    const ano = soc?.ano_exercicio ?? 2026;

    this.novaAta = {
      numero_ata: `Ata nº ${proximaAta}/${ano}`,
      titulo: `Reunião Plenária da ${soc?.sigla ?? 'Sociedade'}`,
      tipo_reuniao: 'Plenária Ordinária',
      data_reuniao: new Date().toISOString().substring(0, 10),
      horario: '19:30',
      local: 'Salão Social da Igreja',
      presidente_id: null,
      secretario_id: null,
      pauta: '1. Abertura com oração e cânticos;\n2. Leitura da ata anterior;\n3. Expediente e planejamento de atividades comunitárias;\n4. Relatório da tesouraria.',
      conteudo: `Aos [dia] dias do mês de [mês] do ano de dois mil e vinte e seis, às 19h30, reuniu-se ordinariamente a ${soc?.nome} (${soc?.sigla}) em seu salão social para a realização de sua reunião plenária. Aberta a sessão sob a presidência, foram tratados os assuntos de pauta conforme deliberado pelos sócios presentes. Nada mais havendo a tratar, foi lavrada a presente ata que, após lida e aprovada, segue assinada pela diretoria.`,
      presentes_count: this.membros().length || 10,
      status: 'Aprovada',
    };
    this.ataDialog = true;
  }

  salvarAta(): void {
    const soc = this.getSociedadeAtiva();
    if (!soc || !this.novaAta.numero_ata || !this.novaAta.conteudo) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Preencha o número e o texto da ata.' });
      return;
    }

    this.secService.addSociedadeAta(soc.id, this.novaAta).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Ata lavrada e registrada no Livro com sucesso!' });
        this.ataDialog = false;
        this.carregarAtas(soc.id);
        this.carregarSociedades();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao lavrar ata.' }),
    });
  }

  visualizarAta(ata: SociedadeAta): void {
    this.ataSelecionada.set(ata);
    this.visualizarAtaDialog = true;
  }

  excluirAta(ata: SociedadeAta): void {
    const soc = this.getSociedadeAtiva();
    if (!soc) return;

    if (confirm(`Deseja excluir a ${ata.numero_ata}?`)) {
      this.secService.deleteSociedadeAta(soc.id, ata.id).subscribe({
        next: () => {
          this.msg.add({ severity: 'info', summary: 'Excluída', detail: 'Ata removida do livro.' });
          this.carregarAtas(soc.id);
          this.carregarSociedades();
        },
        error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao excluir ata.' }),
      });
    }
  }

  imprimirAta(): void {
    window.print();
  }

  // --- 👥 MÉTODOS DE DIRETORIA & ATIVIDADES ---

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
        this.carregarMembros(soc.id);
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

  // --- 📜 DOSSIÊ & FICHA MINISTERIAL DO SÓCIO ---
  fichaDialog = false;
  fichaLoading = signal(false);
  fichaData = signal<FichaMinisterial | null>(null);

  abrirFicha(p?: { id: number } | null): void {
    if (!p?.id) return;
    this.fichaDialog = true;
    this.fichaLoading.set(true);
    this.secService.getFichaMinisterial(p.id).subscribe({
      next: (data) => {
        this.fichaData.set(data);
        this.fichaLoading.set(false);
      },
      error: () => {
        this.fichaLoading.set(false);
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Não foi possível carregar a ficha completa do membro.' });
      },
    });
  }

  imprimirFicha(): void {
    window.print();
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

  getStatusBadge(st?: string): { label: string; severity: 'success' | 'info' | 'warn' | 'danger' | 'secondary' } {
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
