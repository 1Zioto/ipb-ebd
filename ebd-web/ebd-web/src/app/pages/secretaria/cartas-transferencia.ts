import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { SecretariaService, CartaTransferencia, CanonicalMember } from '../../core/secretaria.service';

@Component({
  selector: 'app-cartas-transferencia',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    TableModule,
    ButtonModule,
    TagModule,
    DialogModule,
    InputTextModule,
    ToastModule,
  ],
  providers: [MessageService],
  templateUrl: './cartas-transferencia.html',
})
export class CartasTransferenciaPage implements OnInit {
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);

  cartas = signal<CartaTransferencia[]>([]);
  membros = signal<CanonicalMember[]>([]);
  loading = signal<boolean>(true);

  tipoFilter = '';
  statusFilter = '';

  tipoOptions = [
    { label: 'Todos os Tipos', value: '' },
    { label: 'Emitidas (Saída)', value: 'Emitida' },
    { label: 'Recebidas (Entrada)', value: 'Recebida' },
  ];

  statusOptions = [
    { label: 'Todos os Status', value: '' },
    { label: 'Ativas', value: 'Ativa' },
    { label: 'Concluídas', value: 'Concluída' },
    { label: 'Expiradas', value: 'Expirada' },
    { label: 'Canceladas', value: 'Cancelada' },
  ];

  // Modal Nova Carta
  newDialog = false;
  newCarta: Partial<CartaTransferencia> = {
    tipo: 'Emitida',
    status: 'Ativa',
    igreja_origem: 'Igreja Presbiteriana em Campo Verde - MT',
    igreja_destino: '',
    data_emissao: new Date().toISOString().substring(0, 10),
    data_validade: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10),
  };

  // Modal Visualização Canônica
  viewDialog = false;
  selectedCarta: CartaTransferencia | null = null;

  ngOnInit(): void {
    this.carregarCartas();
    this.carregarMembros();
  }

  carregarCartas(): void {
    this.loading.set(true);
    this.secService
      .getCartas({
        tipo: this.tipoFilter || undefined,
        status: this.statusFilter || undefined,
      })
      .subscribe({
        next: (res) => {
          this.cartas.set(res.data);
          this.loading.set(false);
        },
        error: () => {
          this.loading.set(false);
          this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Erro ao carregar cartas de transferência.' });
        },
      });
  }

  carregarMembros(): void {
    this.secService.getMembros().subscribe({
      next: (res) => this.membros.set(res.membros.data),
    });
  }

  abrirNovaCarta(): void {
    const ano = new Date().getFullYear();
    const seq = this.cartas().length + 1;
    this.newCarta = {
      numero_carta: `CT-${String(seq).padStart(3, '0')}/${ano}`,
      tipo: 'Emitida',
      status: 'Ativa',
      igreja_origem: 'Igreja Presbiteriana em Campo Verde - MT',
      igreja_destino: '',
      data_emissao: new Date().toISOString().substring(0, 10),
      data_validade: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10),
      observacoes: 'Membro em plena comunhão e sem impedimento canônico.',
    };
    this.newDialog = true;
  }

  salvarNovaCarta(): void {
    if (!this.newCarta.person_id || !this.newCarta.numero_carta || !this.newCarta.igreja_destino) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Preencha todos os campos obrigatórios.' });
      return;
    }

    this.secService.createCarta(this.newCarta).subscribe({
      next: (carta) => {
        this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Carta de transferência emitida!' });
        this.newDialog = false;
        this.carregarCartas();
        this.visualizarCarta(carta);
      },
      error: () => {
        this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao salvar carta de transferência.' });
      },
    });
  }

  visualizarCarta(carta: CartaTransferencia): void {
    this.selectedCarta = carta;
    this.viewDialog = true;
  }

  imprimir(): void {
    window.print();
  }
}
