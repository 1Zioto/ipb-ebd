import { Component, ElementRef, OnDestroy, OnInit, ViewChild, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, switchMap, of } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { DizimosService } from '../../core/dizimos.service';
import { PeopleService } from '../../core/people.service';
import { ColetaDizimo, LancamentoDizimo, Person } from '../../core/models';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';

@Component({
  selector: 'app-coleta-lancamento',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './coleta-lancamento.html',
  styleUrl: './coleta-lancamento.scss',
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

  // Form de lançamento rápido
  searchTerm = '';
  selectedPerson: Person | null = null;
  amount: number | null = null;
  contributionType = 'envelope';
  isUnidentified = false;
  notes = '';

  // Aviso de Duplicidade
  showDuplicateModal = signal<boolean>(false);
  duplicateMessage = '';

  // Modal Fechamento / Motivo Reabertura
  showCloseModal = signal<boolean>(false);
  showReopenModal = signal<boolean>(false);
  reopenReason = '';

  /** Subject para debounce do autocomplete server-side */
  private searchSubject = new Subject<string>();

  constructor() {
    // Autocomplete server-side com debounce de 300ms
    this.searchSubject.pipe(
      debounceTime(300),
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
      takeUntilDestroyed(),
    ).subscribe(async (term) => {
      if (!term) return;
      try {
        const res = await this.peopleService.list({ search: term, is_active: true, per_page: 10 });
        this.filteredTithers.set(res.data);

        // Pré-selecionar se houver exato match de envelope ou único resultado
        const exactEnvelope = res.data.find((p) => p.envelope_number?.toLowerCase() === term.toLowerCase().trim());
        if (exactEnvelope) {
          this.selectPerson(exactEnvelope);
        } else if (res.data.length === 1 && term.trim().length >= 3) {
          this.selectPerson(res.data[0]);
        }
      } catch {
        // Silencia erros de autocomplete para não poluir a UI durante digitação
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
        this.loading.set(false);
        setTimeout(() => this.focusSearch(), 100);
      },
      error: () => {
        this.toast.error('Erro ao carregar dados da coleta.');
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
    this.searchTerm = `${p.full_name}${p.envelope_number ? ' (Env. ' + p.envelope_number + ')' : ''}`;
    this.filteredTithers.set([]);
    setTimeout(() => this.amountInput?.nativeElement?.focus(), 50);
  }

  submitLancamento(force = false): void {
    if (this.saving()) return;

    if (!this.isUnidentified && !this.selectedPerson) {
      this.toast.warning('Por favor, selecione um membro dizimista ou marque a opção "Contribuição não identificada".');
      return;
    }

    if (!this.amount || this.amount <= 0) {
      this.toast.warning('Por favor, informe um valor válido para a contribuição.');
      return;
    }

    this.saving.set(true);

    this.dizimosService
      .addLancamento(this.coletaId, {
        person_id: this.isUnidentified ? null : this.selectedPerson?.id,
        amount: this.amount,
        contribution_type: this.contributionType,
        is_unidentified: this.isUnidentified,
        notes: this.notes,
        force,
      })
      .subscribe({
        next: (res) => {
          this.saving.set(false);

          if (res.duplicate) {
            this.duplicateMessage = res.message || 'Lançamento duplicado identificado.';
            this.showDuplicateModal.set(true);
            return;
          }

          this.showDuplicateModal.set(false);
          this.resetFormAndRefocus();
          this.loadColetaDetails();
        },
        error: (err) => {
          this.saving.set(false);
          this.toast.error(err.error?.message || 'Erro ao realizar lançamento.');
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
    this.notes = '';
    this.isUnidentified = false;
    this.filteredTithers.set([]);
    this.focusSearch();
  }

  focusSearch(): void {
    if (this.searchInput?.nativeElement) {
      this.searchInput.nativeElement.focus();
    }
  }

  closeColeta(): void {
    this.dizimosService.closeColeta(this.coletaId).subscribe({
      next: () => {
        this.showCloseModal.set(false);
        this.loadColetaDetails();
        this.toast.success('Coleta fechada com sucesso.');
      },
      error: (err) => this.toast.error(err.error?.message || 'Erro ao fechar coleta.'),
    });
  }

  reopenColeta(): void {
    if (!this.reopenReason.trim()) return;
    this.dizimosService.reopenColeta(this.coletaId, this.reopenReason).subscribe({
      next: () => {
        this.showReopenModal.set(false);
        this.reopenReason = '';
        this.loadColetaDetails();
        this.toast.success('Coleta reaberta para correção.');
      },
      error: (err) => this.toast.error(err.error?.message || 'Erro ao reabrir coleta.'),
    });
  }
}
