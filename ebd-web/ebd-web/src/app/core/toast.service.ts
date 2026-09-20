import { Injectable, inject } from '@angular/core';
import { MessageService } from 'primeng/api';

export type ToastType = 'success' | 'error' | 'info' | 'warning';

@Injectable({ providedIn: 'root' })
export class ToastService {
  private messages = inject(MessageService);

  show(message: string, type: ToastType = 'info', duration = 4000): void {
    this.messages.add({
      severity: type,
      summary: this.summary(type),
      detail: message,
      life: duration,
    });
  }

  success(message: string): void {
    this.show(message, 'success');
  }

  error(message: string): void {
    this.show(message, 'error', 6000);
  }

  info(message: string): void {
    this.show(message, 'info');
  }

  warning(message: string): void {
    this.show(message, 'warning');
  }

  dismiss(_id?: number): void {
    this.messages.clear();
  }

  private summary(type: ToastType): string {
    switch (type) {
      case 'success':
        return 'Sucesso';
      case 'error':
        return 'Erro';
      case 'warning':
        return 'Atenção';
      default:
        return 'Informação';
    }
  }
}
