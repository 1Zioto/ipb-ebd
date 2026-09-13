import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../core/auth.service';
import { PeopleService } from '../../core/people.service';
import { Person } from '../../core/models';

@Component({
  selector: 'app-people-list',
  imports: [FormsModule],
  templateUrl: './people-list.html',
  styleUrl: './people-list.scss',
})
export class PeopleListPage implements OnInit {
  private peopleSvc = inject(PeopleService);
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
}
