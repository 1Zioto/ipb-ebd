import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { AuthService } from './auth.service';

import { InstitutionContextService } from './institution-context.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const instContext = inject(InstitutionContextService);
  const router = inject(Router);
  const token = auth.token();
  const instHeader = instContext.getContextHeaderValue();

  const headers: Record<string, string> = {
    Accept: 'application/json',
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  if (instHeader) {
    headers['X-Institution-Context'] = instHeader;
  }

  const request = req.clone({ setHeaders: headers });

  return next(request).pipe(
    catchError((err) => {
      if (err.status === 401) {
        auth.clearSession();
        router.navigate(['/login']);
      }
      return throwError(() => err);
    })
  );
};
