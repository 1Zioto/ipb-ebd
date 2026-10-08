import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { EbdService, ScheduleItem } from '../../core/ebd.service';
import { ClassesService } from '../../core/classes.service';
import { PeopleService } from '../../core/people.service';
import { ClassRoom, Person } from '../../core/models';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-schedules',
  standalone: true,
  imports: [CommonModule, FormsModule, ButtonModule, TableModule, DialogModule, InputTextModule, TagModule, TooltipModule],
  templateUrl: './schedules.html',
})
export class SchedulesPage implements OnInit {
  private ebdService = inject(EbdService);
  private classesService = inject(ClassesService);
  private peopleService = inject(PeopleService);
  auth = inject(AuthService);

  teacherSchedules = signal<ScheduleItem[]>([]);
  superSchedules = signal<ScheduleItem[]>([]);
  classes = signal<ClassRoom[]>([]);
  teachers = signal<Person[]>([]);
  superintendents = signal<Person[]>([]);
  loading = signal<boolean>(true);
  generatingFictional = signal<boolean>(false);
  successMessage = signal<string | null>(null);

  activeTab: 'teachers' | 'superintendents' = 'teachers';

  // Navegação de Mês/Ano
  selectedYear = signal<number>(2026);
  selectedMonth = signal<number>(10);
  selectedFilterClassId = signal<number | null>(null);

  // Form Escala Professor
  showTeacherModal = signal<boolean>(false);
  scheduleDate = new Date().toISOString().substring(0, 10);
  selectedClassId: number | null = null;
  selectedTeacherId: number | null = null;
  teacherNotes: string = '';

  // Form Escala Superintendente
  showSuperModal = signal<boolean>(false);
  selectedSuperId: number | null = null;
  superNotes: string = '';

  readonly monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  monthTitle = computed(() => {
    return `${this.monthNames[this.selectedMonth() - 1]} de ${this.selectedYear()}`;
  });

  filteredTeacherSchedules = computed(() => {
    const list = this.teacherSchedules();
    const classId = this.selectedFilterClassId();
    if (!classId) return list;
    return list.filter((item) => item.class_id === classId);
  });

  ngOnInit(): void {
    this.loadData();
    this.loadDropdowns();
  }

  loadData(): void {
    this.loading.set(true);
    const y = this.selectedYear();
    const m = this.selectedMonth();

    this.ebdService.getTeacherSchedules(y, m).subscribe({
      next: (res) => this.teacherSchedules.set(res),
      error: () => this.teacherSchedules.set([]),
    });

    this.ebdService.getSuperintendentSchedules(y, m).subscribe({
      next: (res) => {
        this.superSchedules.set(res);
        this.loading.set(false);
      },
      error: () => {
        this.superSchedules.set([]);
        this.loading.set(false);
      },
    });
  }

  async loadDropdowns(): Promise<void> {
    try {
      const [classes, teachers, superintendents] = await Promise.all([
        this.classesService.list(),
        this.peopleService.list({ can_teach: true, per_page: 100 }),
        this.peopleService.list({ can_superintend: true, per_page: 100 }),
      ]);
      this.classes.set(classes.data.filter((item) => item.is_active));
      this.teachers.set(teachers.data);
      this.superintendents.set(superintendents.data);
    } catch (e) {
      console.error('Erro ao carregar selects de escala:', e);
    }
  }

  prevMonth(): void {
    let m = this.selectedMonth() - 1;
    let y = this.selectedYear();
    if (m < 1) {
      m = 12;
      y--;
    }
    this.selectedMonth.set(m);
    this.selectedYear.set(y);
    this.loadData();
  }

  nextMonth(): void {
    let m = this.selectedMonth() + 1;
    let y = this.selectedYear();
    if (m > 12) {
      m = 1;
      y++;
    }
    this.selectedMonth.set(m);
    this.selectedYear.set(y);
    this.loadData();
  }

  setMonth(m: number): void {
    this.selectedMonth.set(m);
    this.loadData();
  }

  generateFictional(): void {
    this.generatingFictional.set(true);
    this.ebdService.seedFictionalSchedules().subscribe({
      next: (res) => {
        this.generatingFictional.set(false);
        this.successMessage.set(res.message || 'Escalas fictícias geradas com sucesso!');
        this.loadData();
        this.loadDropdowns();
        setTimeout(() => this.successMessage.set(null), 5000);
      },
      error: () => {
        this.generatingFictional.set(false);
        this.loadData();
      },
    });
  }

  openTeacherModal(): void {
    this.scheduleDate = new Date().toISOString().substring(0, 10);
    this.selectedClassId = this.classes().length > 0 ? this.classes()[0].id : null;
    this.selectedTeacherId = this.teachers().length > 0 ? this.teachers()[0].id : null;
    this.teacherNotes = '';
    this.showTeacherModal.set(true);
  }

  saveTeacherSchedule(): void {
    if (!this.scheduleDate || !this.selectedClassId || !this.selectedTeacherId) return;

    this.ebdService
      .setTeacherSchedule({
        date: this.scheduleDate,
        class_id: this.selectedClassId,
        teacher_person_id: this.selectedTeacherId,
      })
      .subscribe({
        next: () => {
          this.showTeacherModal.set(false);
          this.loadData();
        },
      });
  }

  openSuperModal(): void {
    this.scheduleDate = new Date().toISOString().substring(0, 10);
    this.selectedSuperId = this.superintendents().length > 0 ? this.superintendents()[0].id : null;
    this.superNotes = '';
    this.showSuperModal.set(true);
  }

  saveSuperSchedule(): void {
    if (!this.scheduleDate || !this.selectedSuperId) return;

    this.ebdService
      .setSuperintendentSchedule({
        date: this.scheduleDate,
        superintendent_person_id: this.selectedSuperId,
      })
      .subscribe({
        next: () => {
          this.showSuperModal.set(false);
          this.loadData();
        },
      });
  }
}
