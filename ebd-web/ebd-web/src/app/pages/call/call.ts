import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { AuthService } from '../../core/auth.service';
import { CallService } from '../../core/call.service';
import { ClassesService } from '../../core/classes.service';
import { AttendanceRecord, ClassTeacher, EbdSession } from '../../core/models';

@Component({
  selector: 'app-call',
  imports: [FormsModule, RouterLink],
  templateUrl: './call.html',
  styleUrl: './call.scss',
})
export class CallPage implements OnInit {
  private route = inject(ActivatedRoute);
  private svc = inject(CallService);
  private classesSvc = inject(ClassesService);
  private auth = inject(AuthService);

  sessionId = 0;
  session = signal<EbdSession | null>(null);
  records = signal<AttendanceRecord[]>([]);
  teachers = signal<ClassTeacher[]>([]);
  loading = signal(true);
  saving = signal(false);
  error = signal<string | null>(null);
  savedAt = signal<string | null>(null);

  materialMode = signal<'individual' | 'agregado'>('individual');
  biblesAgg = signal<number>(0);
  magazinesAgg = signal<number>(0);
  teacherId = signal<number | null>(null);

  canFinalize = computed(() => this.auth.can('call.finalize'));
  canReopen = computed(() => this.auth.can('call.reopen'));
  isFinalized = computed(() => this.session()?.status === 'finalizada');
  readOnly = computed(() => this.isFinalized() && !this.canReopen());

  presentCount = computed(() => this.records().filter(r => r.present).length);
  biblesCount = computed(() => this.records().filter(r => r.brought_bible).length);
  magazinesCount = computed(() => this.records().filter(r => r.brought_magazine).length);

  async ngOnInit() {
    this.sessionId = Number(this.route.snapshot.paramMap.get('id'));
    try {
      // abre (idempotente) e já traz a lista de alunos
      const r = await this.svc.open(this.sessionId);
      this.applyResponse(r.session, r.records);
      const t = await this.classesSvc.teachers(r.session.class_id);
      this.teachers.set(t.data);
    } catch (e: any) {
      // se já finalizada, open retorna 409 — carrega em modo leitura
      try {
        const r = await this.svc.records(this.sessionId);
        this.applyResponse(r.session, r.records);
        const t = await this.classesSvc.teachers(r.session.class_id);
        this.teachers.set(t.data);
      } catch { this.error.set('Não foi possível carregar a chamada.'); }
    } finally {
      this.loading.set(false);
    }
  }

  private applyResponse(session: EbdSession, records: AttendanceRecord[]) {
    this.session.set(session);
    this.records.set(records);
    this.materialMode.set((session.material_mode as any) || 'individual');
    this.biblesAgg.set(session.bibles_total ?? 0);
    this.magazinesAgg.set(session.magazines_total ?? 0);
    this.teacherId.set(session.teacher_person_id);
  }

  togglePresent(r: AttendanceRecord) {
    if (this.readOnly()) return;
    this.records.update(list => list.map(x => x.person_id === r.person_id ? { ...x, present: !x.present } : x));
  }
  toggleBible(r: AttendanceRecord, ev: Event) {
    ev.stopPropagation();
    if (this.readOnly()) return;
    this.records.update(list => list.map(x => x.person_id === r.person_id ? { ...x, brought_bible: !x.brought_bible } : x));
  }
  toggleMagazine(r: AttendanceRecord, ev: Event) {
    ev.stopPropagation();
    if (this.readOnly()) return;
    this.records.update(list => list.map(x => x.person_id === r.person_id ? { ...x, brought_magazine: !x.brought_magazine } : x));
  }

  async save() {
    this.saving.set(true); this.error.set(null);
    try {
      // materiais
      if (this.materialMode() === 'agregado') {
        await this.svc.setMaterials(this.sessionId, { material_mode: 'agregado', bibles_total: Number(this.biblesAgg()), magazines_total: Number(this.magazinesAgg()) });
      } else {
        await this.svc.setMaterials(this.sessionId, { material_mode: 'individual' });
      }
      // professor
      await this.svc.setTeacher(this.sessionId, this.teacherId());
      // presenças
      const payload = this.records().map(r => ({
        person_id: r.person_id, present: r.present,
        brought_bible: this.materialMode() === 'individual' ? !!r.brought_bible : null,
        brought_magazine: this.materialMode() === 'individual' ? !!r.brought_magazine : null,
      }));
      const r = await this.svc.saveAttendance(this.sessionId, payload);
      this.applyResponse(r.session, r.records);
      this.savedAt.set(new Date().toLocaleTimeString('pt-BR'));
    } catch (e: any) { this.error.set(e?.error?.message || 'Erro ao salvar.'); }
    finally { this.saving.set(false); }
  }

  async finalize() {
    if (!confirm('Finalizar a chamada? Após finalizada, alterações exigem reabertura.')) return;
    this.saving.set(true); this.error.set(null);
    try {
      await this.save();
      const r = await this.svc.finalize(this.sessionId);
      this.session.set(r.session);
    } catch (e: any) { this.error.set(e?.error?.message || 'Erro ao finalizar.'); }
    finally { this.saving.set(false); }
  }

  async reopen() {
    try { const r = await this.svc.reopen(this.sessionId); this.session.set(r.data); }
    catch (e: any) { this.error.set(e?.error?.message || 'Erro ao reabrir.'); }
  }
}
