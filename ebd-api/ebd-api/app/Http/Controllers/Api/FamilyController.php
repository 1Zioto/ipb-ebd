<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\FamilyResource;
use App\Models\Family;
use App\Models\Person;
use App\Support\Audit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class FamilyController extends Controller
{
    private const RELATIONSHIPS = ['responsavel', 'conjuge', 'filho', 'filha', 'dependente', 'outro'];

    public function index(Request $request)
    {
        $this->authorize('viewAny', Family::class);
        $query = Family::query()->withCount('members')->with(['members' => fn ($q) => $q->orderByPivot('is_head', 'desc')->orderBy('full_name')]);
        $institutionId = $this->institutionId($request);
        if ($institutionId) $query->where('institution_id', $institutionId);
        if ($request->filled('search')) {
            $term = '%'.$request->string('search').'%';
            $query->where(fn ($q) => $q->where('name', 'ilike', $term)
                ->orWhereHas('members', fn ($m) => $m->where('full_name', 'ilike', $term)));
        }
        if ($request->has('is_active')) $query->where('is_active', $request->boolean('is_active'));
        return FamilyResource::collection($query->orderBy('name')->paginate($request->integer('per_page', 20)));
    }

    public function store(Request $request)
    {
        $this->authorize('create', Family::class);
        $validated = $this->validatePayload($request);
        $family = DB::transaction(function () use ($request, $validated) {
            $members = $validated['members'] ?? [];
            unset($validated['members']);
            $validated['institution_id'] = $this->institutionId($request, true);
            $this->validateMembers($members, $validated['institution_id']);
            $family = Family::create($validated);
            $this->syncMembers($family, $members);
            Audit::log('family.created', 'family', $family->id, null, $family->toArray());
            return $family;
        });
        return (new FamilyResource($this->loadFamily($family)))->response()->setStatusCode(201);
    }

    public function show(Family $family)
    {
        $this->authorize('view', $family);
        return new FamilyResource($this->loadFamily($family));
    }

    public function update(Request $request, Family $family)
    {
        $this->authorize('update', $family);
        $validated = $this->validatePayload($request, true);
        DB::transaction(function () use ($family, $validated) {
            $old = $family->load('members')->toArray();
            $members = $validated['members'] ?? null;
            unset($validated['members']);
            $family->update($validated);
            if ($members !== null) {
                $this->validateMembers($members, $family->institution_id, $family->id);
                $this->syncMembers($family, $members);
            }
            Audit::log('family.updated', 'family', $family->id, $old, $family->fresh()->toArray());
        });
        return new FamilyResource($this->loadFamily($family->fresh()));
    }

    public function destroy(Family $family)
    {
        $this->authorize('delete', $family);
        $family->update(['is_active' => false]);
        $family->delete();
        Audit::log('family.deleted', 'family', $family->id);
        return response()->json(['message' => 'Família inativada.']);
    }

    private function validatePayload(Request $request, bool $updating = false): array
    {
        return $request->validate([
            'name' => [$updating ? 'sometimes' : 'required', 'string', 'max:180'],
            'phone' => ['nullable', 'string', 'max:30'], 'whatsapp' => ['nullable', 'string', 'max:30'],
            'email' => ['nullable', 'email', 'max:180'], 'zipcode' => ['nullable', 'string', 'max:12'],
            'street' => ['nullable', 'string', 'max:180'], 'number' => ['nullable', 'string', 'max:30'],
            'complement' => ['nullable', 'string', 'max:100'], 'district' => ['nullable', 'string', 'max:100'],
            'city' => ['nullable', 'string', 'max:100'], 'state' => ['nullable', 'string', 'size:2'],
            'notes' => ['nullable', 'string'], 'is_active' => ['boolean'],
            'members' => ['sometimes', 'array'], 'members.*.person_id' => ['required', 'integer', 'distinct', 'exists:people,id'],
            'members.*.relationship' => ['required', Rule::in(self::RELATIONSHIPS)],
            'members.*.is_head' => ['boolean'],
        ]);
    }

    private function institutionId(Request $request, bool $required = false): ?int
    {
        $user = $request->user();
        $id = $request->header('X-Institution-Context') ?: $user->institution_id;
        if ($user->hasGlobalInstitutionAccess() && $request->filled('institution_id')) $id = $request->integer('institution_id');
        if ($required && ! $id) abort(422, 'Selecione uma instituição para cadastrar a família.');
        if ($id && ! $user->canAccessInstitution((int) $id)) abort(403, 'Instituição não autorizada.');
        return $id ? (int) $id : null;
    }

    private function validateMembers(array $members, int $institutionId, ?int $familyId = null): void
    {
        $ids = collect($members)->pluck('person_id');
        if ($ids->isEmpty()) return;
        if (Person::whereIn('id', $ids)->where('institution_id', '!=', $institutionId)->exists()) abort(422, 'Todos os membros devem pertencer à mesma instituição.');
        $memberQuery = DB::table('family_members')->whereIn('person_id', $ids);
        if ($familyId) $memberQuery->where('family_id', '!=', $familyId);
        if ($memberQuery->exists()) abort(422, 'Uma das pessoas selecionadas já pertence a outra família.');
        if (collect($members)->where('is_head', true)->count() > 1) abort(422, 'A família pode ter somente um responsável principal.');
    }

    private function syncMembers(Family $family, array $members): void
    {
        $currentIds = $family->members()->pluck('people.id');
        $incomingIds = collect($members)->pluck('person_id');
        $conflicts = DB::table('family_members')->whereIn('person_id', $incomingIds)->whereNotIn('person_id', $currentIds)->exists();
        if ($conflicts) abort(422, 'Uma das pessoas selecionadas já pertence a outra família.');
        $family->members()->sync(collect($members)->mapWithKeys(fn ($member) => [
            $member['person_id'] => ['relationship' => $member['relationship'], 'is_head' => (bool) ($member['is_head'] ?? false)],
        ])->all());
    }

    private function loadFamily(Family $family): Family
    {
        return $family->loadCount('members')->load(['members' => fn ($q) => $q->orderByPivot('is_head', 'desc')->orderBy('full_name')]);
    }
}
