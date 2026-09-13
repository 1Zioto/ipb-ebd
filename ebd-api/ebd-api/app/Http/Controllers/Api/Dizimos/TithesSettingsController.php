<?php

namespace App\Http\Controllers\Api\Dizimos;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Services\Dizimos\AuditoriaDizimosService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TithesSettingsController extends Controller
{
    protected array $defaults = [
        'tithes_min_history_months' => '3',
        'tithes_consecutive_months' => '2',
        'tithes_drop_percentage' => '30.0',
        'tithes_no_contribution_months' => '2',
        'tithes_alerts_enabled' => 'true',
        'tithes_require_double_check' => 'false',
        'tithes_allow_multiple_entries' => 'true',
        'tithes_allow_unidentified' => 'true',
    ];

    public function show(): JsonResponse
    {
        $keys = array_keys($this->defaults);
        $settings = Setting::whereIn('key', $keys)->pluck('value', 'key')->all();

        $merged = array_merge($this->defaults, $settings);

        return response()->json($merged);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'tithes_min_history_months' => 'nullable|integer|min:1|max:24',
            'tithes_consecutive_months' => 'nullable|integer|min:1|max:12',
            'tithes_drop_percentage' => 'nullable|numeric|min:5|max:95',
            'tithes_no_contribution_months' => 'nullable|integer|min:1|max:12',
            'tithes_alerts_enabled' => 'nullable|in:true,false',
            'tithes_require_double_check' => 'nullable|in:true,false',
            'tithes_allow_multiple_entries' => 'nullable|in:true,false',
            'tithes_allow_unidentified' => 'nullable|in:true,false',
        ]);

        foreach ($validated as $key => $val) {
            if ($val !== null) {
                Setting::updateOrCreate(['key' => $key], ['value' => (string) $val]);
            }
        }

        AuditoriaDizimosService::log('configuracoes.atualizar', 'settings', null, $validated, $request->user());

        return $this->show();
    }
}
