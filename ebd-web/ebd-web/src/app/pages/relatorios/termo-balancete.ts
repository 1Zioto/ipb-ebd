import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { SecretariaService, TermoBalancete } from '../../core/secretaria.service';
import { PastorInfo } from '../../core/models';

@Component({
  selector: 'app-termo-balancete',
  standalone: true,
  imports: [CommonModule, FormsModule, ButtonModule, ToastModule],
  providers: [MessageService],
  templateUrl: './termo-balancete.html',
})
export class TermoBalancetePage implements OnInit {
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);

  ano = 2026;
  mes = 9;
  pastorId: number | null = null;
  pastoresDisponiveis = signal<PastorInfo[]>([]);

  anosDisponiveis = [2026, 2025];
  mesesDisponiveis = [
    { valor: 1, nome: 'Janeiro' },
    { valor: 2, nome: 'Fevereiro' },
    { valor: 3, nome: 'Março' },
    { valor: 4, nome: 'Abril' },
    { valor: 5, nome: 'Maio' },
    { valor: 6, nome: 'Junho' },
    { valor: 7, nome: 'Julho' },
    { valor: 8, nome: 'Agosto' },
    { valor: 9, nome: 'Setembro' },
    { valor: 10, nome: 'Outubro' },
    { valor: 11, nome: 'Novembro' },
    { valor: 12, nome: 'Dezembro' },
  ];

  termo = signal<TermoBalancete | null>(null);
  loading = signal<boolean>(true);

  ngOnInit(): void {
    this.carregarTermo();
  }

  carregarTermo(): void {
    this.loading.set(true);
    this.secService.getTermoBalancete(this.ano, this.mes, this.pastorId || undefined).subscribe({
      next: (res) => {
        this.termo.set(res);
        if (res.pastores && res.pastores.length > 0) {
          this.pastoresDisponiveis.set(res.pastores);
        }
        if (res.pastor_responsavel?.id && !this.pastorId) {
          this.pastorId = res.pastor_responsavel.id;
        }
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: 'Falha ao carregar termo de balancete.',
        });
      },
    });
  }

  imprimir(): void {
    window.print();
  }
}
