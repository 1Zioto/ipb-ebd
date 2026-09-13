import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DizimosService } from '../../core/dizimos.service';
import { TithesSettings } from '../../core/models';

@Component({
  selector: 'app-dizimos-config',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './dizimos-config.html',
  styleUrl: './dizimos-config.scss',
})
export class DizimosConfigPage implements OnInit {
  private dizimosService = inject(DizimosService);

  loading = signal<boolean>(true);
  saving = signal<boolean>(false);
  successMsg = signal<string | null>(null);

  settings: TithesSettings = {
    tithes_min_history_months: '3',
    tithes_consecutive_months: '2',
    tithes_drop_percentage: '30.0',
    tithes_no_contribution_months: '2',
    tithes_alerts_enabled: 'true',
    tithes_require_double_check: 'false',
    tithes_allow_multiple_entries: 'true',
    tithes_allow_unidentified: 'true',
  };

  ngOnInit(): void {
    this.loadSettings();
  }

  loadSettings(): void {
    this.loading.set(true);
    this.dizimosService.getSettings().subscribe({
      next: (res) => {
        this.settings = { ...this.settings, ...res };
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  saveSettings(): void {
    this.saving.set(true);
    this.dizimosService.updateSettings(this.settings).subscribe({
      next: (res) => {
        this.settings = { ...this.settings, ...res };
        this.saving.set(false);
        this.successMsg.set('Configurações do módulo de dízimos salvas com sucesso!');
        setTimeout(() => this.successMsg.set(null), 3000);
      },
      error: () => this.saving.set(false),
    });
  }
}
