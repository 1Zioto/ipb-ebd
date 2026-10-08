import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { TagModule } from 'primeng/tag';
import { FinancialService } from '../../core/financial.service';
import { AuthService } from '../../core/auth.service';
import { FinancialCategory, FinancialCostCenter } from '../../core/models';

@Component({
  selector: 'app-categories-cost-centers',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    ButtonModule,
    TableModule,
    DialogModule,
    InputTextModule,
    TextareaModule,
    TagModule,
  ],
  templateUrl: './categories-cost-centers.html',
})
export class CategoriesCostCentersPage implements OnInit {
  private financialService = inject(FinancialService);
  auth = inject(AuthService);

  categories = signal<FinancialCategory[]>([]);
  costCenters = signal<FinancialCostCenter[]>([]);

  loading = signal<boolean>(false);
  activeTab: 'categories' | 'costCenters' = 'categories';

  // Modal Categoria
  showCategoryModal = signal<boolean>(false);
  isEditingCategory = signal<boolean>(false);
  categoryEditingId: number | null = null;
  categoryForm = {
    code: '',
    name: '',
    type: 'despesa' as 'receita' | 'despesa',
    description: '',
  };

  // Modal Centro de Custo
  showCostCenterModal = signal<boolean>(false);
  isEditingCostCenter = signal<boolean>(false);
  costCenterEditingId: number | null = null;
  costCenterForm = {
    code: '',
    name: '',
    description: '',
    budget_limit: null as number | null,
  };

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.loading.set(true);
    this.financialService.getCategories().subscribe({
      next: (cats) => {
        this.categories.set(cats);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });

    this.financialService.getCostCenters().subscribe({
      next: (ccs) => this.costCenters.set(ccs),
      error: (err) => console.error('Erro ao carregar centros de custo:', err),
    });
  }

  // --- Categoria CRUD ---
  openCreateCategoryModal(type: 'receita' | 'despesa' = 'despesa'): void {
    this.isEditingCategory.set(false);
    this.categoryEditingId = null;
    this.categoryForm = {
      code: '',
      name: '',
      type,
      description: '',
    };
    this.showCategoryModal.set(true);
  }

  openEditCategoryModal(c: FinancialCategory): void {
    this.isEditingCategory.set(true);
    this.categoryEditingId = c.id;
    this.categoryForm = {
      code: c.code || '',
      name: c.name,
      type: c.type,
      description: c.description || '',
    };
    this.showCategoryModal.set(true);
  }

  saveCategory(): void {
    if (!this.categoryForm.name) return;

    const req$ = this.isEditingCategory() && this.categoryEditingId
      ? this.financialService.updateCategory(this.categoryEditingId, this.categoryForm)
      : this.financialService.createCategory(this.categoryForm);

    req$.subscribe({
      next: () => {
        this.showCategoryModal.set(false);
        this.loadData();
      },
      error: (err) => alert(err.error?.message || 'Erro ao salvar categoria.'),
    });
  }

  deleteCategory(c: FinancialCategory): void {
    if (!confirm(`Deseja desativar/excluir a categoria "${c.name}"?`)) return;

    this.financialService.deleteCategory(c.id).subscribe({
      next: () => this.loadData(),
      error: (err) => alert(err.error?.message || 'Erro ao excluir categoria.'),
    });
  }

  // --- Centro de Custo CRUD ---
  openCreateCostCenterModal(): void {
    this.isEditingCostCenter.set(false);
    this.costCenterEditingId = null;
    this.costCenterForm = {
      code: '',
      name: '',
      description: '',
      budget_limit: null,
    };
    this.showCostCenterModal.set(true);
  }

  openEditCostCenterModal(cc: FinancialCostCenter): void {
    this.isEditingCostCenter.set(true);
    this.costCenterEditingId = cc.id;
    this.costCenterForm = {
      code: cc.code || '',
      name: cc.name,
      description: cc.description || '',
      budget_limit: cc.budget_limit ? Number(cc.budget_limit) : null,
    };
    this.showCostCenterModal.set(true);
  }

  saveCostCenter(): void {
    if (!this.costCenterForm.name) return;

    const req$ = this.isEditingCostCenter() && this.costCenterEditingId
      ? this.financialService.updateCostCenter(this.costCenterEditingId, this.costCenterForm)
      : this.financialService.createCostCenter(this.costCenterForm);

    req$.subscribe({
      next: () => {
        this.showCostCenterModal.set(false);
        this.loadData();
      },
      error: (err) => alert(err.error?.message || 'Erro ao salvar centro de custo.'),
    });
  }

  deleteCostCenter(cc: FinancialCostCenter): void {
    if (!confirm(`Deseja desativar/excluir o centro de custo "${cc.name}"?`)) return;

    this.financialService.deleteCostCenter(cc.id).subscribe({
      next: () => this.loadData(),
      error: (err) => alert(err.error?.message || 'Erro ao excluir centro de custo.'),
    });
  }
}
