import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { SecretariaService, EstatisticaPresbiterio } from '../../core/secretaria.service';

@Component({
  selector: 'app-estatistica-presbiterio',
  standalone: true,
  imports: [CommonModule, FormsModule, ButtonModule, ToastModule],
  providers: [MessageService],
  templateUrl: './estatistica-presbiterio.html',
})
export class EstatisticaPresbiterioPage implements OnInit {
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);

  ano = 2026;
  anosDisponiveis = [2026, 2025, 2024];

  dados = signal<EstatisticaPresbiterio | null>(null);
  loading = signal<boolean>(true);

  ngOnInit(): void {
    this.carregarEstatistica();
  }

  carregarEstatistica(): void {
    this.loading.set(true);
    this.secService.getEstatisticaPresbiterio(this.ano).subscribe({
      next: (res) => {
        this.dados.set(res);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: 'Falha ao carregar estatística oficial do Presbitério.',
        });
      },
    });
  }

  imprimir(): void {
    window.print();
  }
}
