import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TagModule } from 'primeng/tag';
import { CheckboxModule } from 'primeng/checkbox';
import { TextareaModule } from 'primeng/textarea';
import { MessageModule } from 'primeng/message';
import { TooltipModule } from 'primeng/tooltip';
import { AuthService } from '../../core/auth.service';
import { PeopleService } from '../../core/people.service';
import { SecretariaService, FichaMinisterial } from '../../core/secretaria.service';
import { Person } from '../../core/models';

@Component({
  selector: 'app-people-list',
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    TableModule,
    DialogModule,
    InputTextModule,
    TagModule,
    CheckboxModule,
    TextareaModule,
    MessageModule,
    TooltipModule,
  ],
  templateUrl: './people-list.html',
})
export class PeopleListPage implements OnInit {
  private peopleSvc = inject(PeopleService);
  private secSvc = inject(SecretariaService);
  private auth = inject(AuthService);

  people = signal<Person[]>([]);
  total = signal(0);
  loading = signal(false);
  search = signal('');
  error = signal<string | null>(null);

  canManage = computed(() => this.auth.can('person.manage'));

  // Modal de criação/edição
  showForm = signal(false);
  editing = signal<Person | null>(null);
  form = signal<Partial<Person>>(this.emptyForm());
  saving = signal(false);

  // Modal de Dossiê Completo & Geração de PDF Oficial
  fichaDialog = signal(false);
  fichaLoading = signal(false);
  fichaData = signal<FichaMinisterial | null>(null);

  async ngOnInit() {
    await this.load();
  }

  emptyForm(): Partial<Person> {
    return { full_name: '', birth_date: null, is_active: true, can_teach: false, can_superintend: false, notes: '' };
  }

  async load() {
    this.loading.set(true);
    this.error.set(null);
    try {
      const res = await this.peopleSvc.list({ search: this.search() || undefined, per_page: 50 });
      this.people.set(res.data);
      this.total.set(res.meta.total);
    } catch {
      this.error.set('Não foi possível carregar as pessoas.');
    } finally {
      this.loading.set(false);
    }
  }

  openCreate() {
    this.editing.set(null);
    this.form.set(this.emptyForm());
    this.showForm.set(true);
  }

  openEdit(p: Person) {
    this.editing.set(p);
    this.form.set({ ...p });
    this.showForm.set(true);
  }

  closeForm() {
    this.showForm.set(false);
  }

  patch<K extends keyof Person>(key: K, value: Person[K]) {
    this.form.update((f) => ({ ...f, [key]: value }));
  }

  async save() {
    const data = this.form();
    if (!data.full_name?.trim()) { this.error.set('Informe o nome completo.'); return; }
    this.saving.set(true);
    this.error.set(null);
    try {
      const payload: Partial<Person> = {
        full_name: data.full_name,
        birth_date: data.birth_date || null,
        is_active: !!data.is_active,
        can_teach: !!data.can_teach,
        can_superintend: !!data.can_superintend,
        notes: data.notes || null,
      };
      if (this.editing()) {
        await this.peopleSvc.update(this.editing()!.id, payload);
      } else {
        await this.peopleSvc.create(payload);
      }
      this.showForm.set(false);
      await this.load();
    } catch (e: any) {
      this.error.set(e?.error?.message || 'Erro ao salvar.');
    } finally {
      this.saving.set(false);
    }
  }

  async remove(p: Person) {
    if (!confirm(`Inativar ${p.full_name}?`)) return;
    try {
      await this.peopleSvc.remove(p.id);
      await this.load();
    } catch {
      this.error.set('Erro ao inativar.');
    }
  }

  abrirFicha(p: Person): void {
    this.fichaDialog.set(true);
    this.fichaLoading.set(true);
    this.secSvc.getFichaMinisterial(p.id).subscribe({
      next: (data) => {
        this.fichaData.set(data);
        this.fichaLoading.set(false);
      },
      error: () => {
        this.fichaLoading.set(false);
        this.error.set('Não foi possível carregar a ficha completa do membro.');
      },
    });
  }

  imprimirFicha(): void {
    window.print();
  }

  abrirEdicaoDeFicha(): void {
    const data = this.fichaData();
    const membro = data?.membro || data?.person;
    if (membro) {
      this.fichaDialog.set(false);
      this.openEdit(membro as unknown as Person);
    }
  }

  getIniciais(nome?: string): string {
    if (!nome) return 'MB';
    const parts = nome.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  abrirWhatsApp(telefone?: string): void {
    if (!telefone) return;
    const num = telefone.replace(/\D/g, '');
    if (num) {
      window.open(`https://wa.me/55${num}`, '_blank');
    }
  }

  getStatusBadge(st?: string): { label: string; severity: 'success' | 'info' | 'warn' | 'danger' | 'secondary' } {
    switch (st) {
      case 'comungante':
        return { label: 'Comungante', severity: 'success' };
      case 'nao_comungante':
        return { label: 'Não-comungante', severity: 'info' };
      case 'sob_disciplina':
        return { label: 'Sob Disciplina', severity: 'danger' };
      case 'jurisdicao_especial':
        return { label: 'Jurisdição Especial', severity: 'warn' };
      case 'falecido':
        return { label: 'Falecido', severity: 'secondary' };
      default:
        return { label: st || 'Comungante', severity: 'secondary' };
    }
  }

  getModoRecepcaoLabel(tp?: string): string {
    switch (tp) {
      case 'profissao_fe_batismo':
        return 'Profissão de Fé e Batismo';
      case 'profissao_fe':
        return 'Profissão de Fé';
      case 'transferencia':
        return 'Carta de Transferência';
      case 'batismo_infantil':
        return 'Batismo Infantil';
      case 'jurisdicao':
        return 'Jurisdição do Conselho';
      default:
        return tp || 'Não informado';
    }
  }
}
