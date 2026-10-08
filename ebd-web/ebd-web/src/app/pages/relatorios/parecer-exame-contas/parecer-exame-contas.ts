import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { InputTextModule } from 'primeng/inputtext';
import { DialogModule } from 'primeng/dialog';
import { ToastModule } from 'primeng/toast';
import { CheckboxModule } from 'primeng/checkbox';
import { TooltipModule } from 'primeng/tooltip';
import { MessageService } from 'primeng/api';
import { CanonicExtraService, ParecerExameContas } from '@/app/core/canonic-extra.service';

@Component({
  selector: 'app-parecer-exame-contas',
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
    CheckboxModule,
    TooltipModule,
  ],
  providers: [MessageService],
  templateUrl: './parecer-exame-contas.html',
})
export class ParecerExameContasPage implements OnInit {
  private service = inject(CanonicExtraService);
  private msg = inject(MessageService);

  pareceres = signal<ParecerExameContas[]>([]);
  stats = signal({
    total: 0,
    sem_ressalvas: 0,
    com_ressalvas: 0,
    desfavoraveis: 0,
  });

  loading = signal<boolean>(true);

  // Modais
  dialogNovo = false;
  dialogLaudo = false;
  selectedParecer: ParecerExameContas | null = null;

  formParecer: Partial<ParecerExameContas> = {
    ano_exercicio: 2026,
    periodo: '1º Trimestre',
    data_emissao: new Date().toISOString().split('T')[0],
    relator: '',
    resultado: 'Favorável sem ressalvas',
    total_receitas_auditado: 0,
    total_despesas_auditado: 0,
    saldo_apurado: 0,
    conformidade_livro_caixa: true,
    conformidade_extratos_bancarios: true,
    conformidade_comprovantes_fiscais: true,
    conformidade_cotas_conciliares: true,
    ressalvas_e_recomendacoes: '',
    texto_conclusao: '',
    status: 'Concluído',
  };

  membrosTexto = '';

  ngOnInit(): void {
    this.carregarPareceres();
  }

  carregarPareceres(): void {
    this.loading.set(true);
    this.service.getPareceres().subscribe({
      next: (res) => {
        this.pareceres.set(res.pareceres.data || []);
        if (res.stats) this.stats.set(res.stats);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  abrirNovoParecer(): void {
    this.formParecer = {
      ano_exercicio: 2026,
      periodo: '1º Trimestre',
      data_emissao: new Date().toISOString().split('T')[0],
      relator: 'Diác. Rodrigo Sampaio (Presidente da Comissão)',
      resultado: 'Favorável sem ressalvas',
      total_receitas_auditado: 0,
      total_despesas_auditado: 0,
      saldo_apurado: 0,
      conformidade_livro_caixa: true,
      conformidade_extratos_bancarios: true,
      conformidade_comprovantes_fiscais: true,
      conformidade_cotas_conciliares: true,
      ressalvas_e_recomendacoes: '',
      texto_conclusao: 'A Comissão de Exame de Contas, após minucioso exame dos livros da Tesouraria da Igreja, extratos bancários, notas fiscais e comprovantes de pagamentos, constatou que os registros encontram-se em perfeita exatidão e conformidade com as normas administrativas e canônicas da Igreja Presbiteriana do Brasil. Portanto, somos de parecer FAVORÁVEL à aprovação das contas.',
      status: 'Concluído',
    };
    this.membrosTexto = 'Diác. Rodrigo Sampaio\nIrmã Vera Lúcia Magalhães\nPresb. Carlos Eduardo Prado';
    this.obterValoresSugeridos();
    this.dialogNovo = true;
  }

  obterValoresSugeridos(): void {
    if (!this.formParecer.ano_exercicio || !this.formParecer.periodo) return;

    this.service.auditarPeriodo(this.formParecer.ano_exercicio, this.formParecer.periodo).subscribe({
      next: (res) => {
        this.formParecer.total_receitas_auditado = res.total_receitas;
        this.formParecer.total_despesas_auditado = res.total_despesas;
        this.formParecer.saldo_apurado = res.saldo;
        this.msg.add({ severity: 'info', summary: 'Valores Carregados', detail: 'Totais contábeis do período consolidados automaticamente.' });
      },
    });
  }

  salvarParecer(): void {
    if (!this.formParecer.relator || !this.formParecer.texto_conclusao) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Preencha o relator e o texto conclusivo do parecer.' });
      return;
    }

    const membros = this.membrosTexto
      .split('\n')
      .map((m) => m.trim())
      .filter((m) => m.length > 0);

    const payload = {
      ...this.formParecer,
      membros_comissao: membros,
    };

    this.service.createParecer(payload).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Parecer Emitido', detail: 'Parecer eclesiástico gerado com sucesso.' });
        this.dialogNovo = false;
        this.carregarPareceres();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao emitir parecer.' }),
    });
  }

  verLaudo(p: ParecerExameContas): void {
    this.selectedParecer = p;
    this.dialogLaudo = true;
  }

  imprimirLaudo(): void {
    window.print();
  }

  getResultadoSeverity(r: string): 'success' | 'warn' | 'danger' {
    if (r === 'Favorável sem ressalvas') return 'success';
    if (r === 'Favorável com ressalvas') return 'warn';
    return 'danger';
  }
}
