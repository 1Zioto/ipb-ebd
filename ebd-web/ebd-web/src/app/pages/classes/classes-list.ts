import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { CheckboxModule } from 'primeng/checkbox';
import { TagModule } from 'primeng/tag';
import { MessageModule } from 'primeng/message';
import { AuthService } from '../../core/auth.service';
import { ClassesService } from '../../core/classes.service';
import { ClassRoom } from '../../core/models';

@Component({
  selector: 'app-classes-list',
  imports: [FormsModule, RouterLink, ButtonModule, TableModule, DialogModule, InputTextModule, TextareaModule, CheckboxModule, TagModule, MessageModule],
  templateUrl: './classes-list.html',
})
export class ClassesListPage implements OnInit {
  private svc = inject(ClassesService);
  private auth = inject(AuthService);

  classes = signal<ClassRoom[]>([]);
  loading = signal(false);
  error = signal<string | null>(null);
  canManage = computed(() => this.auth.can('class.manage'));

  showForm = signal(false);
  editing = signal<ClassRoom | null>(null);
  form = signal<Partial<ClassRoom>>(this.empty());
  saving = signal(false);

  async ngOnInit() { await this.load(); }

  empty(): Partial<ClassRoom> {
    return { name: '', description: '', age_range: '', display_order: 0, is_active: true };
  }

  async load() {
    this.loading.set(true);
    try { this.classes.set((await this.svc.list()).data); }
    catch { this.error.set('Erro ao carregar classes.'); }
    finally { this.loading.set(false); }
  }

  openCreate() { this.editing.set(null); this.form.set(this.empty()); this.showForm.set(true); }
  openEdit(c: ClassRoom) { this.editing.set(c); this.form.set({ ...c }); this.showForm.set(true); }
  close() { this.showForm.set(false); }
  patch<K extends keyof ClassRoom>(k: K, v: ClassRoom[K]) { this.form.update(f => ({ ...f, [k]: v })); }

  async save() {
    const d = this.form();
    if (!d.name?.trim()) { this.error.set('Informe o nome.'); return; }
    this.saving.set(true); this.error.set(null);
    try {
      const payload = {
        name: d.name, description: d.description || null, age_range: d.age_range || null,
        display_order: Number(d.display_order) || 0, is_active: !!d.is_active,
      };
      if (this.editing()) await this.svc.update(this.editing()!.id, payload);
      else await this.svc.create(payload);
      this.showForm.set(false);
      await this.load();
    } catch (e: any) { this.error.set(e?.error?.message || 'Erro ao salvar.'); }
    finally { this.saving.set(false); }
  }

  async remove(c: ClassRoom) {
    if (!confirm(`Inativar a classe ${c.name}?`)) return;
    try { await this.svc.remove(c.id); await this.load(); }
    catch { this.error.set('Erro ao inativar.'); }
  }
}
