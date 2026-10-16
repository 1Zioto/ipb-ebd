import { Injectable, signal } from '@angular/core';

export interface ChurchLetterheadConfig {
  churchName: string;
  presbytery: string;
  synod: string;
  cnpj: string;
  address: string;
  cityState: string;
  phone: string;
  email: string;
  pastorName: string;
  pastorRegistration: string;
  secretaryName: string;
  footerVerse: string;
}

export type DocumentTypeKey =
  | 'apresentacao'
  | 'apresentacao_crianca'
  | 'atestado_membresia'
  | 'carta_disciplina'
  | 'certificado_batismo'
  | 'certificado_casamento'
  | 'exclusao'
  | 'nomeacao_cargo'
  | 'recomendacao'
  | 'transferencia';

export interface DocumentModelItem {
  key: DocumentTypeKey;
  title: string;
  subtitle: string;
  category: 'Cartas' | 'Certificados' | 'Termos & Atos';
  badge: string;
  defaultTemplate: string;
}

export interface IssuedDocumentRecord {
  id: string;
  code: string;
  typeKey: DocumentTypeKey;
  typeTitle: string;
  recipientName: string;
  rollNumber?: string;
  issueDate: string;
  churchDestination?: string;
  details: string;
}

const DEFAULT_CONFIG: ChurchLetterheadConfig = {
  churchName: 'Igreja Presbiteriana de Campo Verde',
  presbytery: 'Presbitério de Cariacica (PCAR)',
  synod: 'Sínodo Central Espiritossantense (SCE)',
  cnpj: '31.849.204/0001-82',
  address: 'Rua das Palmeiras, 150 - Campo Verde',
  cityState: 'Cariacica - ES',
  phone: '(27) 3388-1234',
  email: 'secretaria@ipb-campoverde.org.br',
  pastorName: 'Rev. Marcos Aurélio de Souza',
  pastorRegistration: 'Reg. Presbiterial nº 142/PCAR',
  secretaryName: 'Pb. Roberto Guimarães Filho',
  footerVerse: '"Mas faça-se tudo decentemente e com ordem." — 1 Coríntios 14:40',
};

