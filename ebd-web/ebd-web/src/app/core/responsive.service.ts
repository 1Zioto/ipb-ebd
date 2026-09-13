import { Injectable, signal } from '@angular/core';

/** Detecta mobile x desktop por viewport, sem dependências externas. */
@Injectable({ providedIn: 'root' })
export class ResponsiveService {
  private mq = window.matchMedia('(max-width: 768px)');
  private _isMobile = signal<boolean>(this.mq.matches);
  readonly isMobile = this._isMobile.asReadonly();

  constructor() {
    this.mq.addEventListener('change', (e) => this._isMobile.set(e.matches));
  }
}
