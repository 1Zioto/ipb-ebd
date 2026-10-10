import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { ToastModule } from 'primeng/toast';
import { TooltipModule } from 'primeng/tooltip';
import { DialogModule } from 'primeng/dialog';
import { MessageService } from 'primeng/api';
import { PdfService } from '../../../core/pdf.service';

export interface MotivoOracao {
  id: string;
  nome: string;
  motivo: string;
}

export interface EscalaItem {
  faixa: string;
  responsaveis: string;
}

export interface AvisoItem {
  id: string;
  titulo: string;
  descricao: string;
  imagemUrl?: string;
  tema?: string;
  preletor?: string;
  data?: string;
  local?: string;
  valor?: string;
}

export interface AniversarianteItem {
  dia: string;
  nomes: string;
}

export interface BoletimModel {
  id: string;
  edicaoNumero: string;
  dataDomingo: string;
  dataExtenso: string;
  igrejaNome: string;
  igrejaSubtitulo: string;
  pastoresContatos: string;
  agendaPastorTexto: string;

  // Devocional
  devocionalTitulo: string;
  devocionalReferencia: string;
  devocionalTexto: string;

  // Oração
  oracaoSubtitulo: string;
  motivosOracao: MotivoOracao[];
  pedidosOracaoOrientacao: string;

  // Escala Infantil
  escalaEbd: EscalaItem[];
  escalaCultoInfantil: EscalaItem[];

  // Plantação
  congregaAtiva: boolean;
  congregaLocal: string;
  congregaEndereco: string;
  congregaHorarios: string;
  congregaPastor: string;
  congregaPresbitero: string;

  // Dízimos e Ofertas
  dizimosTextoAbertura: string;
  dizimosBanco: string;
  dizimosAgencia: string;
  dizimosConta: string;
  dizimosCnpj: string;
  dizimosTelefones: string;
  dizimosPix: string;

  // Avisos
  avisos: AvisoItem[];

  // Liturgia e Aniversariantes
  aniversariantes: AniversarianteItem[];
  liturgiaManha: string;
  liturgiaNoite: string;
}