const DOCUMENT_MODELS: DocumentModelItem[] = [
  {
    key: 'apresentacao',
    title: 'Apresentação',
    subtitle: 'Carta oficial de apresentação de membro em trânsito ou viagem',
    category: 'Cartas',
    badge: 'Comunhão',
    defaultTemplate: `À amada Igreja-Irmã,

Graça e paz da parte de nosso Senhor e Salvador Jesus Cristo.

Pela presente, temos a honra e satisfação de apresentar-lhes o(a) irmão(ã) {NOME_MEMBRO}, portador(a) do Rol de Membros nº {ROL_MEMBRO}, membro comungante em plena comunhão com esta Igreja Presbiteriana e no pleno gozo de seus direitos eclesiásticos.

O(A) referido(a) irmão(ã) estará em trânsito temporário nessa localidade por motivo de {MOTIVO_TRANSITO}, durante o período aproximado de {PERIODO_TRANSITO}. Solicitamos aos prezados irmãos que o(a) acolham fraternalmente em Cristo Jesus, franqueando-lhe a comunhão da Mesa do Senhor e a participação nos santos trabalhos dessa amada grei.

Na certeza do acolhimento cristão, subscrevemo-nos em Cristo fraternalmente,`,
  },
  {
    key: 'apresentacao_crianca',
    title: 'Apresentação de Criança',
    subtitle: 'Certificado de consagração e apresentação da criança ao Senhor',
    category: 'Certificados',
    badge: 'Consagração',
    defaultTemplate: `Certificamos que a criança {NOME_CRIANCA}, nascida no dia {DATA_NASCIMENTO}, filha de {NOME_PAI} e de {NOME_MAE}, foi solenemente apresentada e consagrada a Deus perante esta comunidade de fé, sob oração de bênção sacerdotal, conforme o ensino das Sagradas Escrituras:

"Deixai vir a mim os pequeninos e não os embaraceis, porque dos tais é o Reino de Deus." — Marcos 10:14

Que o Senhor Todo-Poderoso conceda sabedoria aos pais para criá-la na disciplina e admoestação do Senhor Jesus, guardando seus passos em santidade e retidão.`,
  },
  {
    key: 'atestado_membresia',
    title: 'Atestado de Membresia',
    subtitle: 'Declaração formal de arrolamento e regularidade eclesiástica',
    category: 'Termos & Atos',
    badge: 'Fé Pública',
    defaultTemplate: `O Conselho da {NOME_IGREJA}, federada à Igreja Presbiteriana do Brasil, jurisdicionada ao {NOME_PRESBITERIO}, ATESTA para os devidos fins a quem possa interessar que:

O(A) senhor(a) {NOME_MEMBRO}, inscrito(a) no Rol de Membros desta Igreja sob o nº {ROL_MEMBRO}, é membro comungante devidamente arrolado(a) e ativo(a) nesta comunidade de fé, achando-se em plena comunhão, participando regularmente das atividades eclesiásticas e desfrutando de todos os privilégios inerentes à membresia, sem que contra ele(a) conste qualquer impedimento ou procedimento disciplinar.

Por ser a expressão da verdade e a pedido do(a) interessado(a) para fins de {FINALIDADE_ATESTADO}, firmamos o presente atestado com o selo e chancela oficial desta Igreja.`,
  },
  {
    key: 'carta_disciplina',
    title: 'Carta de Disciplina',
    subtitle: 'Notificação pastoral de deliberação disciplinar do Conselho',
    category: 'Termos & Atos',
    badge: 'Pastoral',
    defaultTemplate: `Prezado(a) irmão(ã) {NOME_MEMBRO},

O Conselho da {NOME_IGREJA}, reunido em Sessão Ordinária em {DATA_REUNIAO}, conforme registro lavrado na Ata nº {NUMERO_ATA}, no zelo espiritual que lhe compete de velar pela sã doutrina e conduta cristã dos membros deste rebanho, houve por bem cientificá-lo(a) do quanto segue:

Em virtude de {MOTIVO_DISCIPLINA}, após fraterna oração e deliberação conciliar, foi determinada a medida pastoral de suspensão temporária dos privilégios da comunhão eclesiástica e da Mesa da Santa Ceia do Senhor pelo período de {PERIODO_DISCIPLINA}, com fulcro no Livro de Disciplina da Igreja Presbiteriana do Brasil.

Enfatizamos que a presente ação tem caráter essencialmente pastoral, curativo e corretivo, visando à edificação da alma, à reconciliação espiritual e ao pleno reatamento da comunhão com o Senhor Jesus e Seu Corpo Santo, a Igreja. Rogamos que continue assistindo à pregação da Palavra e buscando a graça restauradora de Deus.`,
  },
  {
    key: 'certificado_batismo',
    title: 'Certificado de Batismo',
    subtitle: 'Certidão eclesiástica de batismo cristão nas águas',
    category: 'Certificados',
    badge: 'Sacramento',
    defaultTemplate: `Certificamos que {NOME_BATIZANDO}, nascido(a) em {DATA_NASCIMENTO}, filho(a) de {NOME_PAI} e de {NOME_MAE}, recebeu solenemente o Santo Sacramento do Batismo Cristão em nome do Pai, do Filho e do Espírito Santo, em cerimônia oficiada pelo Ministro da Palavra e dos Sacramentos {NOME_OFICIANTE}, em {DATA_BATISMO}, conforme assentamento no Livro de Registros Eclesiásticos desta Igreja.

"Ide, portanto, fazei discípulos de todas as nações, batizando-os em nome do Pai, e do Filho, e do Espírito Santo." — Mateus 28:19`,
  },
  {
    key: 'certificado_casamento',
    title: 'Certificado de Casamento',
    subtitle: 'Certidão solene de bênção matrimonial eclesiástica',
    category: 'Certificados',
    badge: 'Matrimônio',
    defaultTemplate: `Certificamos que em {DATA_CASAMENTO}, no templo da {NOME_IGREJA}, uniram-se pelos sagrados laços do matrimônio religioso os nubentes:

{NOME_NOIVO}
e
{NOME_NOIVA}

A solenidade e a bênção das alianças foram celebradas pelo Ministro da Palavra e dos Sacramentos {NOME_OFICIANTE}, perante a congregação dos santos e as testemunhas {TESTEMUNHAS_CASAMENTO}, em conformidade com as Sagradas Escrituras e a liturgia da Igreja Presbiteriana do Brasil.

"Assim já não são dois, mas uma só carne. Portanto, o que Deus ajuntou não o separe o homem." — Mateus 19:6`,
  },
  {
    key: 'exclusao',
    title: 'Exclusão',
    subtitle: 'Termo formal de demissão ou exclusão do Rol de Membros',
    category: 'Termos & Atos',
    badge: 'Conselho',
    defaultTemplate: `O Conselho da {NOME_IGREJA}, no cumprimento de suas atribuições constitucionais e eclesiásticas previstas no Manual Presbiteriano da Igreja Presbiteriana do Brasil, certifica que:

Em reunião de Conselho realizada no dia {DATA_REUNIAO}, sob a Ata nº {NUMERO_ATA}, foi homologado o desligamento e a exclusão do Rol de Membros desta Igreja do(a) senhor(a) {NOME_MEMBRO}, inscrito(a) sob o Rol nº {ROL_MEMBRO}, pelo seguinte motivo:

{MOTIVO_EXCLUSAO}

Com este ato, cessam todos os direitos, deveres e prerrogativas eclesiásticas do(a) referido(a) perante esta Igreja Local, mantendo-se o devido assentamento no Livro Oficial de Registros da Secretaria do Conselho.`,
  },
  {
    key: 'nomeacao_cargo',
    title: 'Nomeação de Cargo',
    subtitle: 'Portaria e termo de posse para ofícios, diretorias e departamentos',
    category: 'Termos & Atos',
    badge: 'Liderança',
    defaultTemplate: `O Conselho da {NOME_IGREJA}, no uso das atribuições que lhe confere a Constituição da Igreja Presbiteriana do Brasil, resolve:

NOMEAR E DAR POSSE ao(à) irmão(ã) {NOME_MEMBRO}, membro comungante arrolado sob o nº {ROL_MEMBRO}, para o exercício do ofício e função de:

{CARGO_NOMEADO}
junto ao departamento/sociedade {DEPARTAMENTO_SOCIEDADE}, com mandato para o exercício eclesiástico de {EXERCICIO_MANDATO}.

Confiamos ao(à) irmão(ã) o zeloso desempenho dessa nobre mordomia cristã, com integridade, fidelidade e submissão aos padrões doutrinários e de conduta de nossa denominação, certos de que "o vosso trabalho não é vão no Senhor" (1 Co 15:58).`,
  },
  {
    key: 'recomendacao',
    title: 'Recomendação',
    subtitle: 'Carta fraternal de recomendação comungante para Igreja-Irmã',
    category: 'Cartas',
    badge: 'Comunhão',
    defaultTemplate: `Ao Conselho e ao Pastor da amada Igreja Presbiteriana em {IGREJA_DESTINO},

Estimados irmãos em Cristo,

Temos a imensa satisfação de recomendar-lhes calorosamente o(a) prezado(a) irmão(ã) {NOME_MEMBRO}, membro comungante em plena comunhão desta Igreja, arrolado(a) sob o nº {ROL_MEMBRO}.

O(A) referido(a) irmão(ã) tem prestado testemunho de fé operosa e conduta cristã irrepreensível. Estando residindo ou permanecendo provisoriamente nessa localidade, recomendamos que lhe seja concedido o livre acesso à Mesa da Santa Ceia do Senhor e à fraternal convivência cristã nessa querida comunidade.

A presente carta de recomendação possui validade até {DATA_VALIDADE}, devendo ser renovada caso permaneça por mais tempo.

Subscrevemo-nos com fraterna saudação no Senhor,`,
  },
  {
    key: 'transferencia',
    title: 'Transferência',
    subtitle: 'Carta oficial de transferência comungante entre Igrejas Presbiterianas',
    category: 'Cartas',
    badge: 'Constituição IPB',
    defaultTemplate: `Ao Conselho da amada Igreja Presbiteriana em {IGREJA_DESTINO},

Irmãos mui amados em nosso Senhor Jesus Cristo,

Pela presente Carta de Transferência expedida de acordo com os dispositivos da Constituição da Igreja Presbiteriana do Brasil, transferimos para a vossa jurisdição eclesiástica o(a) irmão(ã):

{NOME_MEMBRO}
Inscrito(a) no Rol de Membros sob o nº {ROL_MEMBRO}, recebido(a) originalmente por {FORMA_RECEPCAO} em {DATA_RECEPCAO}.

Atestamos que o(a) referido(a) membro se encontra em pleno gozo de seus privilégios e direitos espirituais, sem qualquer restrição pastoral, disciplinar ou doutrinária perante esta congregação. Juntamente, acompanham-no(a) os seguintes menores não-comungantes sob sua responsabilidade: {FILHOS_MENORES}.

Rogamos que o(a) recebam fraternalmente em vosso seio como membro pleno e nos enviem oportunamente o competente canhoto de recepção preenchido, a fim de procedermos à respectiva baixa em nosso Rol de Membros.

Esta carta tem validade regulamentar de seis (6) meses a contar da data de sua emissão.`,
  },
];

