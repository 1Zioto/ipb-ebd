import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ClassReport, EbdService, MonthlyReport, StudentReport } from '../../core/ebd.service';
import { ClassesService } from '../../core/classes.service';
import { PeopleService } from '../../core/people.service';
import { ClassRoom, Person } from '../../core/models';

@Component({
  selector: 'app-ebd-reports',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './reports.html',
  styleUrl: './reports.scss',
})
export class EbdReportsPage implements OnInit {
  private ebdService = inject(EbdService);
  private classesService = inject(ClassesService);
  private peopleService = inject(PeopleService);

  activeReport: 'monthly' | 'class' | 'student' = 'monthly';
  loading = signal<boolean>(false);

  // Filtros
  selectedYear = new Date().getFullYear();
  selectedMonth = new Date().getMonth() + 1;
  selectedClassId: number | null = null;
  selectedPersonId: number | null = null;

  classes = signal<ClassRoom[]>([]);
  people = signal<Person[]>([]);

  // Dados dos relatórios
  monthlyData = signal<MonthlyReport | null>(null);
  classData = signal<ClassReport | null>(null);
  studentData = signal<StudentReport | null>(null);

  ngOnInit(): void {
    this.loadDropdowns();
    this.fetchMonthlyReport();
  }

  exportPdf(): void { window.print(); }

  async loadDropdowns(): Promise<void> {
    const [classes, people] = await Promise.all([
      this.classesService.list(),
      this.peopleService.list({ is_active: true, per_page: 100 }),
    ]);
    this.classes.set(classes.data.filter((item) => item.is_active));
    this.people.set(people.data);
  }

  fetchMonthlyReport(): void {
    this.loading.set(true);
    this.ebdService.getMonthlyReport(this.selectedYear, this.selectedMonth).subscribe({
      next: (res) => {
        this.monthlyData.set(res);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  fetchClassReport(): void {
    if (!this.selectedClassId) return;
    this.loading.set(true);
    this.ebdService.getClassReport(this.selectedClassId).subscribe({
      next: (res) => {
        this.classData.set(res);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  fetchStudentReport(): void {
    if (!this.selectedPersonId) return;
    this.loading.set(true);
    this.ebdService.getStudentReport(this.selectedPersonId).subscribe({
      next: (res) => {
        this.studentData.set(res);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }
}
