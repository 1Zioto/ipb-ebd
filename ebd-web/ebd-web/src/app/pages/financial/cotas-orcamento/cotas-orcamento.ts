import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { InputTextModule } from 'primeng/inputtext';
import { DialogModule } from 'primeng/dialog';
import { ToastModule } from 'primeng/toast';
import { ProgressBarModule } from 'primeng/progressbar';
import { TooltipModule } from 'primeng/tooltip';
import { MessageService } from 'primeng/api';
import {
  CanonicExtraService,
  CotaConciliar,
  ComparativoOrcamentoResponse,
} from '@/app/core/canonic-extra.service';

@Component({
  selector: 'app-cotas-orcamento',
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
    ProgressBarModule,
    TooltipModule,
  ],
  providers: [MessageService],
  templateUrl: './cotas-orcamento.html',
})
export class CotasOrcamentoPage implements OnInit {
  private service = inject(CanonicExtraService);
  private msg = inject(MessageService);

  abaAtiva: 'cotas' | 'orcamento' = 'cotas';
  anoSelecionado = 2026;

  // Cotas
  cotas = signal<CotaConciliar[]>([]);
  statsCotas = signal({
    total_presbiterio_ano: 0,
    total_sc_ano: 0,
    pago_presbiterio: 0,
    pendente_presbiterio: 0,
    pago_sc: 0,
    pendente_sc: 0,
  });
  dialogCalcularCota = false;
  dialogPagamentoCota = false;
  selectedCota: CotaConciliar | null = null;

  formCalculo = {
    ano: 2026,
    mes: new Date().getMonth() + 1,
    base_calculo: undefined,
    aliquota_presbiterio_pct: 5.0,
    aliquota_supremo_concilio_pct: 5.0,
  };

  formPagamento = {
    status_presbiterio: 'Pago' as 'Pendente' | 'Pago',
    status_supremo_concilio: 'Pago' as 'Pendente' | 'Pago',
    data_pagamento_presbiterio: new Date().toISOString().split('T')[0],
    data_pagamento_sc: new Date().toISOString().split('T')[0],
    comprovante_presbiterio: '',
    comprovante_sc: '',
  };

  // Orçamento
  comparativo = signal<ComparativoOrcamentoResponse | null>(null);
  dialogLinhaOrcamento = false;
  formLinha = {
    ano: 2026,
    departamento_ou_sociedade: 'Escola Dominical (EBD)',
    descricao: '',
    valor_previsto_anual: 0,
    observacoes: '',
  };

  loading = signal<boolean>(true);

  readonly mesesNomes = [
    '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  ngOnInit(): void {
    this.carregarCotas();
    this.carregarOrcamento();
  }

  carregarCotas(): void {
    this.loading.set(true);
    this.service.getCotas(this.anoSelecionado).subscribe({
      next: (res) => {
        this.cotas.set(res.cotas || []);
        if (res.stats) this.statsCotas.set(res.stats);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  carregarOrcamento(): void {
    this.service.getComparativoOrcamento(this.anoSelecionado).subscribe({
      next: (res) => this.comparativo.set(res),
    });
  }

  abrirCalcularCota(): void {
    this.formCalculo = {
      ano: this.anoSelecionado,
      mes: new Date().getMonth() + 1,
      base_calculo: undefined,
      aliquota_presbiterio_pct: 5.0,
      aliquota_supremo_concilio_pct: 5.0,
    };
    this.dialogCalcularCota = true;
  }

  confirmarCalculoCota(): void {
    this.service.calcularCotaMes(this.formCalculo).subscribe({
      next: () => {
        this.msg.add({
          severity: 'success',
          summary: 'Cota Calculada',
          detail: `Cota de ${this.mesesNomes[this.formCalculo.mes]} calculada com base nas receitas do Livro Caixa.`,
        });
        this.dialogCalcularCota = false;
        this.carregarCotas();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao calcular cota.' }),
    });
  }

  abrirPagamento(cota: CotaConciliar): void {
    this.selectedCota = cota;
    this.formPagamento = {
      status_presbiterio: cota.status_presbiterio,
      status_supremo_concilio: cota.status_supremo_concilio,
      data_pagamento_presbiterio: cota.data_pagamento_presbiterio || new Date().toISOString().split('T')[0],
      data_pagamento_sc: cota.data_pagamento_sc || new Date().toISOString().split('T')[0],
      comprovante_presbiterio: cota.comprovante_presbiterio || '',
      comprovante_sc: cota.comprovante_sc || '',
    };
    this.dialogPagamentoCota = true;
  }

  salvarPagamento(): void {
    if (!this.selectedCota) return;

    this.service.atualizarPagamentoCota(this.selectedCota.id, this.formPagamento).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Repasse Atualizado', detail: 'Registro de pagamento atualizado.' });
        this.dialogPagamentoCota = false;
        this.carregarCotas();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao atualizar repasse.' }),
    });
  }

  abrirNovaLinhaOrcamento(): void {
    this.formLinha = {
      ano: this.anoSelecionado,
      departamento_ou_sociedade: 'Escola Dominical (EBD)',
      descricao: '',
      valor_previsto_anual: 0,
      observacoes: '',
    };
    this.dialogLinhaOrcamento = true;
  }

  salvarLinhaOrcamento(): void {
    if (!this.formLinha.descricao || !this.formLinha.valor_previsto_anual) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Preencha a descrição e o valor anual previsto.' });
      return;
    }

    this.service.createLinhaOrcamento(this.formLinha).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Orçamento Adicionado', detail: 'Linha orçamentária incluída no plano.' });
        this.dialogLinhaOrcamento = false;
        this.carregarOrcamento();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao salvar linha orçamentária.' }),
    });
  }

  removerLinha(id: number): void {
    if (!confirm('Deseja excluir esta linha orçamentária?')) return;
    this.service.deleteLinhaOrcamento(id).subscribe({
      next: () => {
        this.msg.add({ severity: 'info', summary: 'Removido', detail: 'Linha orçamentária removida.' });
        this.carregarOrcamento();
      },
    });
  }

  getStatusOrcamentoSeverity(status: string): 'success' | 'warn' | 'danger' {
    if (status === 'Estourado') return 'danger';
    if (status === 'Atenção (>85%)') return 'warn';
    return 'success';
  }
}
