import { Component, input, output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SkeletonModule } from 'primeng/skeleton';

export type StatCardColor = 'primary' | 'emerald' | 'blue' | 'amber' | 'rose' | 'violet' | 'teal';

@Component({
  selector: 'app-stat-card',
  standalone: true,
  imports: [CommonModule, SkeletonModule],
  template: `
    <div
      class="card mb-0 h-full flex flex-col justify-between transition-all duration-200"
      [class.cursor-pointer]="clickable()"
      [class.hover:-translate-y-0.5]="clickable()"
      [class.hover:shadow-md]="clickable()"
      [class.ring-2]="selected()"
      [class.ring-primary]="selected()"
      (click)="clickable() ? cardClick.emit() : null"
    >
      @if (loading()) {
        <div>
          <div class="flex justify-between items-start mb-3">
            <p-skeleton width="60%" height="1rem" styleClass="mb-2"></p-skeleton>
            <p-skeleton shape="circle" size="2.5rem"></p-skeleton>
          </div>
          <p-skeleton width="45%" height="2rem" styleClass="mb-2"></p-skeleton>
          <p-skeleton width="80%" height="0.875rem"></p-skeleton>
        </div>
      } @else {
        <div>
          <div class="flex justify-between items-start mb-3">
            <div>
              <span class="block text-muted-color font-medium text-xs uppercase tracking-wider mb-1">
                {{ title() }}
              </span>
              <div class="text-surface-900 dark:text-surface-0 font-bold text-2xl tracking-tight">
                {{ value() }}
              </div>
            </div>
            <div
              class="flex items-center justify-center rounded-xl p-2.5 transition-transform"
              [ngClass]="iconContainerClass()"
              style="width: 2.75rem; height: 2.75rem"
            >
              <i [ngClass]="icon()" class="text-lg font-bold"></i>
            </div>
          </div>

          @if (subtitle() || trend()) {
            <div class="flex items-center gap-1.5 text-xs mt-2 pt-2 border-t border-surface">
              @if (trend()) {
                <span
                  class="font-semibold flex items-center gap-0.5"
                  [ngClass]="{
                    'text-emerald-600 dark:text-emerald-400': trendDirection() === 'up',
                    'text-rose-600 dark:text-rose-400': trendDirection() === 'down',
                    'text-muted-color': trendDirection() === 'neutral'
                  }"
                >
                  <i
                    class="pi text-[10px]"
                    [ngClass]="{
                      'pi-arrow-up': trendDirection() === 'up',
                      'pi-arrow-down': trendDirection() === 'down',
                      'pi-minus': trendDirection() === 'neutral'
                    }"
                  ></i>
                  {{ trend() }}
                </span>
              }
              @if (subtitle()) {
                <span class="text-muted-color">{{ subtitle() }}</span>
              }
            </div>
          }
        </div>
      }
    </div>
  `,
})
export class StatCardComponent {
  title = input.required<string>();
  value = input.required<string | number>();
  icon = input<string>('pi pi-chart-bar');
  color = input<StatCardColor>('primary');
  subtitle = input<string>();
  trend = input<string>();
  trendDirection = input<'up' | 'down' | 'neutral'>('neutral');
  loading = input<boolean>(false);
  clickable = input<boolean>(false);
  selected = input<boolean>(false);

  cardClick = output<void>();

  iconContainerClass() {
    switch (this.color()) {
      case 'emerald':
        return 'bg-emerald-100 text-emerald-600 dark:bg-emerald-950/50 dark:text-emerald-400';
      case 'blue':
        return 'bg-blue-100 text-blue-600 dark:bg-blue-950/50 dark:text-blue-400';
      case 'amber':
        return 'bg-amber-100 text-amber-600 dark:bg-amber-950/50 dark:text-amber-400';
      case 'rose':
        return 'bg-rose-100 text-rose-600 dark:bg-rose-950/50 dark:text-rose-400';
      case 'violet':
        return 'bg-purple-100 text-purple-600 dark:bg-purple-950/50 dark:text-purple-400';
      case 'teal':
        return 'bg-teal-100 text-teal-600 dark:bg-teal-950/50 dark:text-teal-400';
      case 'primary':
      default:
        return 'bg-primary-100 text-primary-600 dark:bg-primary-950/50 dark:text-primary-400';
    }
  }
}
