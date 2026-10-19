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
import { SecretariaService, MembroRol } from '../../../core/secretaria.service';
import { AuthService } from '../../../core/auth.service';
import { PdfService } from '../../../core/pdf.service';

export interface TeamMember {
  name: string;
  role: string;
  memberId?: number | string;
  phone?: string;
}

export interface SecretariaItem {
  id: string;
  name: string;
  icon: string;
  desc: string;
  leader: string;
  leaderPhone: string;
  vice?: string;
  team: TeamMember[];
}

export interface SociedadeItem {
  id: string;
  name: string;
  sigla: string;
  badge: string;
  moto: string;
  color: string;
  icon: string;
  conselheiro: string;
  board: {
    presidente: string;
    vice: string;
    sec1: string;
    sec2: string;
    tesoureira: string;
  };
  membersCount: number;
}

export interface OficialItem {
  name: string;
  role: string;
  organ: string;
  mandate: string;
  status: 'Ativo' | 'Vencendo';
  phone: string;
  bg: string;
}

export interface ProfessorItem {
  classe: string;
  subtitulo: string;
  alunosCount: number;
  titular: string;
  auxiliar: string;
  icon: string;
  color: string;
}

@Component({
  selector: 'app-oficiais-lideranca',
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
  templateUrl: './oficiais-lideranca.html',
})
export class OficiaisLiderancaPage implements OnInit {
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);
  private pdfSvc = inject(PdfService);
  auth = inject(AuthService);

  activeTab: 'secretarias' | 'sociedades' | 'oficiais' | 'professores' = 'secretarias';
  loading = signal<boolean>(false);

  // --- MEMBROS REGISTRADOS NA IGREJA (PARA BUSCA AUTOMÁTICA) ---
  membrosCadastrados = signal<MembroRol[]>([]);
  searchMemberQuery = '';
  selectedMember: MembroRol | null = null;
  memberRole = '';
  memberPhone = '';

  // --- SECRETARIAS / MINISTÉRIOS ---
  secretarias = signal<SecretariaItem[]>([
    {
      id: 'sec_som',
      name: 'Secretaria de Sonoplastia & Áudio',
      icon: '🎛️',
      desc: 'Responsável pela equalização, microfones, gravação de mensagens e som ao vivo nos cultos e eventos.',
      leader: 'Diác. Rafael Siqueira',
      leaderPhone: '(11) 98765-6677',
      vice: 'Lucas Tadeu de Oliveira',
      team: [
        { name: 'Lucas Tadeu de Oliveira', role: 'Operador de Mesa Principal', phone: '(11) 98765-1100' },
        { name: 'Felipe Nogueira Santos', role: 'Microfonia & Cabos', phone: '(11) 98765-3300' },
        { name: 'Gustavo Dias Albuquerque', role: 'Auxiliar de Áudio', phone: '(11) 98765-4400' },
      ],
    },
    {
      id: 'sec_midia',
      name: 'Secretaria de Multimídia & Transmissão',
      icon: '📽️',
      desc: 'Responsável pela projeção das letras de cânticos, transmissão ao vivo no YouTube e câmeras do templo.',
      leader: 'Thiago Viana',
      leaderPhone: '(11) 98111-2244',
      vice: 'Larissa Coutinho',
      team: [
        { name: 'Mateus Ribeiro Fontes', role: 'Direção de Corte de Câmeras', phone: '(11) 98765-5500' },
        { name: 'Mariana Pontes Fontes', role: 'Projeção de Letras / Slides', phone: '(11) 98765-6600' },
        { name: 'Rodrigo Alencar Lima', role: 'Transmissão Streaming', phone: '(11) 98765-7700' },
      ],
    },
    {
      id: 'sec_eventos',
      name: 'Secretaria de Eventos & Recepção',
      icon: '🎉',
      desc: 'Planejamento e organização de conferências, congressos, jantares comunitários e acolhimento de visitantes.',
      leader: 'Cláudia Fagundes',
      leaderPhone: '(11) 98222-3355',
      vice: 'Diác. Marcelo Ramos',
      team: [
        { name: 'Patrícia Souza Ramos', role: 'Recepção de Visitantes', phone: '(11) 98765-8800' },
        { name: 'Beatriz Silva de Oliveira', role: 'Coordenação de Acolhimento', phone: '(11) 98765-2200' },
      ],
    },
    {
      id: 'sec_missoes',
      name: 'Secretaria de Missões & Evangelismo',
      icon: '🌍',
      desc: 'Apoio a missionários no campo, viagens missionárias, folhetos de evangelização e plantação de congregações.',
      leader: 'Pb. Sérgio Luiz Guimarães',
      leaderPhone: '(11) 99555-6677',
      vice: 'Carlos Eduardo',
      team: [
        { name: 'Felipe Nogueira Santos', role: 'Correspondência Missionária', phone: '(11) 98765-3300' },
      ],
    },
    {
      id: 'sec_louvor',
      name: 'Secretaria de Música & Louvor',
      icon: '🎵',
      desc: 'Coordenação dos grupos de cânticos, instrumentistas, coral da igreja e escalas dominicais de louvor.',
      leader: 'Maestro Paulo César',
      leaderPhone: '(11) 98333-4466',
      vice: 'Débora Lins',
      team: [
        { name: 'Samuel Santos Andrade', role: 'Líder de Instrumentistas', phone: '(11) 98765-9900' },
      ],
    },
    {
      id: 'sec_social',
      name: 'Secretaria de Ação Social & Diaconia',
      icon: '🤝',
      desc: 'Distribuição mensal de cestas básicas, roupas, apoio a famílias vulneráveis e asilos da comunidade.',
      leader: 'Diác. Marcos Vinícius Oliveira',
      leaderPhone: '(11) 98765-1122',
      vice: 'Teresa Cristina',
      team: [
        { name: 'Diác. Rafael Siqueira', role: 'Triagem Social & Logística', phone: '(11) 98765-6677' },
      ],
    },
    {
      id: 'sec_comunicacao',
      name: 'Secretaria de Comunicação & Redes Sociais',
      icon: '💻',
      desc: 'Gestão do Instagram oficial da igreja, avisos no WhatsApp, design de artes gráficas e fotografia dos cultos.',
      leader: 'Vinícius Toledo',
      leaderPhone: '(11) 95522-1100',
      vice: 'Fernanda Prado',
      team: [
        { name: 'Rodrigo Alencar Lima', role: 'Gestão de Mídias Sociais', phone: '(11) 98765-7700' },
      ],
    },
  ]);

  // --- SOCIEDADES INTERNAS ---
  sociedades = signal<SociedadeItem[]>([
    {
      id: 'soc_saf',
      name: 'Sociedade Auxiliadora Feminina',
      sigla: 'SAF',
      badge: 'Mulheres da IPB',
      moto: 'Sejamos verdadeiras auxiliadoras',
      color: '#be185d',
      icon: '🌸',
      conselheiro: 'Pb. Sérgio Luiz Guimarães',
      board: {
        presidente: 'Eunice Barbosa de Lima',
        vice: 'Mônica Albuquerque',
        sec1: 'Beatriz Silva de Oliveira',
        sec2: 'Cláudia Souza',
        tesoureira: 'Sandra Regina Guimarães',
      },
      membersCount: 84,
    },
    {
      id: 'soc_uph',
      name: 'União Presbiteriana de Homens',
      sigla: 'UPH',
      badge: 'Homens da IPB',
      moto: 'Confiança em Jesus, entusiasmo na ação',
      color: '#15803d',
      icon: '🛡️',
      conselheiro: 'Pb. Antônio Carlos Fagundes',
      board: {
        presidente: 'Geraldo Magela Duarte',
        vice: 'Walter Andrade',
        sec1: 'José Carlos Peixoto',
        sec2: 'Maurício Silveira',
        tesoureira: 'Fernando Meirelles',
      },
      membersCount: 68,
    },
    {
      id: 'soc_ump',
      name: 'União de Mocidade Presbiteriana',
      sigla: 'UMP',
      badge: 'Jovens (18 a 35 anos)',
      moto: 'Alegres na esperança, fortes na fé',
      color: '#0284c7',
      icon: '⚡',
      conselheiro: 'Pb. João Batista Nogueira',
      board: {
        presidente: 'Lucas Tadeu de Oliveira',
        vice: 'Ana Beatriz Ramos',
        sec1: 'Felipe Nogueira Santos',
        sec2: 'Larissa Coutinho',
        tesoureira: 'Thiago Viana',
      },
      membersCount: 52,
    },
    {
      id: 'soc_upa',
      name: 'União Presbiteriana de Adolescentes',
      sigla: 'UPA',
      badge: 'Adolescentes (12 a 17 anos)',
      moto: 'Ao Mestre servindo',
      color: '#ea580c',
      icon: '🔥',
      conselheiro: 'Pb. Eduardo Ribeiro Meirelles',
      board: {
        presidente: 'Beatriz Prado Silva',
        vice: 'Gustavo Dias Albuquerque',
        sec1: 'Carolina Fontes',
        sec2: 'Daniel Lins',
        tesoureira: 'Felipe Nogueira Santos',
      },
      membersCount: 38,
    },
    {
      id: 'soc_ucp',
      name: 'União das Crianças Presbiterianas',
      sigla: 'UCP',
      badge: 'Crianças (até 11 anos)',
      moto: 'Crescendo em sabedoria, estatura e graça',
      color: '#c026d3',
      icon: '🎈',
      conselheiro: 'Rev. Mateus Henrique Prado',
      board: {
        presidente: 'Sara Vasconcelos (Orientadora)',
        vice: 'Débora Cristina Lins',
        sec1: 'Mariana Pontes Fontes',
        sec2: 'Carla Ribeiro',
        tesoureira: 'Rute Albuquerque Mendes',
      },
      membersCount: 45,
    },
  ]);

  // --- OFICIAIS DA IGREJA ---
  oficiais = signal<OficialItem[]>([
    { name: 'Rev. Dr. Carlos Alberto Silveira', role: 'Pastor Titular (Ministro)', organ: 'Conselho da Igreja (Presidente)', mandate: '2021 a 2026', status: 'Ativo', phone: '(11) 98122-3344', bg: '#047857' },
    { name: 'Rev. Mateus Henrique Prado', role: 'Pastor Auxiliar', organ: 'Conselho da Igreja (EBD)', mandate: '2023 a 2028', status: 'Ativo', phone: '(11) 97233-4455', bg: '#065f46' },
    { name: 'Pb. Antônio Carlos Fagundes', role: 'Vice-Presidente do Conselho', organ: 'Conselho da Igreja', mandate: '2022 a 2027', status: 'Ativo', phone: '(11) 99111-2233', bg: '#1e3a8a' },
    { name: 'Pb. Eduardo Ribeiro Meirelles', role: 'Secretário do Conselho', organ: 'Secretaria de Atas & Rol', mandate: '2023 a 2028', status: 'Ativo', phone: '(11) 99222-3344', bg: '#2563eb' },
    { name: 'Pb. Roberto Souza Dias', role: 'Tesoureiro da Igreja', organ: 'Tesouraria do Conselho', mandate: '2021 a 2026', status: 'Ativo', phone: '(11) 99333-4455', bg: '#1d4ed8' },
    { name: 'Pb. João Batista Nogueira', role: 'Presbítero Regente', organ: 'Conselho da Igreja', mandate: '2021 a 2026 (Vencendo)', status: 'Vencendo', phone: '(11) 99444-5566', bg: '#d97706' },
    { name: 'Diác. Marcos Vinícius Oliveira', role: 'Presidente da Junta Diaconal', organ: 'Junta Diaconal', mandate: '2023 a 2028', status: 'Ativo', phone: '(11) 98765-1122', bg: '#b45309' },
    { name: 'Diác. Rafael Siqueira', role: 'Vice-Presidente da Junta', organ: 'Junta Diaconal', mandate: '2023 a 2028', status: 'Ativo', phone: '(11) 98765-6677', bg: '#d97706' },
    { name: 'Diác. André Luiz Castro', role: 'Secretário da Junta Diaconal', organ: 'Junta Diaconal (Atas)', mandate: '2024 a 2029', status: 'Ativo', phone: '(11) 98765-3344', bg: '#92400e' },
    { name: 'Diác. Marcelo Costa Ramos', role: 'Tesoureiro da Junta Diaconal', organ: 'Junta Diaconal (Assistência)', mandate: '2022 a 2027', status: 'Ativo', phone: '(11) 98765-4455', bg: '#78350f' },
  ]);

  // --- PROFESSORES DA EBD ---
  professores = signal<ProfessorItem[]>([
    {
      classe: 'Superintendência da EBD',
      subtitulo: 'Coordenação Geral Pedagógica',
      alunosCount: 140,
      titular: 'Pb. João Batista Nogueira',
      auxiliar: 'Profª. Sara Vasconcelos',
      icon: '🎓',
      color: '#7c3aed',
    },
    {
      classe: 'Classe Bereia (Jovens & Adultos)',
      subtitulo: 'Estudo Expositivo das Epístolas',
      alunosCount: 38,
      titular: 'Pb. Eduardo Ribeiro Meirelles',
      auxiliar: 'Diác. Rafael Siqueira',
      icon: '📖',
      color: '#2563eb',
    },
    {
      classe: 'Classe Timóteo (Adolescentes)',
      subtitulo: 'Vida Cristã e Apologética',
      alunosCount: 22,
      titular: 'Irmão Bruno Mendonça',
      auxiliar: 'Beatriz Silva de Oliveira',
      icon: '🔥',
      color: '#ea580c',
    },
  ]);

  // --- MODAIS ---
  manageTeamDialog = false;
  currentSecretaria: SecretariaItem | null = null;

  novaSecretariaDialog = false;
  novaSecretariaForm = {
    name: '',
    desc: '',
    leader: '',
    leaderPhone: '',
    vice: '',
    icon: '🎛️',
  };

  fichaCadastralDialog = false;
  selectedFichaMember: any = null;

  sociedadeDetailDialog = false;
  selectedSociedade: SociedadeItem | null = null;

  novoOficialDialog = false;
  novoOficialForm = {
    name: '',
    role: 'Presbítero Regente',
    organ: 'Conselho da Igreja',
    mandate: '2024 a 2029',
    phone: '',
  };

  ngOnInit(): void {
    this.carregarMembrosCadastrados();
  }

  carregarMembrosCadastrados(): void {
    this.loading.set(true);
    this.secService.getMembros({}).subscribe({
      next: (res) => {
        if (res.membros.data && res.membros.data.length > 0) {
          this.membrosCadastrados.set(res.membros.data);
        } else {
          this.popularMembrosFallback();
        }
        this.loading.set(false);
      },
      error: () => {
        this.popularMembrosFallback();
        this.loading.set(false);
      },
    });
  }

  private popularMembrosFallback(): void {
    this.membrosCadastrados.set([
      { id: 101, full_name: 'Lucas Tadeu de Oliveira', roll_number: '104', canonical_status: 'comungante', phone: '(11) 98765-1100', email: 'lucas.tadeu@ipb.org.br', marital_status: 'Casado', spouse_name: 'Beatriz Silva de Oliveira', reception_type: 'Profissão de Fé e Batismo', reception_date: '15/03/2018', birth_date: '1995-06-18', cpf: '123.456.789-01' },
      { id: 102, full_name: 'Beatriz Silva de Oliveira', roll_number: '108', canonical_status: 'comungante', phone: '(11) 98765-2200', email: 'beatriz.silva@ipb.org.br', marital_status: 'Casada', spouse_name: 'Lucas Tadeu de Oliveira', reception_type: 'Transferência', reception_date: '10/05/2019', birth_date: '1997-04-22', cpf: '234.567.890-12' },
      { id: 103, full_name: 'Felipe Nogueira Santos', roll_number: '112', canonical_status: 'comungante', phone: '(11) 98765-3300', email: 'felipe.nogueira@ipb.org.br', marital_status: 'Solteiro', reception_type: 'Profissão de Fé', reception_date: '20/11/2020', birth_date: '2002-09-05', cpf: '345.678.901-23' },
      { id: 104, full_name: 'Gustavo Dias Albuquerque', roll_number: '115', canonical_status: 'comungante', phone: '(11) 98765-4400', email: 'gustavo.dias@ipb.org.br', marital_status: 'Solteiro', reception_type: 'Profissão de Fé e Batismo', reception_date: '12/04/2021', birth_date: '2004-11-14', cpf: '456.789.012-34' },
      { id: 105, full_name: 'Mateus Ribeiro Fontes', roll_number: '119', canonical_status: 'comungante', phone: '(11) 98765-5500', email: 'mateus.fontes@ipb.org.br', marital_status: 'Casado', spouse_name: 'Mariana Pontes Fontes', reception_type: 'Profissão de Fé', reception_date: '08/02/2017', birth_date: '1993-08-30', cpf: '567.890.123-45' },
      { id: 106, full_name: 'Mariana Pontes Fontes', roll_number: '120', canonical_status: 'comungante', phone: '(11) 98765-6600', email: 'mariana.pontes@ipb.org.br', marital_status: 'Casada', spouse_name: 'Mateus Ribeiro Fontes', reception_type: 'Profissão de Fé', reception_date: '08/02/2017', birth_date: '1994-01-12', cpf: '678.901.234-56' },
      { id: 107, full_name: 'Rodrigo Alencar Lima', roll_number: '124', canonical_status: 'comungante', phone: '(11) 98765-7700', email: 'rodrigo.alencar@ipb.org.br', marital_status: 'Solteiro', reception_type: 'Transferência', reception_date: '14/06/2019', birth_date: '1991-03-03', cpf: '789.012.345-67' },
      { id: 108, full_name: 'Patrícia Souza Ramos', roll_number: '128', canonical_status: 'comungante', phone: '(11) 98765-8800', email: 'patricia.souza@ipb.org.br', marital_status: 'Casada', spouse_name: 'Diác. Marcelo Ramos', reception_type: 'Profissão de Fé', reception_date: '19/08/2016', birth_date: '1988-07-25', cpf: '890.123.456-78' },
      { id: 109, full_name: 'Samuel Santos Andrade', roll_number: '135', canonical_status: 'comungante', phone: '(11) 98765-9900', email: 'samuel.santos@ipb.org.br', marital_status: 'Casado', reception_type: 'Profissão de Fé e Batismo', reception_date: '22/09/2015', birth_date: '1990-12-17', cpf: '901.234.567-89' },
      { id: 110, full_name: 'Diác. Rafael Siqueira', roll_number: '088', canonical_status: 'comungante', phone: '(11) 98765-6677', email: 'rafael.siqueira@ipb.org.br', marital_status: 'Casado', reception_type: 'Profissão de Fé e Batismo', reception_date: '10/03/2012', birth_date: '1985-10-08', cpf: '012.345.678-90' },
    ]);
  }

  // --- FILTRO DE BUSCA AUTOMÁTICA DE MEMBROS ---
  filteredMembers = computed(() => {
    const q = this.searchMemberQuery.trim().toLowerCase();
    if (!q) return this.membrosCadastrados();
    return this.membrosCadastrados().filter(
      (m) =>
        m.full_name.toLowerCase().includes(q) ||
        (m.roll_number && m.roll_number.includes(q)) ||
        (m.cpf && m.cpf.includes(q))
    );
  });

  // --- MODAL GERENCIAR EQUIPE ---
  openManageTeam(sec: SecretariaItem): void {
    this.currentSecretaria = sec;
    this.searchMemberQuery = '';
    this.selectedMember = null;
    this.memberRole = '';
    this.memberPhone = '';
    this.manageTeamDialog = true;
  }

  selectMemberForTeam(m: MembroRol): void {
    this.selectedMember = m;
    this.searchMemberQuery = `${m.full_name} (ROL nº ${m.roll_number || 'S/N'})`;
    this.memberPhone = m.phone || '';
  }

  addMemberToTeam(): void {
    if (!this.currentSecretaria) return;

    const name = this.selectedMember ? this.selectedMember.full_name : this.searchMemberQuery.split('(')[0].trim();
    if (!name) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Busque e selecione um membro do cadastro.' });
      return;
    }

    if (!this.memberRole.trim()) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Informe a função ou atribuição na equipe.' });
      return;
    }

    this.currentSecretaria.team.push({
      name: name,
      role: this.memberRole.trim(),
      phone: this.memberPhone.trim() || undefined,
      memberId: this.selectedMember?.id,
    });

    this.msg.add({
      severity: 'success',
      summary: 'Adicionado com Sucesso',
      detail: `${name} foi incluído(a) na equipe da ${this.currentSecretaria.name}!`,
    });

    // Limpa campos para nova adição
    this.searchMemberQuery = '';
    this.selectedMember = null;
    this.memberRole = '';
    this.memberPhone = '';
  }

  removeMemberFromTeam(index: number): void {
    if (!this.currentSecretaria) return;
    const removed = this.currentSecretaria.team.splice(index, 1)[0];
    this.msg.add({
      severity: 'info',
      summary: 'Removido',
      detail: `${removed.name} foi removido(a) da equipe.`,
    });
  }

  // --- NOVA SECRETARIA ---
  openNovaSecretaria(): void {
    this.novaSecretariaForm = {
      name: '',
      desc: '',
      leader: '',
      leaderPhone: '',
      vice: '',
      icon: '🎛️',
    };
    this.novaSecretariaDialog = true;
  }

  salvarNovaSecretaria(): void {
    if (!this.novaSecretariaForm.name.trim() || !this.novaSecretariaForm.leader.trim()) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Informe o nome da secretaria e o líder titular.' });
      return;
    }

    const newSec: SecretariaItem = {
      id: 'sec_' + Date.now(),
      name: this.novaSecretariaForm.name.trim(),
      desc: this.novaSecretariaForm.desc.trim() || 'Secretaria e ministério de atuação da Igreja local.',
      leader: this.novaSecretariaForm.leader.trim(),
      leaderPhone: this.novaSecretariaForm.leaderPhone.trim() || '(11) 98888-0000',
      vice: this.novaSecretariaForm.vice.trim() || undefined,
      icon: this.novaSecretariaForm.icon || '📂',
      team: [],
    };

    this.secretarias.update((list) => [newSec, ...list]);
    this.novaSecretariaDialog = false;
    this.msg.add({
      severity: 'success',
      summary: 'Secretaria Criada',
      detail: `Secretaria "${newSec.name}" criada com sucesso!`,
    });
  }

  // --- FICHA CADASTRAL / DOSSIÊ DO MEMBRO ---
  openFichaCadastral(memberOrName: any): void {
    if (typeof memberOrName === 'string') {
      const found = this.membrosCadastrados().find(
        (m) => m.full_name.toLowerCase().includes(memberOrName.toLowerCase()) || memberOrName.toLowerCase().includes(m.full_name.toLowerCase())
      );
      if (found) {
        this.selectedFichaMember = found;
      } else {
        this.selectedFichaMember = {
          id: 0,
          full_name: memberOrName,
          roll_number: '088',
          canonical_status: 'comungante',
          phone: '(11) 98765-4321',
          email: 'membro@ipb.org.br',
          reception_type: 'Profissão de Fé e Batismo',
          reception_date: '10/03/2012',
          marital_status: 'Casado',
        };
      }
    } else {
      this.selectedFichaMember = memberOrName;
    }

    this.fichaCadastralDialog = true;
  }

  // CALCULA TODOS OS CARGOS E EQUIPES DO MEMBRO (SINCRONIZADO)
  getMemberRoles(name: string): any[] {
    const roles: any[] = [];
    const clean = name.toLowerCase().trim();

    // 1. Secretarias
    this.secretarias().forEach((s) => {
      if (s.leader.toLowerCase().includes(clean) || clean.includes(s.leader.toLowerCase())) {
        roles.push({
          tipo: 'LIDERANÇA DE SECRETARIA',
          orgao: s.name,
          funcao: 'Secretário(a) / Líder Titular',
          icone: s.icon,
        });
      }
      if (s.vice && (s.vice.toLowerCase().includes(clean) || clean.includes(s.vice.toLowerCase()))) {
        roles.push({
          tipo: 'VICE-LIDERANÇA',
          orgao: s.name,
          funcao: 'Vice-Líder / Co-Responsável',
          icone: s.icon,
        });
      }
      s.team.forEach((t) => {
        if (t.name.toLowerCase().includes(clean) || clean.includes(t.name.toLowerCase())) {
          roles.push({
            tipo: 'EQUIPE DE MINISTÉRIO',
            orgao: s.name,
            funcao: t.role,
            icone: s.icon,
          });
        }
      });
    });

    // 2. Sociedades
    this.sociedades().forEach((soc) => {
      for (const [cargo, pessoa] of Object.entries(soc.board)) {
        if (pessoa.toLowerCase().includes(clean) || clean.includes(pessoa.toLowerCase())) {
          const cargoLabels: Record<string, string> = {
            presidente: 'Presidente',
            vice: 'Vice-Presidente',
            sec1: '1ª Secretária(o)',
            sec2: '2ª Secretária(o)',
            tesoureira: 'Tesoureira(o)',
          };
          roles.push({
            tipo: 'DIRETORIA DE SOCIEDADE',
            orgao: `${soc.name} (${soc.sigla})`,
            funcao: cargoLabels[cargo] || cargo,
            icone: soc.icon,
          });
        }
      }
    });

    // 3. Oficiais
    this.oficiais().forEach((o) => {
      if (o.name.toLowerCase().includes(clean) || clean.includes(o.name.toLowerCase())) {
        roles.push({
          tipo: 'OFICIALATO DA IGREJA',
          orgao: o.organ,
          funcao: `${o.role} (${o.mandate})`,
          icone: '⛪',
        });
      }
    });

    return roles;
  }

  // Emissão de PDF oficial da Ficha Cadastral do Membro/Oficial
  imprimirFicha(): void {
    const nome = this.selectedFichaMember?.full_name
      ? this.selectedFichaMember.full_name.trim().toLowerCase().replace(/\s+/g, '-')
      : 'membro-oficial';
    this.pdfSvc.gerarPdfEmNovaAba(
      'fichaCadastralSheet',
      `ficha-cadastral-${nome}`,
      `Ficha Cadastral Oficial — ${this.selectedFichaMember?.full_name || 'IPB'}`
    );
  }

  // --- DETALHES DE SOCIEDADE ---
  openSociedadeDetail(soc: SociedadeItem): void {
    this.selectedSociedade = soc;
    this.sociedadeDetailDialog = true;
  }

  // --- NOVO OFICIAL ---
  openNovoOficial(): void {
    this.novoOficialForm = {
      name: '',
      role: 'Presbítero Regente',
      organ: 'Conselho da Igreja',
      mandate: '2024 a 2029',
      phone: '',
    };
    this.novoOficialDialog = true;
  }

  salvarNovoOficial(): void {
    if (!this.novoOficialForm.name.trim()) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Informe o nome do oficial.' });
      return;
    }

    const newOf: OficialItem = {
      name: this.novoOficialForm.name.trim(),
      role: this.novoOficialForm.role,
      organ: this.novoOficialForm.organ,
      mandate: this.novoOficialForm.mandate,
      status: 'Ativo',
      phone: this.novoOficialForm.phone || '(11) 98765-4321',
      bg: this.novoOficialForm.role.includes('Pastor') ? '#047857' : (this.novoOficialForm.role.includes('Presbítero') ? '#1e3a8a' : '#b45309'),
    };

    this.oficiais.update((list) => [newOf, ...list]);
    this.novoOficialDialog = false;
    this.msg.add({
      severity: 'success',
      summary: 'Oficial Registrado',
      detail: `${newOf.name} foi registrado como ${newOf.role}!`,
    });
  }

  openWhatsApp(name: string, phone: string): void {
    const clean = phone.replace(/\D/g, '');
    const text = encodeURIComponent(`A paz do Senhor, irmão(ã) ${name}! Entro em contato a respeito das atividades da nossa Igreja Presbiteriana.`);
    window.open(`https://wa.me/55${clean}?text=${text}`, '_blank');
  }
}
