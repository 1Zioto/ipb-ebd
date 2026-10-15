<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Authorizes an endpoint when the user has at least one of the listed
 * permissions. It is intentionally server-side so navigation visibility is
 * never the only access control for shared areas such as council approvals.
 */
class EnsureAnyPermission
{
    public function handle(Request $request, Closure $next, string ...$permissions): Response
    {
        $user = $request->user();

        if (! $user || ! collect($permissions)->contains(fn (string $permission) => $user->hasPermission($permission))) {
            return response()->json([
                'message' => 'Acesso negado. É necessária uma das permissões: '.implode(', ', $permissions),
            ], 403);
        }

        return $next($request);
    }
}
