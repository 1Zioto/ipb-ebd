import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { SecretariaService, AtaConselho } from '../../core/secretaria.service';

@Component({
  selector: 'app-atas-conselho',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    TableModule,
    ButtonModule,
    TagModule,
    DialogModule,
    InputTextModule,
    ToastModule,
  ],
  providers: [MessageService],
  templateUrl: './atas-conselho.html',
})
export class AtasConselhoPage implements OnInit {
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);

  atas = signal<AtaConselho[]>([]);
  loading = signal<boolean>(true);

  tipoFilter = '';
  searchQuery = '';

  // Modal Nova Ata / Edição
  formDialog = false;
  isEditing = false;
  formAta: Partial<AtaConselho> = {
    tipo: 'Ordinária',
    data_reuniao: new Date().toISOString().substring(0, 10),
    horario: '19:30',
    local: 'Gabinete Pastoral / Sala do Conselho',
    pastor_presidente: 'Rev. Marcos Silva',
    secretario_conselho: 'Presb. José Carlos Prado',
    status: 'Aprovada',
  };

  // Modal Leitura do Livro de Atas
  viewDialog = false;
  selectedAta: AtaConselho | null = null;

  ngOnInit(): void {
    this.carregarAtas();
  }

  carregarAtas(): void {
    this.loading.set(true);
    this.secService
      .getAtas({
        tipo: this.tipoFilter || undefined,
        search: this.searchQuery || undefined,
      })
      .subscribe({
        next: (res) => {
          this.atas.set(res.data);
          this.loading.set(false);
        },
        error: () => {
          this.loading.set(false);
          this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Erro ao carregar livro de atas.' });
        },
      });
  }

  abrirNovaAta(): void {
    this.isEditing = false;
    const ano = new Date().getFullYear();
    const seq = 100 + this.atas().length + 1;
    this.formAta = {
      numero_ata: `Ata nº ${seq}/${ano}`,
      tipo: 'Ordinária',
      data_reuniao: new Date().toISOString().substring(0, 10),
      horario: '19:30',
      local: 'Gabinete Pastoral / Sala do Conselho',
      pastor_presidente: 'Rev. Marcos Silva',
      secretario_conselho: 'Presb. José Carlos Prado',
      abertura: 'O Presidente abriu os trabalhos com leitura bíblica e oração.',
      pauta: '1. Expediente; 2. Relatório de finanças; 3. Assuntos pastorais.',
      deliberacoes: 'O Conselho deliberou por unanimidade aprovar os itens da pauta.',
      status: 'Aprovada',
    };
    this.formDialog = true;
  }

  editarAta(ata: AtaConselho): void {
    this.isEditing = true;
    this.formAta = { ...ata };
    this.formDialog = true;
  }

  salvarAta(): void {
    if (!this.formAta.numero_ata || !this.formAta.data_reuniao) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Preencha os campos obrigatórios.' });
      return;
    }

    if (this.isEditing && this.formAta.id) {
      this.secService.updateAta(this.formAta.id, this.formAta).subscribe({
        next: () => {
          this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Ata atualizada com sucesso!' });
          this.formDialog = false;
          this.carregarAtas();
        },
        error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao atualizar ata.' }),
      });
    } else {
      this.secService.createAta(this.formAta).subscribe({
        next: () => {
          this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Ata lavrada e registrada no Livro Oficial!' });
          this.formDialog = false;
          this.carregarAtas();
        },
        error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao registrar ata.' }),
      });
    }
  }

  visualizarAta(ata: AtaConselho): void {
    this.selectedAta = ata;
    this.viewDialog = true;
  }

  imprimir(): void {
    window.print();
  }
}
