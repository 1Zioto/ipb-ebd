import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { ProgressBarModule } from 'primeng/progressbar';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import {
  SecretariaService,
  CatecumenoDiscipulo,
  LivroBiblioteca,
  EmprestimoLivro,
  CanonicalMember,
} from '../../core/secretaria.service';

@Component({
  selector: 'app-discipulado-biblioteca',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    TableModule,
    ButtonModule,
    TagModule,
    DialogModule,
    InputTextModule,
    ProgressBarModule,
    ToastModule,
  ],
  providers: [MessageService],
  templateUrl: './discipulado-biblioteca.html',
})
export class DiscipuladoBibliotecaPage implements OnInit {
  private secService = inject(SecretariaService);
  private msg = inject(MessageService);

  activeTab: 'discipulado' | 'biblioteca' | 'emprestimos' = 'discipulado';

  // Discipulado
  catecumenos = signal<CatecumenoDiscipulo[]>([]);
  statsDiscipulado = signal<any>({});
  loadingDiscipulado = signal<boolean>(true);
  faseFilter = '';

  // Biblioteca
  livros = signal<LivroBiblioteca[]>([]);
  statsBiblioteca = signal<any>({});
  loadingBiblioteca = signal<boolean>(true);
  categoriaFilter = '';
  searchLivro = '';

  // Empréstimos
  emprestimos = signal<EmprestimoLivro[]>([]);
  loadingEmprestimos = signal<boolean>(true);

  // Pessoas para seleção
  membros = signal<CanonicalMember[]>([]);

  // Modal Novo Catecúmeno
  novoCatecumenoDialog = false;
  novoCatecumeno = {
    person_id: null as number | null,
    fase: 'Classe de Catecúmenos',
    data_inicio: new Date().toISOString().substring(0, 10),
    total_licoes: 10,
    observacoes: '',
  };

  // Modal Progresso Catecúmeno
  progressoDialog = false;
  selectedCatecumeno: CatecumenoDiscipulo | null = null;
  formProgresso = {
    licoes_concluidas: 0,
    fase: 'Classe de Catecúmenos',
    observacoes: '',
  };

  // Modal Novo Livro
  novoLivroDialog = false;
  novoLivro = {
    titulo: '',
    autor: '',
    categoria: 'Teologia Sistemática',
    editora: 'Cultura Cristã',
    ano: 2024,
    quantidade_total: 2,
    localizacao: 'Estante A1',
  };

