import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';
import { ScreenConfigService } from './screen-config.service';

export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  if (auth.isAuthenticated()) return true;
  router.navigate(['/login']);
  return false;
};

export const permissionGuard = (permission: string): CanActivateFn => () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  if (auth.can(permission)) return true;
  router.navigate(['/acesso-negado']);
  return false;
};

/**
 * Guarda de rota que verifica se uma tela/módulo está habilitado pelo Super Admin
 * para a igreja ativa. Super Admins têm permissão de auditoria direta.
 */
export const screenGuard = (screenKey: string): CanActivateFn => () => {
  const auth = inject(AuthService);
  const screenConfig = inject(ScreenConfigService);
  const router = inject(Router);

  // Super admin tem acesso irrestrito para parametrização
  if (auth.isSuperAdmin()) {
    return true;
  }

  // Se a tela foi desativada pelo Super Admin, bloqueia o acesso
  if (!screenConfig.isScreenEnabled(screenKey)) {
    router.navigate(['/acesso-negado'], {
      queryParams: {
        motivo: 'tela_desativada',
        modulo: screenKey,
      },
    });
    return false;
  }

  return true;
};

/**
 * Guarda exclusivo para telas e ferramentas de Super Administrador
 */
export const superAdminGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  if (auth.isSuperAdmin()) return true;
  router.navigate(['/acesso-negado']);
  return false;
};
