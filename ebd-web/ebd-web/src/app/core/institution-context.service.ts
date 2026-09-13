import { Injectable, computed, inject, signal } from '@angular/core';
import { AuthService } from './auth.service';
import { Institution } from './models';

const CONTEXT_KEY = 'ebd_active_institution_context';

@Injectable({ providedIn: 'root' })
export class InstitutionContextService {
  private auth = inject(AuthService);

  // Instituição sendo visualizada no momento (caso tenha trocado contexto)
  private _switchedInstitution = signal<Institution | null>(this.readStoredContext());

  readonly switchedInstitution = this._switchedInstitution.asReadonly();

  // Instituição original do usuário logado
  readonly originInstitution = computed(() => {
    const u = this.auth.user();
    return u?.institution ?? null;
  });

  // ID da instituição ativa (ou a trocada, ou a original)
  readonly activeInstitutionId = computed<number | null>(() => {
    const switched = this._switchedInstitution();
    if (switched) {
      return switched.id;
    }
    const u = this.auth.user();
    return u?.institution_id ?? null;
  });

  // Instituição ativa formatada para exibição
  readonly activeInstitution = computed<{ id: number; name: string; type: string } | null>(() => {
    const switched = this._switchedInstitution();
    if (switched) {
      return { id: switched.id, name: switched.name, type: switched.type };
    }
    const origin = this.originInstitution();
    if (origin) {
      return { id: origin.id, name: origin.name, type: origin.type };
    }
    return null;
  });

  // Flag se o contexto foi alterado em relação à instituição original
  readonly isContextSwitched = computed<boolean>(() => {
    const switched = this._switchedInstitution();
    const origin = this.originInstitution();
    if (!switched || !origin) return false;
    return switched.id !== origin.id;
  });

  private readStoredContext(): Institution | null {
    const raw = localStorage.getItem(CONTEXT_KEY);
    return raw ? (JSON.parse(raw) as Institution) : null;
  }

  /**
   * Troca o contexto ativo para uma instituição subordinada.
   */
  switchContext(inst: Institution): void {
    localStorage.setItem(CONTEXT_KEY, JSON.stringify(inst));
    this._switchedInstitution.set(inst);
  }

  /**
   * Restaura a visualização para a instituição original.
   */
  resetContext(): void {
    localStorage.removeItem(CONTEXT_KEY);
    this._switchedInstitution.set(null);
  }

  /**
   * Retorna o ID da instituição ativa para ser enviado no header X-Institution-Context.
   */
  getContextHeaderValue(): string | null {
    const id = this.activeInstitutionId();
    return id ? String(id) : null;
  }
}
