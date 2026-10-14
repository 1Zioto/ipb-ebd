import { Component, ElementRef, OnInit, ViewChild, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, switchMap, of } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { CheckboxModule } from 'primeng/checkbox';
import { TagModule } from 'primeng/tag';
import { MessageModule } from 'primeng/message';
import { TooltipModule } from 'primeng/tooltip';
import { DizimosService } from '../../core/dizimos.service';
import { PeopleService } from '../../core/people.service';
import { ColetaDizimo, LancamentoDizimo, Person, ComprovanteConferencia } from '../../core/models';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';

@Component({
  selector: 'app-coleta-lancamento',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    ButtonModule,
    TableModule,
    DialogModule,
    InputTextModule,
    TextareaModule,
    CheckboxModule,
    TagModule,
    MessageModule,
    TooltipModule,
  ],
  templateUrl: './coleta-lancamento.html',
})
export class ColetaLancamentoPage implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private dizimosService = inject(DizimosService);
  private peopleService = inject(PeopleService);
  private toast = inject(ToastService);
  auth = inject(AuthService);

  @ViewChild('searchInput') searchInput!: ElementRef<HTMLInputElement>;
  @ViewChild('amountInput') amountInput!: ElementRef<HTMLInputElement>;

  coleta = signal<ColetaDizimo | null>(null);
  lancamentos = signal<LancamentoDizimo[]>([]);
  filteredTithers = signal<Person[]>([]);
  searchLoading = signal<boolean>(false);

  coletaId = 0;
  loading = signal<boolean>(true);
  saving = signal<boolean>(false);
  savingOfertas = signal<boolean>(false);

  // Form de lançamento rápido de envelope
  searchTerm = '';
  selectedPerson: Person | null = null;
  amount: number | null = null;
  paymentMethod = 'dinheiro'; // 'dinheiro', 'pix', 'transferencia'
  contributionType = 'dizimo';
  envelopeNumber = '';
  isUnidentified = false;
  notes = '';

  // Ofertas avulsas (separadas dos envelopes)
  ofertaDinheiro = 0;
  ofertaPix = 0;
  ofertaTransferencia = 0;

  // Aviso de Duplicidade
  showDuplicateModal = signal<boolean>(false);
  duplicateMessage = '';

  // Modal de Edição de Lançamento
  showEditModal = signal<boolean>(false);
  editingLancamento: LancamentoDizimo | null = null;
  editAmount: number | null = null;
  editPaymentMethod = 'dinheiro';
  editEnvelopeNumber = '';
  editReason = '';
  editSaving = signal<boolean>(false);

  // Modal de Exclusão de Lançamento
  showDeleteModal = signal<boolean>(false);
  deletingLancamento: LancamentoDizimo | null = null;
  deleteReason = '';
  deleteSaving = signal<boolean>(false);

  // Modal de Encerramento em 4 Etapas
  showCloseModal = signal<boolean>(false);
  closeStep = signal<number>(1); // 1, 2, 3, 4
  closingInProgress = signal<boolean>(false);

  // Modal de Reabertura
  showReopenModal = signal<boolean>(false);
  reopenReason = '';

  // Modal do Comprovante de Impressão (2 Vias)
  showComprovanteModal = signal<boolean>(false);
  comprovanteData = signal<ComprovanteConferencia | null>(null);
  carregandoComprovante = signal<boolean>(false);

  // Totais calculados em tempo real
  totalDizimos = computed(() => {
    return this.lancamentos().reduce((acc, l) => acc + (Number(l.amount) || 0), 0);
  });

  qtdEnvelopes = computed(() => {
    return this.lancamentos().length;
  });

  totalOfertasAvulsas = computed(() => {
    return (Number(this.ofertaDinheiro) || 0) + (Number(this.ofertaPix) || 0) + (Number(this.ofertaTransferencia) || 0);
  });

  totalGeral = computed(() => {
    return this.totalDizimos() + this.totalOfertasAvulsas();
  });

  // Totais de dízimos por forma
  dizimosDinheiro = computed(() => {
    return this.lancamentos().filter((l) => (l.payment_method || 'dinheiro').toLowerCase() === 'dinheiro')
      .reduce((acc, l) => acc + (Number(l.amount) || 0), 0);
  });

  dizimosPix = computed(() => {
    return this.lancamentos().filter((l) => (l.payment_method || '').toLowerCase() === 'pix')
      .reduce((acc, l) => acc + (Number(l.amount) || 0), 0);
  });

  dizimosTransferencia = computed(() => {
    return this.lancamentos().filter((l) => (l.payment_method || '').toLowerCase() === 'transferencia')
      .reduce((acc, l) => acc + (Number(l.amount) || 0), 0);
  });

  // Consolidados gerais (Dízimos + Ofertas)
  consolidadoDinheiro = computed(() => {
    return this.dizimosDinheiro() + (Number(this.ofertaDinheiro) || 0);
  });

  consolidadoPix = computed(() => {
    return this.dizimosPix() + (Number(this.ofertaPix) || 0);
  });

  consolidadoTransferencia = computed(() => {
    return this.dizimosTransferencia() + (Number(this.ofertaTransferencia) || 0);
  });

  private searchSubject = new Subject<string>();

  constructor() {
    this.searchSubject
      .pipe(
        debounceTime(250),
        distinctUntilChanged(),
        switchMap((term) => {
          if (!term.trim() || term.trim().length < 2) {
            this.filteredTithers.set([]);
            this.searchLoading.set(false);
            return of(null);
          }
          this.searchLoading.set(true);
          return of(term);
        }),
        takeUntilDestroyed()
      )
      .subscribe(async (term) => {
        if (!term) return;
        try {
          const res = await this.peopleService.list({ search: term, is_active: true, per_page: 8 });
          this.filteredTithers.set(res.data);

          // Se for código ou envelope exato
          const exact = res.data.find(
            (p) =>
              p.envelope_number?.toLowerCase() === term.toLowerCase().trim() ||
              `ipb:${p.envelope_number}`.toLowerCase() === term.toLowerCase().trim() ||
              `env:${p.envelope_number}`.toLowerCase() === term.toLowerCase().trim()
          );
          if (exact) {
            this.selectPerson(exact);
          }
        } catch {
        } finally {
          this.searchLoading.set(false);
        }
      });
  }

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.coletaId = +id;
      this.loadColetaDetails();
    }
  }

  loadColetaDetails(): void {
    this.loading.set(true);
    this.dizimosService.getColeta(this.coletaId).subscribe({
      next: (res) => {
        this.coleta.set(res);
        if (res.lancamentos) {
          this.lancamentos.set(res.lancamentos);
        }
        this.ofertaDinheiro = Number(res.oferta_dinheiro) || 0;
        this.ofertaPix = Number(res.oferta_pix) || 0;
        this.ofertaTransferencia = Number(res.oferta_transferencia) || 0;
        this.loading.set(false);
        setTimeout(() => this.focusSearch(), 100);
      },
      error: () => {
        this.toast.error('Erro ao carregar dados da conferência.');
        this.loading.set(false);
      },
    });
  }

  onSearchChange(): void {
    if (this.isUnidentified) return;
    if (!this.searchTerm.trim()) {
      this.filteredTithers.set([]);
      this.selectedPerson = null;
      return;
    }
    this.selectedPerson = null;
    this.searchSubject.next(this.searchTerm);
  }

  selectPerson(p: Person): void {
    this.selectedPerson = p;
    this.searchTerm = `${p.full_name}${p.envelope_number ? ' (Envelope #' + p.envelope_number + ')' : ''}`;
    this.envelopeNumber = p.envelope_number || '';
    this.filteredTithers.set([]);
    setTimeout(() => this.amountInput?.nativeElement?.focus(), 50);
  }

  addQuickAmount(delta: number): void {
    const cur = Number(this.amount) || 0;
    this.amount = Number((cur + delta).toFixed(2));
  }

  setExactAmount(val: number): void {
    this.amount = val;
  }

  submitLancamento(force = false): void {
    if (this.saving()) return;

    if (!this.isUnidentified && !this.selectedPerson) {
      this.toast.warning('Por favor, selecione um membro contribuinte ou marque a opção "Contribuinte não identificado".');
      return;
    }

    if (!this.amount || this.amount <= 0) {
      this.toast.warning('Por favor, informe um valor válido em Reais (R$) para o lançamento.');
      return;
    }

    this.saving.set(true);

    this.dizimosService
      .addLancamento(this.coletaId, {
        person_id: this.isUnidentified ? null : this.selectedPerson?.id,
        amount: this.amount,
        contribution_type: this.contributionType,
        payment_method: this.paymentMethod,
        envelope_number: this.envelopeNumber || this.selectedPerson?.envelope_number || null,
        contribuinte_nome: this.selectedPerson?.full_name || (this.isUnidentified ? 'Não identificado' : this.searchTerm),
        is_unidentified: this.isUnidentified,
        notes: this.notes,
        force,
      })
      .subscribe({
        next: (res) => {
          this.saving.set(false);

          if (res.duplicate) {
            this.duplicateMessage = res.message || 'Lançamento com mesmo envelope ou contribuinte já registrado nesta conferência.';
            this.showDuplicateModal.set(true);
            return;
          }

          this.showDuplicateModal.set(false);
          this.toast.success(`Envelope de R$ ${Number(this.amount).toFixed(2)} registrado com sucesso!`);
          this.resetFormAndRefocus();
          this.loadColetaDetails();
        },
        error: (err) => {
          this.saving.set(false);
          this.toast.error(err.error?.message || 'Erro ao registrar envelope na conferência.');
        },
      });
  }

  confirmForceLancamento(): void {
    this.submitLancamento(true);
  }

  cancelDuplicateModal(): void {
    this.showDuplicateModal.set(false);
    this.focusSearch();
  }

  resetFormAndRefocus(): void {
    this.searchTerm = '';
    this.selectedPerson = null;
    this.amount = null;
    this.envelopeNumber = '';
    this.notes = '';
    this.isUnidentified = false;
    this.paymentMethod = 'dinheiro';
    this.filteredTithers.set([]);
    this.focusSearch();
  }

  focusSearch(): void {
    if (this.searchInput?.nativeElement) {
      this.searchInput.nativeElement.focus();
    }
  }

  // --- Ações de Edição e Exclusão de Lançamento ---
  abrirEdicao(l: LancamentoDizimo): void {
    this.editingLancamento = l;
    this.editAmount = Number(l.amount);
    this.editPaymentMethod = l.payment_method || 'dinheiro';
    this.editEnvelopeNumber = l.envelope_number || '';
    this.editReason = '';
    this.showEditModal.set(true);
  }

  salvarEdicao(): void {
    if (!this.editingLancamento || !this.editAmount || this.editAmount <= 0) {
      this.toast.warning('Informe um valor válido.');
      return;
    }
    this.editSaving.set(true);
    this.dizimosService
      .updateLancamento(this.coletaId, this.editingLancamento.id, {
        amount: this.editAmount,
        payment_method: this.editPaymentMethod,
        envelope_number: this.editEnvelopeNumber || null,
        reason: this.editReason || 'Ajuste de valor/forma pelo operador',
      })
      .subscribe({
        next: () => {
          this.editSaving.set(false);
          this.showEditModal.set(false);
          this.toast.success('Lançamento atualizado com sucesso.');
          this.loadColetaDetails();
        },
        error: (err) => {
          this.editSaving.set(false);
          this.toast.error(err.error?.message || 'Erro ao atualizar lançamento.');
        },
      });
  }

  abrirExclusao(l: LancamentoDizimo): void {
    this.deletingLancamento = l;
    this.deleteReason = '';
    this.showDeleteModal.set(true);
  }

  confirmarExclusao(): void {
    if (!this.deletingLancamento) return;
    this.deleteSaving.set(true);
    this.dizimosService
      .deleteLancamento(this.coletaId, this.deletingLancamento.id, this.deleteReason)
      .subscribe({
        next: () => {
          this.deleteSaving.set(false);
          this.showDeleteModal.set(false);
          this.toast.success('Lançamento removido da conferência.');
          this.loadColetaDetails();
        },
        error: (err) => {
          this.deleteSaving.set(false);
          this.toast.error(err.error?.message || 'Erro ao excluir lançamento.');
        },
      });
  }

  // --- Ofertas Avulsas ---
  salvarOfertasAvulsas(): void {
    this.savingOfertas.set(true);
    this.dizimosService
      .saveOfertas(this.coletaId, {
        oferta_dinheiro: Number(this.ofertaDinheiro) || 0,
        oferta_pix: Number(this.ofertaPix) || 0,
        oferta_transferencia: Number(this.ofertaTransferencia) || 0,
      })
      .subscribe({
        next: () => {
          this.savingOfertas.set(false);
          this.toast.success('Ofertas avulsas salvas com sucesso!');
          this.loadColetaDetails();
        },
        error: (err) => {
          this.savingOfertas.set(false);
          this.toast.error(err.error?.message || 'Erro ao salvar ofertas avulsas.');
        },
      });
  }

  // --- Encerramento da Conferência em 4 Etapas ---
  iniciarEncerramento(): void {
    this.closeStep.set(1);
    this.showCloseModal.set(true);
  }

  avancarEtapa(): void {
    if (this.closeStep() < 4) {
      this.closeStep.set(this.closeStep() + 1);
    }
  }

  voltarEtapa(): void {
    if (this.closeStep() > 1) {
      this.closeStep.set(this.closeStep() - 1);
    }
  }

  confirmarEncerramentoDefinitivo(): void {
    if (this.closingInProgress()) return;
    this.closingInProgress.set(true);

    const ofertas = {
      oferta_dinheiro: Number(this.ofertaDinheiro) || 0,
      oferta_pix: Number(this.ofertaPix) || 0,
      oferta_transferencia: Number(this.ofertaTransferencia) || 0,
    };

    this.dizimosService.closeColeta(this.coletaId, undefined, ofertas).subscribe({
      next: (res) => {
        this.closingInProgress.set(false);
        this.showCloseModal.set(false);
        this.toast.success('Conferência encerrada com sucesso! Emitindo comprovante oficial...');
        this.loadColetaDetails();

        // Carrega e exibe o comprovante em duas vias
        if (res.comprovante) {
          this.comprovanteData.set(res.comprovante);
          this.showComprovanteModal.set(true);
          // Auto-print nativo na web (duas vias normais, sem impressora predefinida)
          setTimeout(() => {
            window.print();
          }, 600);
        }
      },
      error: (err) => {
        this.closingInProgress.set(false);
        this.toast.error(err.error?.message || 'Erro ao encerrar conferência.');
      },
    });
  }

  // --- Reabertura ---
  reabrirConferencia(): void {
    if (!this.reopenReason.trim()) {
      this.toast.warning('Informe o motivo formal para reabertura da conferência.');
      return;
    }
    this.dizimosService.reopenColeta(this.coletaId, this.reopenReason).subscribe({
      next: () => {
        this.showReopenModal.set(false);
        this.reopenReason = '';
        this.loadColetaDetails();
        this.toast.success('Conferência reaberta para correções.');
      },
      error: (err) => this.toast.error(err.error?.message || 'Erro ao reabrir conferência.'),
    });
  }

  // --- Visualizar / Reimprimir Comprovante ---
  abrirComprovante(reimprimir = false): void {
    this.carregandoComprovante.set(true);
    this.showComprovanteModal.set(true);

    const call$ = reimprimir
      ? this.dizimosService.reimprimir(this.coletaId)
      : this.dizimosService.getComprovante(this.coletaId);

    call$.subscribe({
      next: (data) => {
        this.comprovanteData.set(data);
        this.carregandoComprovante.set(false);
      },
      error: () => {
        this.carregandoComprovante.set(false);
        this.toast.error('Erro ao carregar comprovante.');
      },
    });
  }

  imprimirComprovanteWeb(): void {
    window.print();
  }

  isAberta(): boolean {
    const s = this.coleta()?.status;
    return s === 'Aberta' || s === 'Reaberta para correção' || s === 'EM ANDAMENTO';
  }
}