@Injectable({
  providedIn: 'root',
})
export class ModelosCartasService {
  private configSignal = signal<ChurchLetterheadConfig>(this.loadStoredConfig());
  private historySignal = signal<IssuedDocumentRecord[]>(this.loadStoredHistory());

  readonly config = this.configSignal.asReadonly();
  readonly history = this.historySignal.asReadonly();
  readonly availableModels = DOCUMENT_MODELS;

  private loadStoredConfig(): ChurchLetterheadConfig {
    try {
      const saved = localStorage.getItem('ipb_letterhead_config');
      if (saved) {
        return { ...DEFAULT_CONFIG, ...JSON.parse(saved) };
      }
    } catch {
      // fallback
    }
    return DEFAULT_CONFIG;
  }

  private loadStoredHistory(): IssuedDocumentRecord[] {
    try {
      const saved = localStorage.getItem('ipb_issued_documents_history');
      if (saved) {
        return JSON.parse(saved);
      }
    } catch {
      // fallback
    }
    // Histórico de demonstração inicial
    const currentYear = new Date().getFullYear();
    return [
      {
        id: 'doc-001',
        code: `CT-012/${currentYear}`,
        typeKey: 'transferencia',
        typeTitle: 'Carta de Transferência',
        recipientName: 'Carlos Eduardo Oliveira',
        rollNumber: 'ROL-0108',
        issueDate: `${currentYear}-03-10`,
        churchDestination: 'IPB Jardim Camburi - Vitória/ES',
        details: 'Transferência concedida a pedido do membro por mudança de domicílio.',
      },
      {
        id: 'doc-002',
        code: `AT-045/${currentYear}`,
        typeKey: 'atestado_membresia',
        typeTitle: 'Atestado de Membresia',
        recipientName: 'Juliana Paes Ferreira',
        rollNumber: 'ROL-0115',
        issueDate: `${currentYear}-03-18`,
        churchDestination: 'Seminário Teológico Presbiteriano',
        details: 'Para fins de comprovação de vínculo eclesiástico para ingresso em curso teológico.',
      },
      {
        id: 'doc-003',
        code: `CB-004/${currentYear}`,
        typeKey: 'certificado_batismo',
        typeTitle: 'Certificado de Batismo',
        recipientName: 'Lucas Gabriel Martins',
        rollNumber: 'ROL-0128',
        issueDate: `${currentYear}-02-15`,
        details: 'Batismo infantil celebrado no culto solene de Santa Ceia.',
      },
    ];
  }

