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
import { PastorInfo } from '../../core/models';
import { PdfService } from '../../core/pdf.service';

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
  private pdfSvc = inject(PdfService);
  auth = inject(AuthService);

  sociedades = signal<SociedadeInterna[]>([]);
  membrosPotenciais = signal<Record<string, number>>({});
  pessoas = signal<CanonicalMember[]>([]);
  loading = signal<boolean>(true);

  activeSigla = 'SAF';
  activeTab: 'membros' | 'atas' | 'diretoria' | 'atividades' = 'membros';

  // --- 🏛️ CADASTRO & EDIÇÃO DE SOCIEDADE INTERNA ---
  sociedadeDialog = false;
  salvandoSociedade = signal(false);
  editandoSociedadeId: number | null = null;
  formSociedade = {
    sigla: '',
    nome: '',
    lema: '',
    target_gender: 'Ambos' as 'Masculino' | 'Feminino' | 'Ambos',
    min_age: null as number | null,
    max_age: null as number | null,
    is_active: true,
    notes: '',
    ano_exercicio: new Date().getFullYear(),
  };

  opcoesPublicoAlvo = [
    { label: 'Ambos (Masculino e Feminino)', value: 'Ambos' },
    { label: 'Masculino', value: 'Masculino' },
    { label: 'Feminino', value: 'Feminino' },
  ];

  abrirNovaSociedade(): void {
    this.editandoSociedadeId = null;
    this.formSociedade = {
      sigla: '',
      nome: '',
      lema: '',
      target_gender: 'Ambos',
      min_age: null,
      max_age: null,
      is_active: true,
      notes: '',
      ano_exercicio: new Date().getFullYear(),
    };
    this.sociedadeDialog = true;
  }

  abrirEditarSociedade(soc: SociedadeInterna): void {
    this.editandoSociedadeId = soc.id;
    this.formSociedade = {
      sigla: soc.sigla,
      nome: soc.nome,
      lema: soc.lema || '',
      target_gender: soc.target_gender || 'Ambos',
      min_age: soc.min_age !== undefined ? soc.min_age : null,
      max_age: soc.max_age !== undefined ? soc.max_age : null,
      is_active: soc.is_active !== undefined ? soc.is_active : true,
      notes: soc.notes || '',
      ano_exercicio: soc.ano_exercicio || new Date().getFullYear(),
    };
    this.sociedadeDialog = true;
  }

  salvarSociedade(): void {
    if (!this.formSociedade.sigla.trim() || !this.formSociedade.nome.trim()) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Informe a sigla e o nome da sociedade.' });
      return;
    }

    if (
      this.formSociedade.min_age !== null &&
      this.formSociedade.max_age !== null &&
      this.formSociedade.min_age > this.formSociedade.max_age
    ) {
      this.msg.add({
        severity: 'warn',
        summary: 'Faixa Etária Inválida',
        detail: 'A idade mínima não pode ser maior do que a idade máxima.',
      });
      return;
    }

    this.salvandoSociedade.set(true);
    const payload = {
      sigla: this.formSociedade.sigla.toUpperCase().trim(),
      nome: this.formSociedade.nome.trim(),
      lema: this.formSociedade.lema.trim() || undefined,
      target_gender: this.formSociedade.target_gender,
      min_age: this.formSociedade.min_age !== null && this.formSociedade.min_age !== undefined ? Number(this.formSociedade.min_age) : null,
      max_age: this.formSociedade.max_age !== null && this.formSociedade.max_age !== undefined ? Number(this.formSociedade.max_age) : null,
      is_active: this.formSociedade.is_active,
      notes: this.formSociedade.notes.trim() || undefined,
      ano_exercicio: Number(this.formSociedade.ano_exercicio) || new Date().getFullYear(),
    };

    const req$ = this.editandoSociedadeId
      ? this.secService.updateSociedade(this.editandoSociedadeId, payload)
      : this.secService.createSociedade(payload);

    req$.subscribe({
      next: (res) => {
        this.salvandoSociedade.set(false);
        this.msg.add({
          severity: 'success',
          summary: 'Sucesso',
          detail: `Sociedade ${res.sigla} ${this.editandoSociedadeId ? 'atualizada' : 'cadastrada'} com sucesso!`,
        });
        this.sociedadeDialog = false;
        this.activeSigla = res.sigla;
        this.carregarSociedades();
      },
      error: (err) => {
        this.salvandoSociedade.set(false);
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: err?.error?.message || 'Erro ao salvar sociedade interna.',
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

  // --- ⚡ ARROLAMENTO EM LOTE INTELIGENTE ---
  loteDialog = false;
  confirmacaoLoteDialog = false;
  candidatosLoading = signal(false);
  candidatosLote = signal<any[]>([]);
  candidatosMeta = signal<any>(null);
  loteSelecionados = signal<number[]>([]);
  loteTipo: 'efetivo' | 'cooperador' = 'efetivo';
  loteObservacoes = '';

  loteFiltro = {
    target_gender: 'Ambos',
    min_age: null as number | null,
    max_age: null as number | null,
    search: '',
    situacao_cadastral: 'ativo',
    situacao_sociedade: 'nao_arrolado',
    apenas_elegiveis: false,
  };

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
      label: `${p.full_name} (${p.gender || 'Não inf.'} • ${p.age !== null && p.age !== undefined ? p.age + ' anos' : 'Idade não inf.'} • ${p.canonical_status || 'Membro'})`,
      value: p.id,
      name: p.full_name,
    }));
  });

  pessoaSelecionadaInfo = computed(() => {
    const personId = this.novoMembro.person_id;
    if (!personId) return null;
    const p = this.pessoas().find((item) => item.id === personId);
    if (!p) return null;

    const soc = this.getSociedadeAtiva();
    if (!soc) return { pessoa: p, elegivel: true, avisos: [] as string[] };

    const avisos: string[] = [];
    const targetGender = soc.target_gender || 'Ambos';
    if (targetGender !== 'Ambos' && p.gender && p.gender.toLowerCase() !== targetGender.toLowerCase()) {
      avisos.push(`Sexo (${p.gender}) diverge do público de referência (${targetGender})`);
    }

    if (p.age === null || p.age === undefined) {
      avisos.push('Data de nascimento não cadastrada (idade não informada)');
    } else {
      if (soc.min_age !== null && soc.min_age !== undefined && p.age < soc.min_age) {
        avisos.push(`Idade (${p.age} anos) abaixo da idade mínima sugerida (${soc.min_age} anos)`);
      }
      if (soc.max_age !== null && soc.max_age !== undefined && p.age > soc.max_age) {
        avisos.push(`Idade (${p.age} anos) acima da idade máxima sugerida (${soc.max_age} anos)`);
      }
    }

    const jaArroladoAtivo = this.membros().some((m) => m.person_id === p.id && m.status === 'ativo');

    return {
      pessoa: p,
      elegivel: avisos.length === 0,
      avisos,
      jaArroladoAtivo,
    };
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

    const info = this.pessoaSelecionadaInfo();
    if (info?.jaArroladoAtivo) {
      this.msg.add({
        severity: 'error',
        summary: 'Vínculo Ativo Duplicado',
        detail: 'Esta pessoa já possui vínculo ativo com esta sociedade.',
      });
      return;
    }

    this.secService.addSociedadeMembro(soc.id, this.novoMembro).subscribe({
      next: (res) => {
        if (res.aviso) {
          this.msg.add({
            severity: 'warn',
            summary: 'Sócio Arrolado com Aviso',
            detail: res.aviso,
            life: 6000,
          });
        } else {
          this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Membro arrolado com sucesso na sociedade!' });
        }
        this.membroDialog = false;
        this.carregarMembros(soc.id);
        this.carregarSociedades();
      },
      error: (err) => {
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: err?.error?.message || 'Falha ao arrolar membro.',
        });
      },
    });
  }

  // --- ⚡ MÉTODOS DE ARROLAMENTO EM LOTE INTELIGENTE ---

  abrirLoteDialog(): void {
    const soc = this.getSociedadeAtiva();
    if (!soc) return;

    // Carrega automaticamente os filtros com base nas configurações da sociedade
    this.loteFiltro = {
      target_gender: soc.target_gender || 'Ambos',
      min_age: soc.min_age ?? null,
      max_age: soc.max_age ?? null,
      search: '',
      situacao_cadastral: 'ativo',
      situacao_sociedade: 'nao_arrolado',
      apenas_elegiveis: false,
    };

    this.loteTipo = 'efetivo';
    this.loteObservacoes = '';
    this.loteSelecionados.set([]);
    this.loteDialog = true;

    this.carregarCandidatosLote();
  }

  carregarCandidatosLote(): void {
    const soc = this.getSociedadeAtiva();
    if (!soc) return;

    this.candidatosLoading.set(true);
    this.secService.getCandidatosArrolamento(soc.id, this.loteFiltro).subscribe({
      next: (res) => {
        this.candidatosLote.set(res.data);
        this.candidatosMeta.set(res);
        this.candidatosLoading.set(false);

        // Se a seleção estiver vazia, pré-seleciona os que são compatíveis e ainda não estão arrolados
        if (this.loteSelecionados().length === 0) {
          const elegiveis = res.data
            .filter((c: any) => !c.ja_arrolado && c.elegibilidade?.is_eligible)
            .map((c: any) => c.id);
          this.loteSelecionados.set(elegiveis);
        }
      },
      error: () => {
        this.candidatosLoading.set(false);
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Não foi possível carregar os candidatos ao arrolamento.' });
      },
    });
  }

  restaurarFiltrosOriginais(): void {
    const soc = this.getSociedadeAtiva();
    if (!soc) return;
    this.loteFiltro = {
      target_gender: soc.target_gender || 'Ambos',
      min_age: soc.min_age ?? null,
      max_age: soc.max_age ?? null,
      search: '',
      situacao_cadastral: 'ativo',
      situacao_sociedade: 'nao_arrolado',
      apenas_elegiveis: false,
    };
    this.carregarCandidatosLote();
  }

  isLoteSelecionado(id: number): boolean {
    return this.loteSelecionados().includes(id);
  }

  toggleSelecaoLote(id: number): void {
    const cur = this.loteSelecionados();
    if (cur.includes(id)) {
      this.loteSelecionados.set(cur.filter((x) => x !== id));
    } else {
      this.loteSelecionados.set([...cur, id]);
    }
  }

  marcarTodosElegiveisLote(): void {
    const elegiveis = this.candidatosLote()
      .filter((c) => !c.ja_arrolado)
      .map((c) => c.id);
    this.loteSelecionados.set(Array.from(new Set([...this.loteSelecionados(), ...elegiveis])));
  }

  desmarcarTodosLote(): void {
    this.loteSelecionados.set([]);
  }

  // Diálogo de Confirmação Seguro
  resumoConfirmacaoLote = computed(() => {
    const soc = this.getSociedadeAtiva();
    const selecionados = this.loteSelecionados();
    const candidatos = this.candidatosLote();

    const mapa = new Map(candidatos.map((c) => [c.id, c]));
    let jaArroladosCount = 0;
    let foraFaixaCount = 0;

    for (const id of selecionados) {
      const c = mapa.get(id);
      if (c) {
        if (c.ja_arrolado) jaArroladosCount++;
        if (!c.elegibilidade?.is_eligible) foraFaixaCount++;
      }
    }

    const novosCount = Math.max(0, selecionados.length - jaArroladosCount);

    return {
      sociedadeSigla: soc?.sigla || '',
      sociedadeNome: soc?.nome || '',
      totalSelecionados: selecionados.length,
      jaArroladosCount,
      novosCount,
      foraFaixaCount,
      tipoLabel: this.loteTipo === 'efetivo' ? 'Sócio Efetivo (Comungante)' : 'Sócio Cooperador',
    };
  });

  abrirConfirmacaoLote(): void {
    if (this.loteSelecionados().length === 0) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Nenhuma pessoa selecionada para arrolamento.' });
      return;
    }
    this.confirmacaoLoteDialog = true;
  }

  salvarLoteConfirmado(): void {
    const soc = this.getSociedadeAtiva();
    if (!soc || this.loteSelecionados().length === 0) return;

    this.salvandoSociedade.set(true);
    this.secService
      .arrolarMembrosEmLote(soc.id, {
        person_ids: this.loteSelecionados(),
        tipo_socio: this.loteTipo,
        observacoes: this.loteObservacoes.trim() || undefined,
      })
      .subscribe({
        next: (res) => {
          this.salvandoSociedade.set(false);
          this.confirmacaoLoteDialog = false;
          this.loteDialog = false;

          const r = res.resumo;
          this.msg.add({
            severity: 'success',
            summary: 'Arrolamento Efetivado',
            detail: `Sucesso: ${r.novos_arrolados} novos sócios arrolados na ${soc.sigla}. (${r.ja_arrolados} já eram sócios ativos).`,
            life: 6000,
          });

          this.carregarMembros(soc.id);
          this.carregarSociedades();
        },
        error: (err) => {
          this.salvandoSociedade.set(false);
          this.msg.add({
            severity: 'error',
            summary: 'Erro',
            detail: err?.error?.message || 'Falha ao efetivar o arrolamento em lote.',
          });
        },
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
  pastoresDisponiveis = signal<PastorInfo[]>([]);
  selectedPastorId = signal<number | null>(null);

  abrirFicha(p?: { id: number } | null): void {
    if (!p?.id) return;
    this.fichaDialog = true;
    this.fichaLoading.set(true);
    this.secService.getFichaMinisterial(p.id, this.selectedPastorId() || undefined).subscribe({
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
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Não foi possível carregar a ficha completa do membro.' });
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
    this.pdfSvc.gerarPdfEmNovaAba('ficha-impressao-ipb', `ficha-sociedade-${nome}`);
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