const BOLETIM_EXEMPLO_PADRAO: BoletimModel = {
  id: 'ipjao-exemplo-domingo',
  edicaoNumero: 'Edição Especial',
  dataDomingo: '2026-10-11',
  dataExtenso: '11 de Outubro de 2026',
  igrejaNome: 'IGREJA PRESBITERIANA JAÓ',
  igrejaSubtitulo: 'Uma Igreja Bíblica, Acolhedora e Missionária',
  pastoresContatos: '3945-7071 / 3945-7281',
  agendaPastorTexto:
    'Se você deseja conversar com os pastores, fale com a secretária para marcar um horário pelos telefones: 3945-7071/3945-7281.',

  devocionalTitulo: 'TU E TUA CASA – Devocionais para o Lar',
  devocionalReferencia: '2Cr. 7:14',
  devocionalTexto:
    'Leitura do texto bíblico e da reflexão – 2Cr. 7:14\n' +
    'Orar com fé não significa determinar a Deus que as coisas aconteçam como se nossa oração tivesse um poder próprio para que as coisas acontecessem. Nada do que pedimos tem valor se for fora da vontade de Deus. É Deus quem responde com graça e soberania ao clamor sincero e obediente do seu povo. Ele se inclina aos nossos pedidos para respondê-las, e isto de acordo com sua vontade boa, perfeita e agradável. Se houvesse uma busca verdadeira a Deus por parte dos que professam crer em Seu Santo Nome, desfrutaríamos de muito mais bênçãos e veríamos aquele avivamento genuíno transformar as famílias e a nossa pátria. Sugerimos que as famílias aproveitem estes momentos edificantes na Igreja Presbiteriana Jaó.',

  oracaoSubtitulo: 'Oremos pelos nossos irmãos:',
  motivosOracao: [
    { id: '1', nome: 'Cláudia (tia da Marcela Machado)', motivo: 'Tratamento de Câncer' },
    { id: '2', nome: 'Bruno', motivo: 'Filho da Marla, amiga do Célio' },
    { id: '3', nome: 'Sr. Valdacir', motivo: 'Pai do Paulo Henrique' },
  ],
  pedidosOracaoOrientacao:
    'Interessados em colocar pedidos de oração no boletim, por favor, procurem o Pr. Gil ou a secretária Marcela Machado.',

  escalaEbd: [
    { faixa: '02 a 07 anos', responsaveis: 'Rayliane, Eloíza e Diliany' },
    { faixa: '08 a 12 anos', responsaveis: 'Deise e Pb. Álvaro' },
  ],
  escalaCultoInfantil: [
    { faixa: 'Berçário', responsaveis: 'Não terá' },
    { faixa: '02 e 03 anos', responsaveis: 'Iara e Jéssica' },
    { faixa: '04 a 06 anos', responsaveis: 'Gabrielle' },
    { faixa: '07 a 09 anos', responsaveis: 'Diliany' },
    { faixa: '10 a 12 anos', responsaveis: 'Templo' },
  ],

  congregaAtiva: true,
  congregaLocal: 'Alphaville',
  congregaEndereco: 'AlphaPark Hotel - Av. Alphaville Flamboyant, Qd. 5, nº 200, Park Lozandes.',
  congregaHorarios: 'Culto – Domingo: 19h e Grupos familiares – Quinta-feira: 20h',
  congregaPastor: 'Rev. Gustavo Ribeiro',
  congregaPresbitero: 'Presb. Ronaldo Guedes',

  dizimosTextoAbertura:
    'Para os membros da igreja ou visitantes que desejarem realizar suas ofertas ou dar seus dízimos por meio de operação bancária, segue dados abaixo:',
  dizimosBanco: '341 - ITAÚ',
  dizimosAgencia: '4384',
  dizimosConta: '39.456-7',
  dizimosCnpj: '11.118.427/0001-05',
  dizimosTelefones: '3945-7071 ou 3945-7281',
  dizimosPix: '11.118.427/0001-05 (CNPJ)',

  avisos: [
    {
      id: 'aviso-1',
      titulo: 'VIGÍLIA IPJAÓ',
      descricao:
        'A Equipe do Life on Life convida toda a igreja para participar da Vigília de Oração, no próximo dia 28 de abril, das 22h às 00h, aqui na igreja. Venha, participe e traga sua família!',
      data: '28 de abril, das 22h às 00h',
      local: 'Templo da Igreja Presbiteriana Jaó',
    },
    {
      id: 'aviso-2',
      titulo: 'ENCONTRO DE CASAIS ALPHAVILLE',
      descricao:
        'Invista em seu casamento! Comunicação - Resolvendo conflitos no casamento. Uma noite abençoada para fortalecer os laços conjugais à luz da Palavra de Deus.',
      imagemUrl: 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=600&q=80',
      tema: 'Comunicação (Resolvendo conflitos no casamento)',
      preletor: 'Rev. Saulo Carvalho',
      data: '27 de abril',
      local: 'Salão de Festas do Edifício Maison Royale',
      valor: 'R$ 30,00 // Para casados, noivos e namorados!',
    },
    {
      id: 'aviso-3',
      titulo: 'SEMINÁRIO EBD - OS YOUTUBERS',
      descricao:
        'No dia 07/5 haverá um seminário na Escola Bíblica Dominical da IPJaó que abordará um tema muito conhecido por nossos filhos: Os Youtubers. Quem são? O que essas pessoas estão falando na internet? O preletor será o Presbítero Beto da Igreja Presbiteriana do Setor Bueno. Participe!',
      preletor: 'Presbítero Beto (IPB Setor Bueno)',
      data: '07 de maio durante a EBD',
      local: 'Templo Principal',
    },
  ],

  aniversariantes: [
    { dia: 'Segunda-feira', nomes: 'Ana Clara, Carlos Eduardo' },
    { dia: 'Quarta-feira', nomes: 'Pb. Ronaldo Guedes' },
    { dia: 'Sexta-feira', nomes: 'Marcela Machado, Lucas Oliveira' },
    { dia: 'Domingo', nomes: 'Rev. Gilberto Silveira' },
  ],
  liturgiaManha:
    'Prelúdio Instrumental | Oração de Invocação | Hino Congregacional | Leitura Bíblica Alternada | Oração Pastoral | Louvor com a Congregação | Ofertório & Dízimos | Proclamação da Palavra | Oração Final e Bênção Apostólica',
  liturgiaNoite:
    'Prelúdio | Leitura Bíblica de Abertura | Cânticos de Adoração | Oração de Intercessão | Mensagem Musical | Ministração da Palavra de Deus | Apelo e Oração | Bênção e Poslúdio',
};