  saveConfig(newConfig: ChurchLetterheadConfig): void {
    this.configSignal.set(newConfig);
    try {
      localStorage.setItem('ipb_letterhead_config', JSON.stringify(newConfig));
    } catch {
      // ignore
    }
  }

  getModelByKey(key: DocumentTypeKey): DocumentModelItem | undefined {
    return DOCUMENT_MODELS.find((m) => m.key === key);
  }

  generateDocumentCode(key: DocumentTypeKey): string {
    const year = new Date().getFullYear();
    const count = this.historySignal().filter((h) => h.typeKey === key).length + 1;
    const prefixMap: Record<DocumentTypeKey, string> = {
      apresentacao: 'CA',
      apresentacao_crianca: 'AC',
      atestado_membresia: 'AM',
      carta_disciplina: 'CD',
      certificado_batismo: 'CB',
      certificado_casamento: 'CC',
      exclusao: 'TE',
      nomeacao_cargo: 'PC',
      recomendacao: 'CR',
      transferencia: 'CT',
    };
    const prefix = prefixMap[key] || 'DOC';
    return `${prefix}-${String(count).padStart(3, '0')}/${year}`;
  }

  addIssuedRecord(record: Omit<IssuedDocumentRecord, 'id'>): IssuedDocumentRecord {
    const newRecord: IssuedDocumentRecord = {
      ...record,
      id: `doc-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
    };
    const updated = [newRecord, ...this.historySignal()];
    this.historySignal.set(updated);
    try {
      localStorage.setItem('ipb_issued_documents_history', JSON.stringify(updated));
    } catch {
      // ignore
    }
    return newRecord;
  }

  deleteIssuedRecord(id: string): void {
    const updated = this.historySignal().filter((h) => h.id !== id);
    this.historySignal.set(updated);
    try {
      localStorage.setItem('ipb_issued_documents_history', JSON.stringify(updated));
    } catch {
      // ignore
    }
  }
}
