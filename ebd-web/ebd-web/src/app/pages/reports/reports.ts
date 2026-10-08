import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { InputTextModule } from 'primeng/inputtext';
import { TagModule } from 'primeng/tag';
import { ProgressBarModule } from 'primeng/progressbar';
import { TooltipModule } from 'primeng/tooltip';
import { ClassReport, EbdService, MonthlyReport, StudentReport } from '../../core/ebd.service';
import { ClassesService } from '../../core/classes.service';
import { PeopleService } from '../../core/people.service';
import { ClassRoom, Person } from '../../core/models';

@Component({
  selector: 'app-ebd-reports',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    TableModule,
    InputTextModule,
    TagModule,
    ProgressBarModule,
    TooltipModule,
  ],
  templateUrl: './reports.html',
})
export class EbdReportsPage implements OnInit {
  private ebdService = inject(EbdService);
  private classesService = inject(ClassesService);
  private peopleService = inject(PeopleService);

  activeReport: 'monthly' | 'class' | 'student' = 'monthly';
  loading = signal<boolean>(false);

  // Filtros
  selectedYear = signal<number>(2026);
  selectedMonth = signal<number>(10);
  selectedClassId = signal<number | null>(null);
  selectedPersonId = signal<number | null>(null);

  classes = signal<ClassRoom[]>([]);
  people = signal<Person[]>([]);

  // Dados dos relatórios
  monthlyData = signal<MonthlyReport | null>(null);
  classData = signal<ClassReport | null>(null);
  studentData = signal<StudentReport | null>(null);

  readonly monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  monthTitle = computed(() => {
    return `${this.monthNames[this.selectedMonth() - 1]} de ${this.selectedYear()}`;
  });

  ngOnInit(): void {
    this.loadDropdowns();
    this.fetchMonthlyReport();
  }

  exportPdf(): void {
    window.print();
  }

  async loadDropdowns(): Promise<void> {
    try {
      const [classes, people] = await Promise.all([
        this.classesService.list(),
        this.peopleService.list({ is_active: true, per_page: 100 }),
      ]);
      const activeClasses = classes.data.filter((item) => item.is_active);
      this.classes.set(activeClasses);
      this.people.set(people.data);

      if (activeClasses.length > 0 && !this.selectedClassId()) {
        this.selectedClassId.set(activeClasses[0].id);
      }
      if (people.data.length > 0 && !this.selectedPersonId()) {
        this.selectedPersonId.set(people.data[0].id);
      }
    } catch (e) {
      console.error('Erro ao carregar dropdowns de relatórios:', e);
    }
  }

  fetchMonthlyReport(): void {
    this.loading.set(true);
    this.ebdService.getMonthlyReport(this.selectedYear(), this.selectedMonth()).subscribe({
      next: (res) => {
        this.monthlyData.set(res);
        this.loading.set(false);
      },
      error: (err) => {
        console.error('Erro ao buscar relatório mensal:', err);
        this.loading.set(false);
      },
    });
  }

  setMonth(m: number): void {
    this.selectedMonth.set(m);
    this.fetchMonthlyReport();
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
    this.fetchMonthlyReport();
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
    this.fetchMonthlyReport();
  }

  fetchClassReport(): void {
    const classId = this.selectedClassId();
    if (!classId) return;
    this.loading.set(true);
    this.ebdService.getClassReport(classId).subscribe({
      next: (res) => {
        this.classData.set(res);
        this.loading.set(false);
      },
      error: (err) => {
        console.error('Erro ao buscar relatório da classe:', err);
        this.loading.set(false);
      },
    });
  }

  onClassChange(classId: number): void {
    this.selectedClassId.set(classId);
    this.fetchClassReport();
  }

  fetchStudentReport(): void {
    const personId = this.selectedPersonId();
    if (!personId) return;
    this.loading.set(true);
    this.ebdService.getStudentReport(personId).subscribe({
      next: (res) => {
        this.studentData.set(res);
        this.loading.set(false);
      },
      error: (err) => {
        console.error('Erro ao buscar relatório do aluno:', err);
        this.loading.set(false);
      },
    });
  }

  onStudentChange(personId: number): void {
    this.selectedPersonId.set(personId);
    this.fetchStudentReport();
  }
}
