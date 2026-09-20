import { Injectable, inject } from '@angular/core';
import { LayoutService } from '@/app/layout/service/layout.service';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  private layout = inject(LayoutService);

  toggle() {
    this.layout.layoutConfig.update((state) => ({
      ...state,
      darkTheme: !state.darkTheme,
    }));
  }

  isDark() {
    return this.layout.isDarkTheme();
  }
}