  // Modal Novo Empréstimo
  novoEmprestimoDialog = false;
  novoEmprestimo = {
    livro_id: null as number | null,
    person_id: null as number | null,
    data_emprestimo: new Date().toISOString().substring(0, 10),
    data_prevista_devolucao: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10),
    observacoes: '',
  };

  fasesDiscipulado = [
    'Novo Convertido',
    'Classe de Catecúmenos',
    'Apto para Batismo/Profissão',
    'Concluído',
  ];

  categoriasLivro = [
    'Teologia Sistemática',
    'Vida Cristã',
    'Comentários Bíblicos',
    'Apologética',
    'Família & Aliança',
    'Aconselhamento Pastoral',
    'História da Igreja',
    'Literatura Cristã',
  ];

  ngOnInit(): void {
    this.carregarDiscipulado();
    this.carregarLivros();
    this.carregarEmprestimos();
    this.carregarMembros();
  }

  carregarMembros(): void {
    this.secService.getMembros().subscribe({
      next: (res) => this.membros.set(res.membros.data),
    });
  }

  carregarDiscipulado(): void {
    this.loadingDiscipulado.set(true);
    this.secService.getDiscipulado({ fase: this.faseFilter || undefined }).subscribe({
      next: (res) => {
        this.catecumenos.set(res.items.data);
        this.statsDiscipulado.set(res.stats);
        this.loadingDiscipulado.set(false);
      },
      error: () => this.loadingDiscipulado.set(false),
    });
  }

  carregarLivros(): void {
    this.loadingBiblioteca.set(true);
    this.secService
      .getLivros({
        categoria: this.categoriaFilter || undefined,
        search: this.searchLivro || undefined,
      })
      .subscribe({
        next: (res) => {
          this.livros.set(res.livros.data);
          this.statsBiblioteca.set(res.stats);
          this.loadingBiblioteca.set(false);
        },
        error: () => this.loadingBiblioteca.set(false),
      });
  }

  carregarEmprestimos(): void {
    this.loadingEmprestimos.set(true);
    this.secService.getEmprestimos().subscribe({
      next: (res) => {
        this.emprestimos.set(res.data);
        this.loadingEmprestimos.set(false);
      },
      error: () => this.loadingEmprestimos.set(false),
    });
  }

  abrirNovoCatecumeno(): void {
    this.novoCatecumeno = {
      person_id: null,
      fase: 'Classe de Catecúmenos',
      data_inicio: new Date().toISOString().substring(0, 10),
      total_licoes: 10,
      observacoes: '',
    };
    this.novoCatecumenoDialog = true;
  }

  salvarCatecumeno(): void {
    if (!this.novoCatecumeno.person_id) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Selecione uma pessoa.' });
      return;
    }
    this.secService.createCatecumeno(this.novoCatecumeno).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Inscrito na trilha de discipulado!' });
        this.novoCatecumenoDialog = false;
        this.carregarDiscipulado();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao inscrever no discipulado.' }),
    });
  }

  abrirProgresso(cat: CatecumenoDiscipulo): void {
    this.selectedCatecumeno = cat;
    this.formProgresso = {
      licoes_concluidas: cat.licoes_concluidas,
      fase: cat.fase,
      observacoes: cat.observacoes || '',
    };
    this.progressoDialog = true;
  }

  salvarProgresso(): void {
    if (!this.selectedCatecumeno) return;
    this.secService.updateCatecumeno(this.selectedCatecumeno.id, this.formProgresso).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Progresso do catecúmeno atualizado!' });
        this.progressoDialog = false;
        this.carregarDiscipulado();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao atualizar progresso.' }),
    });
  }

  abrirNovoLivro(): void {
    this.novoLivro = {
      titulo: '',
      autor: '',
      categoria: 'Teologia Sistemática',
      editora: 'Cultura Cristã',
      ano: 2024,
      quantidade_total: 2,
      localizacao: 'Estante A1',
    };
    this.novoLivroDialog = true;
  }

  salvarLivro(): void {
    if (!this.novoLivro.titulo || !this.novoLivro.autor) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Preencha título e autor.' });
      return;
    }
    this.secService.createLivro(this.novoLivro).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Livro adicionado ao acervo!' });
        this.novoLivroDialog = false;
        this.carregarLivros();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao cadastrar livro.' }),
    });
  }

  abrirNovoEmprestimo(livro?: LivroBiblioteca): void {
    this.novoEmprestimo = {
      livro_id: livro ? livro.id : null,
      person_id: null,
      data_emprestimo: new Date().toISOString().substring(0, 10),
      data_prevista_devolucao: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10),
      observacoes: '',
    };
    this.novoEmprestimoDialog = true;
  }

  salvarEmprestimo(): void {
    if (!this.novoEmprestimo.livro_id || !this.novoEmprestimo.person_id) {
      this.msg.add({ severity: 'warn', summary: 'Atenção', detail: 'Selecione o livro e o leitor.' });
      return;
    }
    this.secService.createEmprestimo(this.novoEmprestimo).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Empréstimo registrado com sucesso!' });
        this.novoEmprestimoDialog = false;
        this.carregarEmprestimos();
        this.carregarLivros();
      },
      error: (err) => {
        this.msg.add({
          severity: 'error',
          summary: 'Erro',
          detail: err.error?.message || 'Falha ao registrar empréstimo.',
        });
      },
    });
  }

  devolver(emp: EmprestimoLivro): void {
    this.secService.devolverEmprestimo(emp.id).subscribe({
      next: () => {
        this.msg.add({ severity: 'success', summary: 'Sucesso', detail: 'Devolução registrada no acervo!' });
        this.carregarEmprestimos();
        this.carregarLivros();
      },
      error: () => this.msg.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao registrar devolução.' }),
    });
  }

  getProgressPercentage(cat: CatecumenoDiscipulo): number {
    if (!cat.total_licoes) return 0;
    return Math.round((cat.licoes_concluidas / cat.total_licoes) * 100);
  }

  getFaseSeverity(fase: string): 'success' | 'info' | 'warn' | 'secondary' {
    switch (fase) {
      case 'Concluído':
        return 'success';
      case 'Apto para Batismo/Profissão':
        return 'warn';
      case 'Classe de Catecúmenos':
        return 'info';
      default:
        return 'secondary';
    }
  }
}
