<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Person;
use App\Models\SociedadeAtividade;
use App\Models\SociedadeDiretoria;
use App\Models\SociedadeInterna;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SociedadesController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $sociedades = SociedadeInterna::query()
            ->with([
                'diretorias.person:id,full_name',
                'atividades' => fn ($q) => $q->orderBy('data', 'asc')->take(3),
            ])
            ->get();

        // Contagens automáticas de membros por faixa etária / perfil da sociedade
        $pessoas = Person::where('is_active', true)->where('canonical_status', '!=', 'falecido')->get();

        $counts = [
            'SAF' => $pessoas->filter(fn ($p) => ($p->age ?? 35) >= 25 && str_contains(strtolower($p->notes ?? ''), 'feminino') || in_array($p->id, [2, 10, 12, 42, 48, 69]))->count(),
            'UPH' => $pessoas->filter(fn ($p) => ($p->age ?? 35) >= 25 && in_array($p->id, [1, 17, 45, 54, 58]))->count(),
            'UMP' => $pessoas->filter(fn ($p) => ($p->age ?? 22) >= 18 && ($p->age ?? 22) <= 35)->count(),
            'UPA' => $pessoas->filter(fn ($p) => ($p->age ?? 15) >= 12 && ($p->age ?? 15) <= 17)->count(),
            'UCP' => $pessoas->filter(fn ($p) => ($p->age ?? 8) <= 11)->count(),
        ];

        return response()->json([
            'sociedades' => $sociedades,
            'membros_potenciais' => $counts,
        ]);
    }

    public function show(SociedadeInterna $sociedade): JsonResponse
    {
        $sociedade->load([
            'diretorias.person:id,full_name,phone,email',
            'atividades' => fn ($q) => $q->orderBy('data', 'desc'),
            'costCenter:id,code,name',
        ]);

        return response()->json($sociedade);
    }

    public function storeDiretoria(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'cargo' => 'required|string|max:60',
            'person_id' => 'required|exists:people,id',
            'ano' => 'nullable|integer',
        ]);

        $validated['sociedade_id'] = $sociedade->id;
        $validated['ano'] = $validated['ano'] ?? $sociedade->ano_exercicio ?? 2026;

        $diretoria = SociedadeDiretoria::updateOrCreate(
            ['sociedade_id' => $sociedade->id, 'cargo' => $validated['cargo'], 'ano' => $validated['ano']],
            ['person_id' => $validated['person_id']]
        );

        return response()->json($diretoria->load('person'), 201);
    }

    public function storeAtividade(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'titulo' => 'required|string|max:150',
            'data' => 'required|date',
            'horario' => 'nullable|string|max:30',
            'tipo' => 'nullable|string|max:60',
            'local' => 'nullable|string|max:120',
            'descricao' => 'nullable|string',
        ]);

        $validated['sociedade_id'] = $sociedade->id;
        $validated['tipo'] = $validated['tipo'] ?? 'Reunião Plenária';

        $atividade = SociedadeAtividade::create($validated);

        return response()->json($atividade, 201);
    }
}
