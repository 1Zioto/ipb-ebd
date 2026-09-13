import { Injectable, signal } from '@angular/core';

type Theme = 'light' | 'dark';
const KEY = 'ebd_theme';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  private _theme = signal<Theme>(this.initial());
  readonly theme = this._theme.asReadonly();

  constructor() { this.apply(this._theme()); }

  private initial(): Theme {
    const stored = localStorage.getItem(KEY) as Theme | null;
    if (stored === 'light' || stored === 'dark') return stored;
    const prefersDark = window.matchMedia?.('(prefers-color-scheme: dark)').matches;
    return prefersDark ? 'dark' : 'light';
  }

  private apply(t: Theme) { document.documentElement.setAttribute('data-theme', t); }

  toggle() {
    const next: Theme = this._theme() === 'dark' ? 'light' : 'dark';
    this._theme.set(next);
    localStorage.setItem(KEY, next);
    this.apply(next);
  }

  isDark() { return this._theme() === 'dark'; }
}
