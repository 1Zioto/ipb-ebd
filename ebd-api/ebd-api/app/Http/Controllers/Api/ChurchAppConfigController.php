<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\ChurchAppConfig;
use App\Models\Institution;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChurchAppConfigController extends Controller
{
    /**
     * Retorna as configurações de módulos do aplicativo do membro para a igreja autenticada
     */
    public function show(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $config = ChurchAppConfig::where('institution_id', $institutionId)->first();

        $modules = $config ? $config->modules_config : ChurchAppConfig::defaultModules();

        return response()->json([
            'institution_id' => $institutionId,
            'modules' => $modules,
            'updated_at' => $config?->updated_at,
        ]);
    }

    /**
     * Atualiza as configurações de módulos do aplicativo do membro para a igreja
     */
    public function update(Request $request): JsonResponse
    {
        $request->validate([
            'modules' => 'required|array',
        ]);

        $institutionId = $request->user()->institution_id;
        $user = $request->user();

        $mergedModules = array_merge(ChurchAppConfig::defaultModules(), $request->input('modules'));

        $config = ChurchAppConfig::updateOrCreate(
            ['institution_id' => $institutionId],
            ['modules_config' => $mergedModules]
        );

        AuditLog::create([
            'user_id' => $user->id,
            'institution_id' => $institutionId,
            'action' => 'atualizar_modulos_app_membro',
            'entity_type' => 'ChurchAppConfig',
            'entity_id' => $config->id,
            'details' => json_encode($mergedModules),
        ]);

        return response()->json([
            'message' => 'Configurações do Aplicativo do Membro atualizadas com sucesso.',
            'modules' => $config->modules_config,
        ]);
    }

    /**
     * Consulta pública dos módulos ativos para o app do membro / web mobile
     */
    public function publicModules(string $slugOrId): JsonResponse
    {
        $institution = is_numeric($slugOrId)
            ? Institution::find((int) $slugOrId)
            : Institution::where('short_name', $slugOrId)->orWhere('code', $slugOrId)->first();

        if (!$institution) {
            return response()->json(['message' => 'Igreja não encontrada.'], 404);
        }

        $config = ChurchAppConfig::where('institution_id', $institution->id)->first();
        $modules = $config ? $config->modules_config : ChurchAppConfig::defaultModules();

        return response()->json([
            'institution' => [
                'id' => $institution->id,
                'name' => $institution->name,
                'short_name' => $institution->short_name,
            ],
            'modules' => $modules,
        ]);
    }
}
