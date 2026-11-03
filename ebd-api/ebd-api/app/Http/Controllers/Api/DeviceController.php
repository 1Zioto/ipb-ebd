<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\UserDevice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;

class DeviceController extends Controller
{
    /**
     * Lista todos os dispositivos e sessões do usuário autenticado.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $currentTokenId = $user->currentAccessToken()?->id;

        $devices = UserDevice::where('user_id', $user->id)
            ->where('is_revoked', false)
            ->orderBy('last_active_at', 'desc')
            ->get()
            ->map(function ($device) use ($currentTokenId) {
                return [
                    'id' => $device->id,
                    'device_name' => $device->device_name,
                    'platform' => $device->platform,
                    'client_version' => $device->client_version,
                    'ip_address' => $device->ip_address,
                    'last_active_at' => $device->last_active_at?->toIso8601String(),
                    'is_current' => ($device->token_id === $currentTokenId),
                    'created_at' => $device->created_at?->toIso8601String(),
                ];
            });

        return response()->json([
            'devices' => $devices,
            'total_active' => $devices->count(),
        ]);
    }

    /**
     * Encerra a sessão e revoga o acesso de um dispositivo específico.
     */
    public function revoke(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $device = UserDevice::where('user_id', $user->id)
            ->where('id', $id)
            ->firstOrFail();

        if ($device->token_id) {
            PersonalAccessToken::where('id', $device->token_id)->delete();
        }

        $device->update(['is_revoked' => true]);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'auth.device.revoked',
            'entity_type' => 'user_device',
            'entity_id' => $device->id,
            'ip' => $request->ip(),
            'user_agent' => substr((string) $request->userAgent(), 0, 255),
        ]);

        return response()->json([
            'message' => 'Sessão do dispositivo encerrada com sucesso.',
            'device_id' => $id,
        ]);
    }

    /**
     * Encerra todas as outras sessões, mantendo apenas a do dispositivo atual.
     */
    public function revokeOthers(Request $request): JsonResponse
    {
        $user = $request->user();
        $currentTokenId = $user->currentAccessToken()?->id;

        $otherDevices = UserDevice::where('user_id', $user->id)
            ->where('is_revoked', false)
            ->when($currentTokenId, fn ($q) => $q->where('token_id', '!=', $currentTokenId))
            ->get();

        $tokenIdsToDelete = $otherDevices->pluck('token_id')->filter()->all();
        if (! empty($tokenIdsToDelete)) {
            PersonalAccessToken::whereIn('id', $tokenIdsToDelete)->delete();
        }

        UserDevice::where('user_id', $user->id)
            ->where('is_revoked', false)
            ->when($currentTokenId, fn ($q) => $q->where('token_id', '!=', $currentTokenId))
            ->update(['is_revoked' => true]);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'auth.device.revoke_others',
            'entity_type' => 'user',
            'entity_id' => $user->id,
            'ip' => $request->ip(),
            'user_agent' => substr((string) $request->userAgent(), 0, 255),
        ]);

        return response()->json([
            'message' => 'Todas as outras sessões foram encerradas com sucesso.',
            'revoked_count' => count($otherDevices),
        ]);
    }
}

