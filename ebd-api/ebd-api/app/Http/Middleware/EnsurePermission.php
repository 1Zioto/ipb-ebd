<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePermission
{
    /** Uso: ->middleware('permission:person.manage') */
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = $request->user();

        if (! $user || ! $user->hasPermission($permission)) {
            return response()->json([
                'message' => 'Acesso negado. Permissão necessária: '.$permission,
            ], 403);
        }

        return $next($request);
    }
}
