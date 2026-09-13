import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../core/auth.service';
import { FamiliesService } from '../../core/families.service';
import { PeopleService } from '../../core/people.service';
import { Family, FamilyMember, FamilyRelationship, Person } from '../../core/models';

type MemberDraft = Pick<FamilyMember, 'id' | 'full_name' | 'birth_date' | 'age' | 'is_active' | 'relationship' | 'is_head'>;

@Component({
  selector: 'app-families-list',
  imports: [FormsModule],
  templateUrl: './families-list.html',
  styleUrl: './families-list.scss',
})
export class FamiliesListPage implements OnInit {
  private familiesSvc = inject(FamiliesService);
  private peopleSvc = inject(PeopleService);
  private auth = inject(AuthService);

  families = signal<Family[]>([]);
  people = signal<Person[]>([]);
  loading = signal(false);
  saving = signal(false);
  search = '';
  personSearch = '';
  error = signal<string | null>(null);
  showForm = signal(false);
  editing = signal<Family | null>(null);
  form = signal<Partial<Family>>(this.emptyForm());
  members = signal<MemberDraft[]>([]);
  canManage = computed(() => this.auth.can('family.manage'));

  relationships: { value: FamilyRelationship; label: string }[] = [
    { value: 'responsavel', label: 'Responsável' }, { value: 'conjuge', label: 'Cônjuge' },
    { value: 'filho', label: 'Filho' }, { value: 'filha', label: 'Filha' },
    { value: 'dependente', label: 'Dependente' }, { value: 'outro', label: 'Outro' },
  ];

  async ngOnInit() { await Promise.all([this.load(), this.loadPeople()]); }

  emptyForm(): Partial<Family> { return { name: '', is_active: true, state: '', notes: '' }; }

  async load() {
    this.loading.set(true); this.error.set(null);
    try { this.families.set((await this.familiesSvc.list(this.search)).data); }
    catch { this.error.set('Não foi possível carregar as famílias.'); }
    finally { this.loading.set(false); }
  }

  async loadPeople() {
    try { this.people.set((await this.peopleSvc.list({ is_active: true, per_page: 500 })).data); } catch { /* lista continua vazia */ }
  }

  availablePeople(): Person[] {
    const selected = new Set(this.members().map(m => m.id));
    const term = this.personSearch.trim().toLocaleLowerCase('pt-BR');
    return this.people().filter(p => !selected.has(p.id) && (!term || p.full_name.toLocaleLowerCase('pt-BR').includes(term))).slice(0, 8);
  }

  openCreate() { this.editing.set(null); this.form.set(this.emptyForm()); this.members.set([]); this.personSearch = ''; this.showForm.set(true); }
  openEdit(family: Family) { this.editing.set(family); this.form.set({ ...family }); this.members.set((family.members || []).map(m => ({ ...m }))); this.personSearch = ''; this.showForm.set(true); }
  closeForm() { this.showForm.set(false); }
  patch(key: keyof Family, value: unknown) { this.form.update(f => ({ ...f, [key]: value })); }

  addMember(person: Person) {
    this.members.update(items => [...items, { id: person.id, full_name: person.full_name, birth_date: person.birth_date, age: person.age, is_active: person.is_active, relationship: items.length ? 'outro' : 'responsavel', is_head: items.length === 0 }]);
    this.personSearch = '';
  }

  removeMember(id: number) { this.members.update(items => items.filter(m => m.id !== id)); }
  setRelationship(id: number, relationship: FamilyRelationship) { this.members.update(items => items.map(m => m.id === id ? { ...m, relationship } : m)); }
  setHead(id: number) { this.members.update(items => items.map(m => ({ ...m, is_head: m.id === id, relationship: m.id === id && m.relationship === 'outro' ? 'responsavel' : m.relationship }))); }

  async save() {
    if (!this.form().name?.trim()) { this.error.set('Informe o nome da família.'); return; }
    this.saving.set(true); this.error.set(null);
    const payload: Omit<Partial<Family>, 'members'> & { members: { person_id: number; relationship: FamilyRelationship; is_head: boolean }[] } = {
      ...this.form(), name: this.form().name!.trim(), state: this.form().state?.toUpperCase() || null,
      members: this.members().map(m => ({ person_id: m.id, relationship: m.relationship, is_head: m.is_head })),
    };
    try {
      if (this.editing()) await this.familiesSvc.update(this.editing()!.id, payload);
      else await this.familiesSvc.create(payload);
      this.showForm.set(false); await this.load();
    } catch (e: any) { this.error.set(e?.error?.message || 'Erro ao salvar a família.'); }
    finally { this.saving.set(false); }
  }

  async remove(family: Family) {
    if (!confirm(`Inativar a família ${family.name}? Os cadastros das pessoas serão preservados.`)) return;
    try { await this.familiesSvc.remove(family.id); await this.load(); } catch { this.error.set('Erro ao inativar a família.'); }
  }

  address(family: Family): string {
    return [family.street, family.number, family.district, family.city, family.state].filter(Boolean).join(', ');
  }
}
