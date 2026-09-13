import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { DizimosService } from '../../core/dizimos.service';
import { ColetaDizimo } from '../../core/models';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-coletas-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './coletas-list.html',
  styleUrl: './coletas-list.scss',
})
export class ColetasListPage implements OnInit {
  private dizimosService = inject(DizimosService);
  private router = inject(Router);
  auth = inject(AuthService);

  coletas = signal<ColetaDizimo[]>([]);
  loading = signal<boolean>(false);
  showModal = signal<boolean>(false);
  creating = signal<boolean>(false);
  createError = signal<string | null>(null);

  // Form para nova coleta
  newDate = new Date().toISOString().substring(0, 10);
  newMeeting = 'Culto de Domingo';
  newDesc = '';
  newNotes = '';

  ngOnInit(): void {
    this.loadColetas();
  }

  loadColetas(): void {
    this.loading.set(true);
    this.dizimosService.getColetas().subscribe({
      next: (res) => {
        this.coletas.set(res.data);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  openNewModal(): void {
    this.newDate = new Date().toISOString().substring(0, 10);
    this.createError.set(null);
    this.showModal.set(true);
  }

  closeModal(): void {
    this.showModal.set(false);
  }

  createColeta(): void {
    if (!this.newDate || this.creating()) return;
    this.creating.set(true);
    this.createError.set(null);
    this.dizimosService
      .openColeta({
        date: this.newDate,
        service_meeting: this.newMeeting,
        description: this.newDesc,
        notes: this.newNotes,
      })
      .subscribe({
        next: (c) => {
          this.creating.set(false);
          this.closeModal();
          void this.router.navigate(['/dizimos/coletas', c.id]);
        },
        error: (error: HttpErrorResponse) => {
          this.creating.set(false);
          const validationErrors = error.error?.errors
            ? Object.values(error.error.errors).flat().join(' ')
            : null;
          this.createError.set(
            validationErrors ||
              error.error?.message ||
              'Não foi possível abrir a coleta. Verifique sua conexão e tente novamente.'
          );
        },
      });
  }

  getStatusBadgeClass(status: string): string {
    switch (status) {
      case 'Aberta':
        return 'badge-success';
      case 'Em conferência':
        return 'badge-warning';
      case 'Fechada':
        return 'badge-secondary';
      case 'Reaberta para correção':
        return 'badge-info';
      default:
        return 'badge-danger';
    }
  }
}
