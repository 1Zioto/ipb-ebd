import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { EbdService, ScheduleItem } from '../../core/ebd.service';
import { ClassesService } from '../../core/classes.service';
import { PeopleService } from '../../core/people.service';
import { ClassRoom, Person } from '../../core/models';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-schedules',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './schedules.html',
  styleUrl: './schedules.scss',
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

  activeTab: 'teachers' | 'superintendents' = 'teachers';

  // Form Escala Professor
  showTeacherModal = signal<boolean>(false);
  scheduleDate = new Date().toISOString().substring(0, 10);
  selectedClassId: number | null = null;
  selectedTeacherId: number | null = null;

  // Form Escala Superintendente
  showSuperModal = signal<boolean>(false);
  selectedSuperId: number | null = null;

  ngOnInit(): void {
    this.loadData();
    this.loadDropdowns();
  }

  loadData(): void {
    this.loading.set(true);
    this.ebdService.getTeacherSchedules().subscribe({
      next: (res) => this.teacherSchedules.set(res),
    });

    this.ebdService.getSuperintendentSchedules().subscribe({
      next: (res) => {
        this.superSchedules.set(res);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  async loadDropdowns(): Promise<void> {
    const [classes, teachers, superintendents] = await Promise.all([
      this.classesService.list(),
      this.peopleService.list({ can_teach: true, per_page: 100 }),
      this.peopleService.list({ can_superintend: true, per_page: 100 }),
    ]);
    this.classes.set(classes.data.filter((item) => item.is_active));
    this.teachers.set(teachers.data);
    this.superintendents.set(superintendents.data);
  }

  openTeacherModal(): void {
    this.scheduleDate = new Date().toISOString().substring(0, 10);
    this.selectedClassId = this.classes().length > 0 ? this.classes()[0].id : null;
    this.selectedTeacherId = this.teachers().length > 0 ? this.teachers()[0].id : null;
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