const STORAGE_KEY_ATUAL = 'ipb_boletim_elaboracao_atual';
const STORAGE_KEY_HISTORICO = 'ipb_boletim_historico_edicoes';

@Component({
  selector: 'app-boletim-elaborador',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    InputTextModule,
    ToastModule,
    TooltipModule,
    DialogModule,
  ],
  providers: [MessageService],
  templateUrl: './boletim-elaborador.html',
  styleUrls: ['./boletim-elaborador.css'],
})
export class BoletimElaboradorPage implements OnInit {
  private msg = inject(MessageService);
  private pdfSvc = inject(PdfService);

  // Estado Reativo Principal
  boletim = signal<BoletimModel>(JSON.parse(JSON.stringify(BOLETIM_EXEMPLO_PADRAO)));
  historicoEdicoes = signal<{ id: string; titulo: string; data: string; boletim: BoletimModel }[]>([]);

  // Abas de Edição no Painel
  activeTab = signal<'geral' | 'devocional' | 'oracao' | 'escalas' | 'congrega' | 'dizimos' | 'avisos' | 'liturgia'>('geral');
  
  // Modo de Exibição do Preview:
  // 'avisos_escalas' (Página idêntica à foto enviada), 'capa_liturgia' ou 'completo' (2 páginas)
  modoPreview = signal<'avisos_escalas' | 'capa_liturgia' | 'completo'>('avisos_escalas');

  // Modais
  dialogHistorico = false;
  dialogExportarWhatsapp = false;
  dialogNovoAviso = false;
  dialogConfigCores = false;

  textoWhatsappGerado = '';

  // Edição de Avisos
  avisoEmEdicao: AvisoItem = {
    id: '',
    titulo: '',
    descricao: '',
    imagemUrl: '',
    tema: '',
    preletor: '',
    data: '',
    local: '',
    valor: '',
  };

  // Cores personalizáveis para identidade da igreja
  corPrimaria = '#0d532b'; // Verde IPB escuro
  corSecundaria = '#43a047'; // Verde destaque
  corDestaqueBox = '#dcedc8'; // Fundo suave dízimos

  ngOnInit(): void {
    this.carregarDoLocalStorage();
    this.carregarHistorico();
  }

  // ---- PERSISTÊNCIA LOCAL ----
  carregarDoLocalStorage(): void {
    try {
      const salvo = localStorage.getItem(STORAGE_KEY_ATUAL);
      if (salvo) {
        const dados = JSON.parse(salvo);
        this.boletim.set(dados);
      }
    } catch (e) {
      console.warn('Erro ao carregar rascunho de boletim:', e);
    }
  }

  salvarRascunho(notificar = true): void {
    try {
      localStorage.setItem(STORAGE_KEY_ATUAL, JSON.stringify(this.boletim()));
      if (notificar) {
        this.msg.add({
          severity: 'success',
          summary: 'Rascunho Salvo!',
          detail: 'As alterações do boletim foram salvas localmente no navegador.',
        });
      }
    } catch (e) {
      this.msg.add({
        severity: 'error',
        summary: 'Erro ao salvar',
        detail: 'Não foi possível salvar os dados no navegador.',
      });
    }
  }

