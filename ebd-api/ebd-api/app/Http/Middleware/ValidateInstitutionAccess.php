<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ValidateInstitutionAccess
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['message' => 'Não autenticado.'], 401);
        }

        // Tentar obter o contexto da instituição via header X-Institution-Context ou query/param
        $headerContext = $request->header('X-Institution-Context');
        $targetInstitutionId = $headerContext ? (int) $headerContext : null;

        if (! $targetInstitutionId && $request->has('institution_id')) {
            $targetInstitutionId = (int) $request->input('institution_id');
        }

        if ($targetInstitutionId && ! $user->canAccessInstitution($targetInstitutionId)) {
            return response()->json([
                'message' => 'Acesso não autorizado a esta instituição.',
                'error' => 'OUT_OF_INSTITUTION_TREE_SCOPE',
            ], 403);
        }

        return $next($request);
    }
}
