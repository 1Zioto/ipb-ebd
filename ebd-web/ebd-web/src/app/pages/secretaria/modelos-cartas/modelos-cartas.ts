import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { ToastModule } from 'primeng/toast';
import { TooltipModule } from 'primeng/tooltip';
import { MessageService } from 'primeng/api';
import {
  ModelosCartasService,
  DocumentModelItem,
  DocumentTypeKey,
  ChurchLetterheadConfig,
  IssuedDocumentRecord,
} from '../../../core/modelos-cartas.service';
import { FALLBACK_MEMBERS_LIST } from '../../../core/members-fallback.data';
import { CongregationMember } from '../../../core/intelligence.service';
import { PdfService } from '../../../core/pdf.service';

@Component({
  selector: 'app-modelos-cartas',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    DialogModule,
    InputTextModule,
    TextareaModule,
    TableModule,
    TagModule,
    ToastModule,
    TooltipModule,
  ],
  providers: [MessageService],
  templateUrl: './modelos-cartas.html',
  styleUrls: ['./modelos-cartas.scss'],
})
export class ModelosCartasPage implements OnInit {
  private service = inject(ModelosCartasService);
  private msg = inject(MessageService);
  private router = inject(Router);
  private pdfSvc = inject(PdfService);

  // Lista dos 10 modelos disponíveis
  readonly models = this.service.availableModels;
  readonly churchConfig = this.service.config;
  readonly issuedHistory = this.service.history;

  // Membros cadastrados (76 membros reais)
  members = signal<CongregationMember[]>(FALLBACK_MEMBERS_LIST.members);
  searchMemberQuery = signal<string>('');

  // Membro filtrado para busca rápida
  filteredMembers = computed(() => {
    const q = this.searchMemberQuery().toLowerCase().trim();
    if (!q) return this.members();
    return this.members().filter(
      (m) =>
        m.full_name.toLowerCase().includes(q) ||
        (m.roll_number && m.roll_number.toLowerCase().includes(q)) ||
        (m.cpf && m.cpf.includes(q))
    );
  });

  // Estado do Diálogo de Preenchimento
  fillDialog = signal<boolean>(false);
  selectedModel = signal<DocumentModelItem | null>(null);
  selectedMember = signal<CongregationMember | null>(null);

  // Estado do Diálogo de Configuração da Igreja
  configDialog = signal<boolean>(false);
  editConfig = signal<ChurchLetterheadConfig>({ ...this.service.config() });

  // Estado do Diálogo de Histórico
  historyDialog = signal<boolean>(false);

  // Estado do Diálogo de Pré-visualização A4
  previewDialog = signal<boolean>(false);

  // Campos do formulário dinâmico
  formDocumentNumber = signal<string>('');
  formIssueDate = signal<string>(new Date().toISOString().substring(0, 10));

  // Variáveis comuns
  varMemberName = signal<string>('');
  varRollNumber = signal<string>('');

  // Variáveis específicas
  varChurchDestination = signal<string>('');
  varCityState = signal<string>('Vitória/ES');
  varTransitReason = signal<string>('trabalho e aperfeiçoamento profissional');
  varTransitPeriod = signal<string>('6 (seis) meses');

  varChildName = signal<string>('');
  varBirthDate = signal<string>('');
  varFatherName = signal<string>('');
  varMotherName = signal<string>('');
  varPresentationDate = signal<string>(new Date().toISOString().substring(0, 10));
  varOfficiant = signal<string>('');

  varCertificatePurpose = signal<string>('fins acadêmicos e comprovação de vínculo eclesiástico');
  varValidityDays = signal<string>('90 dias');

  varDisciplineReason = signal<string>('ausência injustificada aos meios de graça e conduta em dissonância com os votos eclesiásticos');
  varDisciplinePeriod = signal<string>('6 meses com acompanhamento pastoral');
  varCouncilMeetingDate = signal<string>(new Date().toISOString().substring(0, 10));
  varMinutesNumber = signal<string>('08/2026');

  varBaptismType = signal<string>('Profissão de Fé e Batismo');
  varBaptismDate = signal<string>(new Date().toISOString().substring(0, 10));

  varGroomName = signal<string>('');
  varBrideName = signal<string>('');
  varWeddingDate = signal<string>(new Date().toISOString().substring(0, 10));
  varWeddingWitnesses = signal<string>('Pb. Antônio Carlos e Diác. Marcos Silva');

  varExclusionReason = signal<string>('transferência solicitada e homologada para outra comunidade evangélica');

  varAppointedOffice = signal<string>('Superintendente da Escola Bíblica Dominical');
  varDepartment = signal<string>('Superintendência Geral da EBD');
  varTermPeriod = signal<string>('Ano Eclesiástico de 2026');

  varRecommendationValidity = signal<string>('180 dias');

  varMinorChildren = signal<string>('Nenhum menor arrolado');
  varReceptionType = signal<string>('Profissão de Fé e Batismo');
  varReceptionDate = signal<string>('10/05/2018');

  // Texto gerado da carta para edição manual se desejado
  customizedBodyText = signal<string>('');

