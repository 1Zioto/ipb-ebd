<?php

namespace App\Services\Dizimos;

use App\Models\AuditoriaDizimo;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Request;

class AuditoriaDizimosService
{
    public static function log(string $action, string $entity, ?int $entityId = null, array $details = [], ?User $user = null): AuditoriaDizimo
    {
        $userId = $user?->id ?? Auth::id();

        // Remover dados excessivamente sensíveis ou contrassenhas do log de auditoria
        unset($details['password'], $details['secret']);

        return AuditoriaDizimo::create([
            'user_id' => $userId,
            'action' => $action,
            'entity' => $entity,
            'entity_id' => $entityId,
            'details' => empty($details) ? null : $details,
            'ip_address' => Request::ip(),
            'user_agent' => Request::userAgent(),
            'created_at' => now(),
        ]);
    }
}
