<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ScreenConfigController extends Controller
{
    /**
     * Retorna a configuração global e por igreja das telas do sistema.
     */
    public function index(): JsonResponse
    {
        $toggles = Setting::get('ipb_screen_toggles_by_church', []);
        $churches = Setting::get('ipb_super_admin_churches_v2', []);

        return response()->json([
            'toggles' => $toggles ?: new \stdClass(),
            'churches' => $churches ?: [],
        ]);
    }

    /**
     * Salva a configuração de telas por igreja e opcionalmente a lista de igrejas.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'toggles' => ['nullable', 'array'],
            'churches' => ['nullable', 'array'],
            'active_church_id' => ['nullable', 'integer'],
        ]);

        if (isset($data['toggles'])) {
            Setting::updateOrCreate(
                ['key' => 'ipb_screen_toggles_by_church'],
                ['value' => $data['toggles']]
            );
        }

        if (isset($data['churches'])) {
            Setting::updateOrCreate(
                ['key' => 'ipb_super_admin_churches_v2'],
                ['value' => $data['churches']]
            );
        }

        return response()->json([
            'message' => 'Configurações de telas salvas com sucesso no banco de dados.',
            'success' => true,
        ]);
    }
}