  restaurarModeloIPJao(): void {
    if (confirm('Deseja recarregar o modelo original da Igreja Presbiteriana Jaó (conforme a imagem)?')) {
      const copia = JSON.parse(JSON.stringify(BOLETIM_EXEMPLO_PADRAO));
      this.boletim.set(copia);
      this.salvarRascunho(false);
      this.msg.add({
        severity: 'info',
        summary: 'Modelo Carregado',
        detail: 'O modelo padrão do boletim da IPJaó foi restaurado com sucesso!',
      });
    }
  }

  salvarNoHistorico(): void {
    const atual = this.boletim();
    const titulo = `${atual.igrejaNome} - ${atual.dataExtenso} (${atual.edicaoNumero})`;
    const novaEdicao = {
      id: 'edicao-' + Date.now(),
      titulo,
      data: new Date().toLocaleDateString('pt-BR'),
      boletim: JSON.parse(JSON.stringify(atual)),
    };

    const lista = [novaEdicao, ...this.historicoEdicoes().filter((h) => h.id !== novaEdicao.id)].slice(0, 20);
    this.historicoEdicoes.set(lista);
    localStorage.setItem(STORAGE_KEY_HISTORICO, JSON.stringify(lista));
    this.salvarRascunho(false);

    this.msg.add({
      severity: 'success',
      summary: 'Edição Arquivada',
      detail: `Boletim "${titulo}" arquivado no histórico de edições com sucesso!`,
    });
  }

  carregarHistorico(): void {
    try {
      const salvo = localStorage.getItem(STORAGE_KEY_HISTORICO);
      if (salvo) {
        this.historicoEdicoes.set(JSON.parse(salvo));
      }
    } catch (e) {
      console.warn('Erro ao carregar histórico:', e);
    }
  }

  carregarEdicaoDoHistorico(item: { boletim: BoletimModel }): void {
    this.boletim.set(JSON.parse(JSON.stringify(item.boletim)));
    this.salvarRascunho(false);
    this.dialogHistorico = false;
    this.msg.add({
      severity: 'info',
      summary: 'Edição Carregada',
      detail: 'O boletim selecionado foi carregado no editor.',
    });
  }

  excluirDoHistorico(id: string, event: Event): void {
    event.stopPropagation();
    const lista = this.historicoEdicoes().filter((h) => h.id !== id);
    this.historicoEdicoes.set(lista);
    localStorage.setItem(STORAGE_KEY_HISTORICO, JSON.stringify(lista));
  }

  // ---- GESTÃO DE MOTIVOS DE ORAÇÃO ----
  adicionarMotivoOracao(): void {
    const b = this.boletim();
    const novo: MotivoOracao = {
      id: 'motivo-' + Date.now(),
      nome: 'Novo Nome',
      motivo: 'Motivo de oração / Intercessão',
    };
    b.motivosOracao.push(novo);
    this.boletim.set({ ...b });
    this.salvarRascunho(false);
  }

  removerMotivoOracao(index: number): void {
    const b = this.boletim();
    b.motivosOracao.splice(index, 1);
    this.boletim.set({ ...b });
    this.salvarRascunho(false);
  }

  // ---- GESTÃO DE ESCALAS INFANTIS ----
  adicionarEscalaEbd(): void {
    const b = this.boletim();
    b.escalaEbd.push({ faixa: 'Nova Faixa', responsaveis: 'Professores' });
    this.boletim.set({ ...b });
    this.salvarRascunho(false);
  }

  removerEscalaEbd(index: number): void {
    const b = this.boletim();
    b.escalaEbd.splice(index, 1);
    this.boletim.set({ ...b });
    this.salvarRascunho(false);
  }

  adicionarEscalaCulto(): void {
    const b = this.boletim();
    b.escalaCultoInfantil.push({ faixa: 'Nova Faixa', responsaveis: 'Voluntários' });
    this.boletim.set({ ...b });
    this.salvarRascunho(false);
  }