  ngOnInit(): void {
    this.editConfig.set({ ...this.service.config() });
  }

  // Ação ao clicar em um card da lista de 10
  openDocumentFill(model: DocumentModelItem): void {
    this.selectedModel.set(model);
    this.formDocumentNumber.set(this.service.generateDocumentCode(model.key));
    this.formIssueDate.set(new Date().toISOString().substring(0, 10));
    this.selectedMember.set(null);
    this.searchMemberQuery.set('');

    // Preenche oficiante padrão com o pastor titular
    this.varOfficiant.set(this.churchConfig().pastorName);

    // Gera texto inicial com placeholders padrão
    this.regenerateBodyText();

    this.fillDialog.set(true);
  }

  // Selecionar membro do rol
  onSelectMember(member: CongregationMember): void {
    this.selectedMember.set(member);
    this.varMemberName.set(member.full_name);
    this.varRollNumber.set(member.roll_number || 'Sem Rol');
    this.varBirthDate.set(member.birth_date ? this.formatDateBR(member.birth_date) : '');
    this.varReceptionType.set(this.formatReceptionType(member.reception_type ?? undefined));
    this.varReceptionDate.set(member.reception_date ? this.formatDateBR(member.reception_date) : 'Conforme Registro');

    if (member.spouse_name) {
      this.varGroomName.set(member.full_name);
      this.varBrideName.set(member.spouse_name);
    } else {
      this.varGroomName.set(member.full_name);
    }

    if (member.families && member.families.length > 0) {
      this.varMotherName.set(`Membro da ${member.families[0].name}`);
    }

    this.regenerateBodyText();
    this.msg.add({
      severity: 'info',
      summary: 'Membro Selecionado',
      detail: `${member.full_name} (${member.roll_number || 'S/ Rol'}) carregado com sucesso!`,
      life: 2500,
    });
  }

  // Gera o corpo do documento com as variáveis atuais
  regenerateBodyText(): void {
    const model = this.selectedModel();
    if (!model) return;

    const conf = this.churchConfig();
    let text = model.defaultTemplate;

    const memberName = this.varMemberName() || '[Nome do Membro]';
    const rollNum = this.varRollNumber() || '[Nº Rol]';

    text = text.replace(/{NOME_MEMBRO}/g, memberName);
    text = text.replace(/{ROL_MEMBRO}/g, rollNum);
    text = text.replace(/{NOME_IGREJA}/g, conf.churchName);
    text = text.replace(/{NOME_PRESBITERIO}/g, conf.presbytery);
    text = text.replace(/{NOME_SINODO}/g, conf.synod);

    // Específicos
    text = text.replace(/{MOTIVO_TRANSITO}/g, this.varTransitReason());
    text = text.replace(/{PERIODO_TRANSITO}/g, this.varTransitPeriod());
    text = text.replace(/{IGREJA_DESTINO}/g, this.varChurchDestination() || '[Igreja de Destino]');

    text = text.replace(/{NOME_CRIANCA}/g, this.varChildName() || '[Nome da Criança]');
    text = text.replace(/{DATA_NASCIMENTO}/g, this.varBirthDate() || '[Data de Nascimento]');
    text = text.replace(/{NOME_PAI}/g, this.varFatherName() || '[Nome do Pai]');
    text = text.replace(/{NOME_MAE}/g, this.varMotherName() || '[Nome da Mãe]');

    text = text.replace(/{FINALIDADE_ATESTADO}/g, this.varCertificatePurpose());

    text = text.replace(/{MOTIVO_DISCIPLINA}/g, this.varDisciplineReason());
    text = text.replace(/{PERIODO_DISCIPLINA}/g, this.varDisciplinePeriod());
    text = text.replace(/{DATA_REUNIAO}/g, this.formatDateBR(this.varCouncilMeetingDate()));
    text = text.replace(/{NUMERO_ATA}/g, this.varMinutesNumber());

    text = text.replace(/{NOME_BATIZANDO}/g, memberName);
    text = text.replace(/{DATA_BATISMO}/g, this.formatDateBR(this.varBaptismDate()));
    text = text.replace(/{NOME_OFICIANTE}/g, this.varOfficiant() || conf.pastorName);

    text = text.replace(/{NOME_NOIVO}/g, this.varGroomName() || '[Nome do Noivo]');
    text = text.replace(/{NOME_NOIVA}/g, this.varBrideName() || '[Nome da Noiva]');
    text = text.replace(/{DATA_CASAMENTO}/g, this.formatDateBR(this.varWeddingDate()));
    text = text.replace(/{TESTEMUNHAS_CASAMENTO}/g, this.varWeddingWitnesses());

    text = text.replace(/{MOTIVO_EXCLUSAO}/g, this.varExclusionReason());

    text = text.replace(/{CARGO_NOMEADO}/g, this.varAppointedOffice());
    text = text.replace(/{DEPARTAMENTO_SOCIEDADE}/g, this.varDepartment());
    text = text.replace(/{EXERCICIO_MANDATO}/g, this.varTermPeriod());

    text = text.replace(/{DATA_VALIDADE}/g, this.varRecommendationValidity());

    text = text.replace(/{FORMA_RECEPCAO}/g, this.varReceptionType());
    text = text.replace(/{DATA_RECEPCAO}/g, this.varReceptionDate());
    text = text.replace(/{FILHOS_MENORES}/g, this.varMinorChildren());

    this.customizedBodyText.set(text);
  }

