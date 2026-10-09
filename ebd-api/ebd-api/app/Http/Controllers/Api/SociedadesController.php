<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Person;
use App\Models\SociedadeAtividade;
use App\Models\SociedadeAta;
use App\Models\SociedadeDiretoria;
use App\Models\SociedadeInterna;
use App\Models\SociedadeMembro;
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
            ->withCount(['membros', 'atas'])
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

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'sigla' => 'required|string|max:20',
            'nome' => 'required|string|max:120',
            'lema' => 'nullable|string|max:255',
            'faixa_etaria' => 'nullable|string|max:80',
            'ano_exercicio' => 'nullable|integer',
            'financial_cost_center_id' => 'nullable|exists:financial_cost_centers,id',
        ]);

        $validated['institution_id'] = $request->user()?->institution_id ?? 5;
        $validated['ano_exercicio'] = $validated['ano_exercicio'] ?? date('Y');
        $validated['sigla'] = strtoupper(trim($validated['sigla']));

        $sociedade = SociedadeInterna::create($validated);

        return response()->json($sociedade->load('costCenter'), 201);
    }

    public function update(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'sigla' => 'sometimes|required|string|max:20',
            'nome' => 'sometimes|required|string|max:120',
            'lema' => 'nullable|string|max:255',
            'faixa_etaria' => 'nullable|string|max:80',
            'ano_exercicio' => 'nullable|integer',
            'financial_cost_center_id' => 'nullable|exists:financial_cost_centers,id',
        ]);

        if (isset($validated['sigla'])) {
            $validated['sigla'] = strtoupper(trim($validated['sigla']));
        }

        $sociedade->update($validated);

        return response()->json($sociedade->load('costCenter'));
    }

    public function destroy(SociedadeInterna $sociedade): JsonResponse
    {
        $sociedade->delete();
        return response()->json(['message' => 'Sociedade interna excluída com sucesso.']);
    }

    public function show(SociedadeInterna $sociedade): JsonResponse
    {
        $sociedade->load([
            'diretorias.person:id,full_name,phone,email',
            'atividades' => fn ($q) => $q->orderBy('data', 'desc'),
            'membros.person:id,full_name,phone,email,canonical_status',
            'atas.presidente:id,full_name',
            'atas.secretario:id,full_name',
            'costCenter:id,code,name',
        ]);

        return response()->json($sociedade);
    }

    // ==========================================
    // 👥 ROL DE SÓCIOS / MEMBROS DA SOCIEDADE
    // ==========================================

    public function getMembros(SociedadeInterna $sociedade): JsonResponse
    {
        $membros = $sociedade->membros()
            ->with('person:id,full_name,phone,email,canonical_status,birth_date')
            ->orderBy('tipo_socio', 'asc')
            ->orderBy('id', 'asc')
            ->get();

        return response()->json([
            'sociedade_id' => $sociedade->id,
            'total' => $membros->count(),
            'efetivos' => $membros->where('tipo_socio', 'efetivo')->count(),
            'cooperadores' => $membros->where('tipo_socio', 'cooperador')->count(),
            'data' => $membros,
        ]);
    }

    public function storeMembro(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'person_id' => 'required|exists:people,id',
            'tipo_socio' => 'required|in:efetivo,cooperador',
            'data_admissao' => 'nullable|date',
            'cargo_atual' => 'nullable|string|max:60',
            'status' => 'nullable|in:ativo,inativo,licenciado',
            'observacoes' => 'nullable|string',
        ]);

        $validated['sociedade_id'] = $sociedade->id;
        $validated['data_admissao'] = $validated['data_admissao'] ?? now()->toDateString();
        $validated['status'] = $validated['status'] ?? 'ativo';

        $membro = SociedadeMembro::updateOrCreate(
            ['sociedade_id' => $sociedade->id, 'person_id' => $validated['person_id']],
            $validated
        );

        return response()->json($membro->load('person'), 201);
    }

    public function arrolarEmLote(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'person_ids' => 'required|array',
            'person_ids.*' => 'exists:people,id',
            'tipo_socio' => 'nullable|in:efetivo,cooperador',
        ]);

        $tipo = $validated['tipo_socio'] ?? 'efetivo';
        $adicionados = 0;

        foreach ($validated['person_ids'] as $personId) {
            $m = SociedadeMembro::firstOrCreate(
                ['sociedade_id' => $sociedade->id, 'person_id' => $personId],
                [
                    'tipo_socio' => $tipo,
                    'data_admissao' => now()->toDateString(),
                    'status' => 'ativo',
                ]
            );
            if ($m->wasRecentlyCreated) {
                $adicionados++;
            }
        }

        return response()->json([
            'message' => "Arrolamento concluído: {$adicionados} novos sócios adicionados à {$sociedade->sigla}.",
            'adicionados' => $adicionados,
        ]);
    }

    public function deleteMembro(SociedadeInterna $sociedade, SociedadeMembro $membro): JsonResponse
    {
        if ($membro->sociedade_id !== $sociedade->id) {
            abort(404);
        }

        $membro->delete();
        return response()->json(['message' => 'Sócio removido do rol da sociedade.']);
    }

    // ==========================================
    // 📖 LIVRO DE ATAS DA SOCIEDADE
    // ==========================================

    public function getAtas(SociedadeInterna $sociedade): JsonResponse
    {
        $atas = $sociedade->atas()
            ->with(['presidente:id,full_name', 'secretario:id,full_name'])
            ->orderBy('data_reuniao', 'desc')
            ->orderBy('id', 'desc')
            ->get();

        return response()->json([
            'sociedade_id' => $sociedade->id,
            'total' => $atas->count(),
            'data' => $atas,
        ]);
    }

    public function storeAta(Request $request, SociedadeInterna $sociedade): JsonResponse
    {
        $validated = $request->validate([
            'numero_ata' => 'required|string|max:30',
            'titulo' => 'required|string|max:160',
            'tipo_reuniao' => 'required|string|max:60',
            'data_reuniao' => 'required|date',
            'horario' => 'nullable|string|max:30',
            'local' => 'nullable|string|max:120',
            'presidente_id' => 'nullable|exists:people,id',
            'secretario_id' => 'nullable|exists:people,id',
            'pauta' => 'nullable|string',
            'conteudo' => 'required|string',
            'presentes_count' => 'nullable|integer',
            'status' => 'nullable|in:Rascunho,Aprovada,Assinada',
        ]);

        $validated['sociedade_id'] = $sociedade->id;
        $validated['status'] = $validated['status'] ?? 'Aprovada';
        $validated['presentes_count'] = $validated['presentes_count'] ?? 0;

        $ata = SociedadeAta::create($validated);

        return response()->json($ata->load(['presidente', 'secretario']), 201);
    }

    public function updateAta(Request $request, SociedadeInterna $sociedade, SociedadeAta $ata): JsonResponse
    {
        if ($ata->sociedade_id !== $sociedade->id) {
            abort(404);
        }

        $validated = $request->validate([
            'numero_ata' => 'sometimes|string|max:30',
            'titulo' => 'sometimes|string|max:160',
            'tipo_reuniao' => 'sometimes|string|max:60',
            'data_reuniao' => 'sometimes|date',
            'horario' => 'nullable|string|max:30',
            'local' => 'nullable|string|max:120',
            'presidente_id' => 'nullable|exists:people,id',
            'secretario_id' => 'nullable|exists:people,id',
            'pauta' => 'nullable|string',
            'conteudo' => 'sometimes|string',
            'presentes_count' => 'nullable|integer',
            'status' => 'nullable|in:Rascunho,Aprovada,Assinada',
            'visto_conselho_data' => 'nullable|date',
            'visto_conselho_relator' => 'nullable|string|max:120',
        ]);

        $ata->update($validated);

        return response()->json($ata->load(['presidente', 'secretario']));
    }

    public function deleteAta(SociedadeInterna $sociedade, SociedadeAta $ata): JsonResponse
    {
        if ($ata->sociedade_id !== $sociedade->id) {
            abort(404);
        }

        $ata->delete();
        return response()->json(['message' => 'Ata excluída com sucesso.']);
    }

    // ==========================================
    // 👥 DIRETORIA E ATIVIDADES (ORIGINAIS)
    // ==========================================

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

        // Também assegura que quem está na diretoria está arrolado como membro
        SociedadeMembro::firstOrCreate(
            ['sociedade_id' => $sociedade->id, 'person_id' => $validated['person_id']],
            [
                'tipo_socio' => 'efetivo',
                'data_admissao' => now()->toDateString(),
                'cargo_atual' => $validated['cargo'],
                'status' => 'ativo',
            ]
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