  removerEscalaCulto(index: number): void {
    const b = this.boletim();
    b.escalaCultoInfantil.splice(index, 1);
    this.boletim.set({ ...b });
    this.salvarRascunho(false);
  }

  // ---- GESTÃO DE AVISOS DIVERSOS ----
  abrirModalNovoAviso(): void {
    this.avisoEmEdicao = {
      id: 'aviso-' + Date.now(),
      titulo: 'NOVO EVENTO / AVISO',
      descricao: 'Descrição dos detalhes do evento ou comunicado.',
      imagemUrl: '',
      tema: '',
      preletor: '',
      data: '',
      local: '',
      valor: '',
    };
    this.dialogNovoAviso = true;
  }

  editarAviso(aviso: AvisoItem): void {
    this.avisoEmEdicao = JSON.parse(JSON.stringify(aviso));
    this.dialogNovoAviso = true;
  }

  salvarAvisoModal(): void {
    const b = this.boletim();
    const idx = b.avisos.findIndex((a) => a.id === this.avisoEmEdicao.id);
    if (idx >= 0) {
      b.avisos[idx] = { ...this.avisoEmEdicao };
    } else {
      b.avisos.push({ ...this.avisoEmEdicao });
    }
    this.boletim.set({ ...b });
    this.salvarRascunho(false);
    this.dialogNovoAviso = false;
    this.msg.add({
      severity: 'success',
      summary: 'Aviso Salvo',
      detail: 'O aviso foi atualizado no boletim.',
    });
  }

  removerAviso(index: number): void {
    const b = this.boletim();
    b.avisos.splice(index, 1);
    this.boletim.set({ ...b });
    this.salvarRascunho(false);
  }

  // ---- ANIVERSARIANTES ----
  adicionarAniversariante(): void {
    const b = this.boletim();
    b.aniversariantes.push({ dia: 'Novo Dia', nomes: 'Nome dos aniversariantes' });
    this.boletim.set({ ...b });
    this.salvarRascunho(false);
  }

  removerAniversariante(index: number): void {
    const b = this.boletim();
    b.aniversariantes.splice(index, 1);
    this.boletim.set({ ...b });
    this.salvarRascunho(false);
  }

  // ---- IMPRESSÃO E PDF ----
  imprimirOuExportarPdf(): void {
    // 1. Otimiza a visualização e abre a impressão nativa de alta fidelidade
    const elem = document.getElementById('boletim-folha-impressao');
    if (!elem) {
      this.msg.add({
        severity: 'error',
        summary: 'Erro na Impressão',
        detail: 'Não foi possível localizar o container de impressão do boletim.',
      });
      return;
    }

    const b = this.boletim();
    const nomeArquivo = `boletim-ipb-${b.dataDomingo || 'domingo'}`;
    const titulo = `Boletim Informativo Semanal — ${b.igrejaNome} (${b.dataExtenso})`;

    // Dispara via PdfService oficial
    this.pdfSvc.gerarPdfEmNovaAba(elem, nomeArquivo, titulo);
  }