  // Abre visualização prévia da folha timbrada oficial
  openPreview(): void {
    this.regenerateBodyText();
    this.previewDialog.set(true);
  }

  // Emissão de PDF oficial em nova aba via PdfService (folha A4 timbrada de alta definição)
  gerarPdfOficial(): void {
    this.salvarRegistroHistorico(false);
    const model = this.selectedModel();
    const titulo = model?.title || 'Documento Oficial';
    const codigo = (this.formDocumentNumber() || 'doc').replace(/[^a-zA-Z0-9-]/g, '_');

    this.regenerateBodyText();

    if (!this.previewDialog()) {
      this.previewDialog.set(true);
    }

    setTimeout(() => {
      this.pdfSvc.gerarPdfEmNovaAba(
        'sheet-a4-preview-content',
        `chancelaria-ipb-${codigo.toLowerCase()}`,
        `${titulo} — Chancelaria IPB`
      );
    }, 150);
  }

  // Imprimir diretamente (abre o visualizador solene com disparo de impressão nativa)
  imprimirDocumento(): void {
    this.gerarPdfOficial();
  }

  // Copiar texto para o clipboard
  copiarTexto(): void {
    navigator.clipboard.writeText(this.customizedBodyText()).then(() => {
      this.msg.add({
        severity: 'success',
        summary: 'Copiado!',
        detail: 'Texto do documento copiado para a área de transferência.',
        life: 2500,
      });
    });
  }

  // Salvar registro no histórico da secretaria
  salvarRegistroHistorico(showToast = true): void {
    const model = this.selectedModel();
    if (!model) return;

    this.service.addIssuedRecord({
      code: this.formDocumentNumber(),
      typeKey: model.key,
      typeTitle: model.title,
      recipientName: this.varMemberName() || this.varChildName() || 'Documento Geral',
      rollNumber: this.varRollNumber() || undefined,
      issueDate: this.formIssueDate(),
      churchDestination: this.varChurchDestination() || undefined,
      details: `${model.subtitle} emitido em conformidade com o Manual Presbiteriano da IPB.`,
    });

    if (showToast) {
      this.msg.add({
        severity: 'success',
        summary: 'Salvo no Histórico',
        detail: `Protocolo ${this.formDocumentNumber()} registrado com sucesso!`,
        life: 3000,
      });
    }
  }

  // Reabrir documento do histórico para impressão
  reimprimirDoHistorico(rec: IssuedDocumentRecord): void {
    const model = this.service.getModelByKey(rec.typeKey);
    if (!model) return;

    this.selectedModel.set(model);
    this.formDocumentNumber.set(rec.code);
    this.formIssueDate.set(rec.issueDate);
    this.varMemberName.set(rec.recipientName);
    this.varRollNumber.set(rec.rollNumber || '');
    this.varChurchDestination.set(rec.churchDestination || '');

    this.regenerateBodyText();
    this.historyDialog.set(false);
    this.previewDialog.set(true);
  }

  excluirDoHistorico(id: string): void {
    this.service.deleteIssuedRecord(id);
    this.msg.add({
      severity: 'info',
      summary: 'Removido',
      detail: 'Registro removido do histórico da secretaria.',
    });
  }

  // Navegar de volta ao painel
  voltarAoPainel(): void {
    this.router.navigate(['/dashboard']);
  }

  // Abrir configuração da igreja
  abrirConfiguracao(): void {
    this.editConfig.set({ ...this.churchConfig() });
    this.configDialog.set(true);
  }

  // Salvar configurações editadas
  salvarConfiguracao(): void {
    this.service.saveConfig(this.editConfig());
    this.configDialog.set(false);
    this.msg.add({
      severity: 'success',
      summary: 'Configuração Atualizada',
      detail: 'Dados e timbres da Igreja e oficiais salvos com sucesso!',
    });
  }

  // Data formatada por extenso no padrão de chancelaria
  getDataPorExtenso(): string {
    const date = new Date(this.formIssueDate() + 'T12:00:00');
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    const dia = date.getDate();
    const mes = meses[date.getMonth()];
    const ano = date.getFullYear();
    return `${this.churchConfig().cityState}, ${dia} de ${mes} de ${ano}.`;
  }

  private formatDateBR(dateStr: string): string {
    if (!dateStr) return '';
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      return `${parts[2]}/${parts[1]}/${parts[0]}`;
    }
    return dateStr;
  }

  private formatReceptionType(type?: string): string {
    if (!type) return 'Profissão de Fé e Batismo';
    const map: Record<string, string> = {
      profissao_fe_batismo: 'Profissão de Fé e Batismo',
      profissao_fe: 'Profissão de Fé',
      transferencia: 'Carta de Transferência',
      jurisdicao: 'Jurisdição Eclesiástica a Pedido',
      restauracao: 'Restauração da Comunhão',
    };
    return map[type] || type;
  }
}
