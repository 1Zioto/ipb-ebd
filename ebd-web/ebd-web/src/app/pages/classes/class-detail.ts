import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { AuthService } from '../../core/auth.service';
import { ClassCallSession, ClassesService } from '../../core/classes.service';
import { PeopleService } from '../../core/people.service';
import { ClassRoom, ClassTeacher, Enrollment, Person } from '../../core/models';

@Component({
  selector: 'app-class-detail',
  imports: [FormsModule, RouterLink],
  templateUrl: './class-detail.html',
  styleUrl: './classes.scss',
})
export class ClassDetailPage implements OnInit {
  private route = inject(ActivatedRoute);
  private svc = inject(ClassesService);
  private peopleSvc = inject(PeopleService);
  private auth = inject(AuthService);

  classId = 0;
  classInfo = signal<ClassRoom | null>(null);
  tab = signal<'alunos' | 'professores' | 'chamadas'>('alunos');

  students = signal<Enrollment[]>([]);
  teachers = signal<ClassTeacher[]>([]);
  sessions = signal<ClassCallSession[]>([]);
  loadingSessions = signal(false);
  allPeople = signal<Person[]>([]);
  teacherPeople = signal<Person[]>([]);

  studentSearch = signal('');
  selectedStudentIds = signal<Set<number>>(new Set());
  enrolling = signal(false);
  selectedTeacherId = signal<number | null>(null);
  error = signal<string | null>(null);

  canEnroll = computed(() => this.auth.can('enrollment.manage'));
  canManage = computed(() => this.auth.can('class.manage'));
  canViewCalls = computed(() => this.auth.can('call.view'));

  // Pessoas ainda não matriculadas (para o seletor)
  availableStudents = computed(() => {
    const enrolledIds = new Set(this.students().map(s => s.person_id));
    const term = this.studentSearch().trim().toLocaleLowerCase('pt-BR');
    return this.allPeople().filter(p =>
      p.is_active &&
      !enrolledIds.has(p.id) &&
      (!term || p.full_name.toLocaleLowerCase('pt-BR').includes(term))
    );
  });
  availableTeachers = computed(() => {
    const ids = new Set(this.teachers().map(t => t.person_id));
    return this.teacherPeople().filter(p => !ids.has(p.id));
  });

  async ngOnInit() {
    this.classId = Number(this.route.snapshot.paramMap.get('id'));
    await Promise.all([
      this.loadClass(), this.loadStudents(), this.loadTeachers(), this.loadPeople(),
      this.canViewCalls() ? this.loadSessions() : Promise.resolve(),
    ]);
  }

  async loadClass() { this.classInfo.set((await this.svc.get(this.classId)).data); }
  async loadStudents() { this.students.set((await this.svc.students(this.classId)).data); }
  async loadTeachers() { this.teachers.set((await this.svc.teachers(this.classId)).data); }
  async loadSessions() {
    this.loadingSessions.set(true);
    try { this.sessions.set((await this.svc.sessions(this.classId)).data); }
    catch { this.error.set('Não foi possível carregar as chamadas desta classe.'); }
    finally { this.loadingSessions.set(false); }
  }

  formatDate(value: string | null): string {
    if (!value) return 'Data não informada';
    return new Intl.DateTimeFormat('pt-BR', { timeZone: 'UTC' }).format(new Date(`${value}T00:00:00Z`));
  }

  statusLabel(status: string): string {
    return ({
      pendente: 'Pendente', em_andamento: 'Em andamento', finalizada: 'Finalizada',
      cancelada: 'Cancelada', classe_unificada: 'Classe unificada',
      nao_realizada: 'Não realizada', evento_especial: 'Evento especial',
    } as Record<string, string>)[status] || status;
  }
  async loadPeople() {
    this.allPeople.set((await this.peopleSvc.list({ is_active: true, per_page: 500 })).data);
    this.teacherPeople.set((await this.peopleSvc.list({ can_teach: true, per_page: 500 })).data);
  }

  isStudentSelected(id: number): boolean {
    return this.selectedStudentIds().has(id);
  }

  toggleStudent(id: number, checked: boolean): void {
    const selected = new Set(this.selectedStudentIds());
    checked ? selected.add(id) : selected.delete(id);
    this.selectedStudentIds.set(selected);
  }

  toggleAllVisible(checked: boolean): void {
    const selected = new Set(this.selectedStudentIds());
    for (const person of this.availableStudents()) {
      checked ? selected.add(person.id) : selected.delete(person.id);
    }
    this.selectedStudentIds.set(selected);
  }

  allVisibleSelected(): boolean {
    const visible = this.availableStudents();
    return visible.length > 0 && visible.every(person => this.isStudentSelected(person.id));
  }

  async enrollSelected() {
    const ids = [...this.selectedStudentIds()];
    if (ids.length === 0 || this.enrolling()) return;
    this.error.set(null);
    this.enrolling.set(true);
    try {
      for (const id of ids) await this.svc.enroll(this.classId, id);
      this.selectedStudentIds.set(new Set());
      this.studentSearch.set('');
      await this.loadStudents();
    } catch (e: any) {
      await this.loadStudents();
      this.error.set(e?.error?.message || 'Algumas matrículas não puderam ser concluídas.');
    } finally {
      this.enrolling.set(false);
    }
  }
  async unenroll(e: Enrollment) {
    if (!confirm(`Encerrar matrícula de ${e.person_name}?`)) return;
    try { await this.svc.unenroll(this.classId, e.person_id); await this.loadStudents(); }
    catch { this.error.set('Erro ao encerrar matrícula.'); }
  }
  async addTeacher() {
    const id = this.selectedTeacherId();
    if (!id) return;
    this.error.set(null);
    try { await this.svc.addTeacher(this.classId, id); this.selectedTeacherId.set(null); await this.loadTeachers(); }
    catch (e: any) { this.error.set(e?.error?.message || 'Erro ao adicionar professor.'); }
  }
  async removeTeacher(t: ClassTeacher) {
    if (!confirm(`Remover ${t.person_name} dos professores?`)) return;
    try { await this.svc.removeTeacher(this.classId, t.person_id); await this.loadTeachers(); }
    catch { this.error.set('Erro ao remover professor.'); }
  }
}