  // ---- GERADOR DE WHATSAPP ----
  abrirGeradorWhatsapp(): void {
    const b = this.boletim();
    let txt = `📰 *BOLETIM INFORMATIVO SEMANAL — ${b.igrejaNome.toUpperCase()}*\n`;
    txt += `📅 *${b.dataExtenso}* | *${b.edicaoNumero}*\n`;
    txt += `━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n`;

    if (b.devocionalTexto) {
      txt += `📖 *PALAVRA DEVOCIONAL — ${b.devocionalReferencia}*\n`;
      txt += `${b.devocionalTexto.trim()}\n\n`;
      txt += `━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n`;
    }

    txt += `🙏 *IGREJA EM ORAÇÃO*\n`;
    txt += `${b.oracaoSubtitulo}\n`;
    b.motivosOracao.forEach((m) => {
      txt += `• *${m.nome}*${m.motivo ? ' – ' + m.motivo : ''}\n`;
    });
    txt += `\n_${b.pedidosOracaoOrientacao}_\n\n`;
    txt += `━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n`;

    txt += `👶 *ESCALA INFANTIL DESTE DOMINGO*\n`;
    txt += `*Escola Bíblica Dominical:*\n`;
    b.escalaEbd.forEach((e) => {
      txt += `• ${e.faixa}: ${e.responsaveis}\n`;
    });
    txt += `\n*Culto Infantil:*\n`;
    b.escalaCultoInfantil.forEach((c) => {
      txt += `• ${c.faixa}: ${c.responsaveis}\n`;
    });
    txt += `\n━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n`;

    if (b.avisos && b.avisos.length > 0) {
      txt += `📢 *AVISOS & EVENTOS DA SEMANA*\n\n`;
      b.avisos.forEach((a) => {
        txt += `✨ *${a.titulo}*\n`;
        txt += `${a.descricao}\n`;
        if (a.data) txt += `🗓️ *Data:* ${a.data}\n`;
        if (a.preletor) txt += `🎤 *Preletor:* ${a.preletor}\n`;
        if (a.local) txt += `📍 *Local:* ${a.local}\n`;
        if (a.valor) txt += `🏷️ *Valor:* ${a.valor}\n`;
        txt += `\n`;
      });
      txt += `━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n`;
    }

    if (b.congregaAtiva) {
      txt += `🌱 *PLANTAÇÃO DE IGREJA / CONGREGAÇÃO*\n`;
      txt += `*Local:* ${b.congregaLocal}\n`;
      txt += `*Endereço:* ${b.congregaEndereco}\n`;
      txt += `*Horários:* ${b.congregaHorarios}\n`;
      txt += `*Pastor:* ${b.congregaPastor} | *Presbítero:* ${b.congregaPresbitero}\n\n`;
      txt += `━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n`;
    }

    txt += `💳 *DÍZIMOS E OFERTAS*\n`;
    txt += `${b.dizimosTextoAbertura}\n`;
    txt += `*Banco:* ${b.dizimosBanco}\n`;
    txt += `*Agência:* ${b.dizimosAgencia} | *Conta:* ${b.dizimosConta}\n`;
    txt += `*CNPJ:* ${b.dizimosCnpj}\n`;
    if (b.dizimosPix) txt += `*Chave PIX:* ${b.dizimosPix}\n`;
    txt += `*Telefone Secretaria:* ${b.dizimosTelefones}\n\n`;
    txt += `_Deus abençoe sua semana e sua família!_ 🙌✨`;

    this.textoWhatsappGerado = txt;
    this.dialogExportarWhatsapp = true;
  }

  copiarTextoWhatsapp(): void {
    navigator.clipboard.writeText(this.textoWhatsappGerado).then(() => {
      this.msg.add({
        severity: 'success',
        summary: 'Copiado!',
        detail: 'Texto formatado para WhatsApp copiado para a área de transferência.',
      });
    });
  }

  // Backup / Exportação JSON
  exportarJson(): void {
    const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(this.boletim(), null, 2));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute('href', dataStr);
    downloadAnchor.setAttribute('download', `boletim_${this.boletim().dataDomingo || 'edicao'}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  }

  importarJson(event: any): void {
    const file = event.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e: any) => {
        try {
          const importado = JSON.parse(e.target.result);
          this.boletim.set(importado);
          this.salvarRascunho(false);
          this.msg.add({
            severity: 'success',
            summary: 'Importado com Sucesso',
            detail: 'O arquivo JSON do boletim foi carregado no editor.',
          });
        } catch (err) {
          this.msg.add({
            severity: 'error',
            summary: 'Erro no Arquivo',
            detail: 'O arquivo selecionado não é um JSON válido de boletim.',
          });
        }
      };
      reader.readAsText(file);
    }
  }
}
