import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Institution, InstitutionBreadcrumb, InstitutionLinkRequest, InstitutionSubordinateSummary } from '../../core/models';
import { InstitutionService } from '../../core/institution.service';
import { InstitutionBreadcrumbComponent } from '../../layout/institution-breadcrumb';
import { InstitutionContextService } from '../../core/institution-context.service';

@Component({
  selector: 'app-institution-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterLink, InstitutionBreadcrumbComponent],
  templateUrl: './institution-detail.html',
  styleUrl: './institution-detail.scss',
})
export class InstitutionDetailPage implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private fb = inject(FormBuilder);
  private instService = inject(InstitutionService);
  private contextService = inject(InstitutionContextService);

  isNew = signal<boolean>(false);
  institutionId = signal<number | null>(null);
  activeTab = signal<'general' | 'subordinates' | 'link_requests' | 'transfer'>('general');

  institutionData = signal<Institution | null>(null);
  subordinatesList = signal<InstitutionSubordinateSummary[]>([]);
  historyList = signal<any[]>([]);
  parentOptions = signal<Institution[]>([]);

  // Vínculos & Solicitações por Código
  receivedLinkRequests = signal<InstitutionLinkRequest[]>([]);
  sentLinkRequests = signal<InstitutionLinkRequest[]>([]);
  lookupCodeInput = signal<string>('');
  targetLookupResult = signal<Institution | null>(null);
  lookupError = signal<string | null>(null);
  lookupLoading = signal<boolean>(false);
  linkType = signal<'vinculo_superior' | 'vinculo_inferior'>('vinculo_superior');
  linkReason = signal<string>('');
  submittingLinkRequest = signal<boolean>(false);
  copiedCode = signal<boolean>(false);

  loading = signal<boolean>(true);
  saving = signal<boolean>(false);
  successMsg = signal<string | null>(null);
  errorMsg = signal<string | null>(null);

  form = this.fb.group({
    name: ['', [Validators.required, Validators.maxLength(200)]],
    short_name: ['', [Validators.required, Validators.maxLength(100)]],
    type: ['igreja', [Validators.required]],
    code: [{ value: '', disabled: true }],
    cnpj: [''],
    foundation_date: [''],
    organization_date: [''],
    status: ['ativa', [Validators.required]],
    parent_institution_id: [null as number | null],
    zipcode: [''],
    street: [''],
    number: [''],
    complement: [''],
    district: [''],
    city: [''],
    state: [''],
    phone: [''],
    whatsapp: [''],
    email: [''],
    website: [''],
    share_financials_with_parent: [false],
    notes: [''],
  });

  transferForm = this.fb.group({
    new_parent_id: [null as number | null],
    reason: ['', [Validators.required, Validators.minLength(5)]],
  });

  ngOnInit(): void {
    this.loadParentOptions();

    this.route.params.subscribe((params) => {
      if (params['id'] === 'nova') {
        this.isNew.set(true);
        this.loading.set(false);

        // Se query parameter 'parent_id' for fornecido (+ Nova Subordinada)
        const parentIdParam = this.route.snapshot.queryParamMap.get('parent_id');
        if (parentIdParam) {
          this.form.patchValue({ parent_institution_id: Number(parentIdParam) });
        }
      } else {
        const id = Number(params['id']);
        this.institutionId.set(id);
        this.loadInstitution(id);
      }
    });

    // Se houver query param tab=link_requests
    const tabParam = this.route.snapshot.queryParamMap.get('tab');
    if (tabParam === 'link_requests') {
      this.activeTab.set('link_requests');
    }
  }

  private loadParentOptions(): void {
    this.instService.list({ per_page: 100 }).subscribe({
      next: (res) => this.parentOptions.set(res.data),
    });
  }

  loadInstitution(id: number): void {
    this.loading.set(true);
    this.instService.get(id).subscribe({
      next: (res) => {
        this.institutionData.set(res.data);
        this.form.patchValue(res.data as any);
        this.loading.set(false);
        this.loadSubordinates(id);
        this.loadHistory(id);
        this.loadLinkRequests(id);
      },
      error: (err) => {
        this.errorMsg.set(err.error?.message || 'Erro ao carregar instituição.');
        this.loading.set(false);
      },
    });
  }

  loadSubordinates(id: number): void {
    this.instService.getSubordinates(id).subscribe({
      next: (res) => this.subordinatesList.set(res.subordinates),
    });
  }

  loadHistory(id: number): void {
    this.instService.getHistory(id).subscribe({
      next: (res) => this.historyList.set(res.data),
    });
  }

  loadLinkRequests(id: number): void {
    this.instService.getLinkRequests(id).subscribe({
      next: (res) => {
        this.receivedLinkRequests.set(res.received);
        this.sentLinkRequests.set(res.sent);
      },
    });
  }

  copyCode(code?: string): void {
    if (!code) return;
    navigator.clipboard.writeText(code);
    this.copiedCode.set(true);
    setTimeout(() => this.copiedCode.set(false), 2500);
  }

  onLookupCode(): void {
    const code = this.lookupCodeInput().trim();
    if (!code) return;

    this.lookupLoading.set(true);
    this.lookupError.set(null);
    this.targetLookupResult.set(null);

    this.instService.getByCode(code).subscribe({
      next: (res) => {
        this.targetLookupResult.set(res.data);
        this.lookupLoading.set(false);
      },
      error: (err) => {
        this.lookupError.set(err.error?.message || 'Instituição não encontrada com este código.');
        this.lookupLoading.set(false);
      },
    });
  }

  sendLinkRequest(): void {
    const target = this.targetLookupResult();
    if (!target || !target.code) return;

    this.submittingLinkRequest.set(true);
    this.errorMsg.set(null);
    this.successMsg.set(null);

    this.instService.createLinkRequest({
      requester_institution_id: this.institutionId()!,
      target_code: target.code,
      type: this.linkType(),
      reason: this.linkReason(),
    }).subscribe({
      next: (res) => {
        this.submittingLinkRequest.set(false);
        this.successMsg.set(res.message);
        this.targetLookupResult.set(null);
        this.lookupCodeInput.set('');
        this.linkReason.set('');
        this.loadLinkRequests(this.institutionId()!);
      },
      error: (err) => {
        this.errorMsg.set(err.error?.message || 'Erro ao enviar solicitação.');
        this.submittingLinkRequest.set(false);
      },
    });
  }

  confirmLinkSubordinate(): void {
    const target = this.targetLookupResult();
    if (!target || !target.code || !this.institutionId()) return;

    this.submittingLinkRequest.set(true);
    this.errorMsg.set(null);
    this.successMsg.set(null);
    this.lookupError.set(null);

    this.instService.createLinkRequest({
      requester_institution_id: this.institutionId()!,
      target_code: target.code,
      type: 'vinculo_inferior',
      reason: 'Solicitação de vínculo de instituição subordinada por código.',
    }).subscribe({
      next: (res) => {
        this.submittingLinkRequest.set(false);
        this.successMsg.set(res.message || 'Solicitação de vínculo enviada com sucesso! Aguardando aprovação da instituição subordinada.');
        this.targetLookupResult.set(null);
        this.lookupCodeInput.set('');
        this.loadLinkRequests(this.institutionId()!);
      },
      error: (err) => {
        this.lookupError.set(err.error?.message || 'Erro ao enviar solicitação de vínculo.');
        this.submittingLinkRequest.set(false);
      },
    });
  }

  requestUnlink(targetCode?: string, targetName?: string): void {
    if (!targetCode || !this.institutionId()) return;

    const confirmMsg = `Deseja enviar uma solicitação de desvinculação da instituição "${targetName}"? A desvinculação dependerá da aprovação dela.`;
    if (!confirm(confirmMsg)) return;

    this.submittingLinkRequest.set(true);
    this.errorMsg.set(null);
    this.successMsg.set(null);

    this.instService.createLinkRequest({
      requester_institution_id: this.institutionId()!,
      target_code: targetCode,
      type: 'desvinculo',
      reason: 'Solicitação de remoção de vínculo iniciada pelo usuário.',
    }).subscribe({
      next: (res) => {
        this.submittingLinkRequest.set(false);
        this.successMsg.set(res.message);
        this.loadLinkRequests(this.institutionId()!);
      },
      error: (err) => {
        this.errorMsg.set(err.error?.message || 'Erro ao solicitar desvinculação.');
        this.submittingLinkRequest.set(false);
      },
    });
  }

  acceptRequest(reqId: number): void {
    this.errorMsg.set(null);
    this.successMsg.set(null);

    this.instService.acceptLinkRequest(reqId).subscribe({
      next: (res) => {
        this.successMsg.set(res.message);
        this.loadInstitution(this.institutionId()!);
      },
      error: (err) => {
        this.errorMsg.set(err.error?.message || 'Erro ao aceitar solicitação.');
      },
    });
  }

  rejectRequest(reqId: number): void {
    this.errorMsg.set(null);
    this.successMsg.set(null);

    this.instService.rejectLinkRequest(reqId).subscribe({
      next: (res) => {
        this.successMsg.set(res.message);
        this.loadLinkRequests(this.institutionId()!);
      },
      error: (err) => {
        this.errorMsg.set(err.error?.message || 'Erro ao recusar solicitação.');
      },
    });
  }

  cancelRequest(reqId: number): void {
    this.errorMsg.set(null);
    this.successMsg.set(null);

    this.instService.cancelLinkRequest(reqId).subscribe({
      next: (res) => {
        this.successMsg.set(res.message);
        this.loadLinkRequests(this.institutionId()!);
      },
      error: (err) => {
        this.errorMsg.set(err.error?.message || 'Erro ao cancelar solicitação.');
      },
    });
  }

  save(): void {
    if (this.form.invalid) return;

    this.saving.set(true);
    this.errorMsg.set(null);
    this.successMsg.set(null);

    const data = this.form.value as Partial<Institution>;

    if (this.isNew()) {
      this.instService.create(data).subscribe({
        next: (res) => {
          this.saving.set(false);
          this.router.navigate(['/instituicoes', res.data.id]);
        },
        error: (err) => {
          this.errorMsg.set(err.error?.message || 'Erro ao cadastrar.');
          this.saving.set(false);
        },
      });
    } else {
      this.instService.update(this.institutionId()!, data).subscribe({
        next: (res) => {
          this.saving.set(false);
          this.successMsg.set('Dados atualizados com sucesso.');
          this.institutionData.set(res.data);
        },
        error: (err) => {
          this.errorMsg.set(err.error?.message || 'Erro ao atualizar.');
          this.saving.set(false);
        },
      });
    }
  }

  submitTransfer(): void {
    if (this.transferForm.invalid || !this.institutionId()) return;

    const val = this.transferForm.value;
    this.saving.set(true);

    this.instService.transfer(this.institutionId()!, val.new_parent_id ?? null, val.reason!).subscribe({
      next: (res) => {
        this.saving.set(false);
        this.successMsg.set('Vínculo transferido com sucesso.');
        this.institutionData.set(res.data);
        this.loadHistory(this.institutionId()!);
        this.transferForm.reset();
      },
      error: (err) => {
        this.errorMsg.set(err.error?.message || 'Erro ao transferir.');
        this.saving.set(false);
      },
    });
  }

  switchToContext(): void {
    if (this.institutionData()) {
      this.contextService.switchContext(this.institutionData()!);
      this.router.navigate(['/dashboard']);
    }
  }

  formatType(type: string): string {
    const map: Record<string, string> = {
      supremo_concilio: 'Supremo Concílio',
      sinodo: 'Sínodo',
      presbiterio: 'Presbitério',
      igreja: 'Igreja',
      congregacao: 'Congregação',
    };
    return map[type] || type;
  }
}

