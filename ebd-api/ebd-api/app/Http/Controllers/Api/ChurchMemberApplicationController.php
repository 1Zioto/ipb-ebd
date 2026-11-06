<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\ChurchMemberApplication;
use App\Models\Institution;
use App\Models\Person;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ChurchMemberApplicationController extends Controller
{
    /**
     * Informações públicas da igreja para o formulário de cadastro de membro
     */
    public function getFormInfo(string $slugOrId): JsonResponse
    {
        $institution = $this->resolveInstitution($slugOrId);

        if (!$institution) {
            return response()->json(['message' => 'Igreja não encontrada.'], 404);
        }

        return response()->json([
            'institution' => [
                'id' => $institution->id,
                'name' => $institution->name,
                'short_name' => $institution->short_name,
                'city' => $institution->city,
                'state' => $institution->state,
                'address' => $institution->address,
            ]
        ]);
    }

    /**
     * Submissão pública da solicitação de cadastro pelo visitante/membro
     */
    public function submitPublicApplication(Request $request, string $slugOrId): JsonResponse
    {
        $institution = $this->resolveInstitution($slugOrId);

        if (!$institution) {
            return response()->json(['message' => 'Igreja não encontrada.'], 404);
        }

        $validated = $request->validate([
            'full_name' => 'required|string|max:255',
            'birth_date' => 'required|date',
            'gender' => 'nullable|string|in:M,F',
            'marital_status' => 'nullable|string|max:30',
            'cpf' => 'nullable|string|max:20',
            'rg' => 'nullable|string|max:20',
            'email' => 'nullable|email|max:255',
            'phone' => 'required|string|max:30',
            'address' => 'nullable|string|max:255',
            'address_number' => 'nullable|string|max:20',
            'address_complement' => 'nullable|string|max:100',
            'neighborhood' => 'nullable|string|max:100',
            'city' => 'nullable|string|max:100',
            'state' => 'nullable|string|max:10',
            'postal_code' => 'nullable|string|max:20',
            'profession' => 'nullable|string|max:100',
            'education' => 'nullable|string|max:100',
            'father_name' => 'nullable|string|max:255',
            'mother_name' => 'nullable|string|max:255',
            'spouse_name' => 'nullable|string|max:255',
            'is_communicant' => 'nullable|boolean',
            'ecclesiastical_condition' => 'nullable|string|max:50',
            'origin_church' => 'nullable|string|max:255',
            'reception_mode' => 'nullable|string|max:50',
            'baptism_date' => 'nullable|date',
            'baptism_church' => 'nullable|string|max:255',
            'profession_of_faith_date' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        // Normalização de CPF e Telefone
        $phoneClean = preg_replace('/\D/', '', $validated['phone']);
        $cpfClean = !empty($validated['cpf']) ? preg_replace('/\D/', '', $validated['cpf']) : null;

        // Verificar duplicidade pendente recente
        $existing = ChurchMemberApplication::where('institution_id', $institution->id)
            ->where('status', 'pendente')
            ->where(function ($q) use ($phoneClean, $cpfClean) {
                $q->where('phone', $phoneClean);
                if ($cpfClean) {
                    $q->orWhere('cpf', $cpfClean);
                }
            })
            ->first();

        if ($existing) {
            return response()->json([
                'message' => 'Já existe uma solicitação de cadastro pendente com este número de telefone ou CPF para esta instituição.',
                'application_id' => $existing->id
            ], 422);
        }

        $application = ChurchMemberApplication::create([
            'institution_id' => $institution->id,
            'full_name' => trim($validated['full_name']),
            'birth_date' => $validated['birth_date'],
            'gender' => $validated['gender'] ?? null,
            'marital_status' => $validated['marital_status'] ?? null,
            'cpf' => $cpfClean,
            'rg' => $validated['rg'] ?? null,
            'email' => !empty($validated['email']) ? strtolower(trim($validated['email'])) : null,
            'phone' => $phoneClean,
            'address' => $validated['address'] ?? null,
            'address_number' => $validated['address_number'] ?? null,
            'address_complement' => $validated['address_complement'] ?? null,
            'neighborhood' => $validated['neighborhood'] ?? null,
            'city' => $validated['city'] ?? $institution->city,
            'state' => $validated['state'] ?? $institution->state,
            'postal_code' => $validated['postal_code'] ?? null,
            'profession' => $validated['profession'] ?? null,
            'education' => $validated['education'] ?? null,
            'father_name' => $validated['father_name'] ?? null,
            'mother_name' => $validated['mother_name'] ?? null,
            'spouse_name' => $validated['spouse_name'] ?? null,
            'is_communicant' => $validated['is_communicant'] ?? true,
            'ecclesiastical_condition' => $validated['ecclesiastical_condition'] ?? 'comungante',
            'origin_church' => $validated['origin_church'] ?? null,
            'reception_mode' => $validated['reception_mode'] ?? null,
            'baptism_date' => $validated['baptism_date'] ?? null,
            'baptism_church' => $validated['baptism_church'] ?? null,
            'profession_of_faith_date' => $validated['profession_of_faith_date'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'status' => 'pendente',
        ]);

        return response()->json([
            'message' => 'Sua solicitação de cadastro foi enviada com sucesso! A secretaria da igreja analisará as informações para aprovação.',
            'id' => $application->id,
        ], 201);
    }

    /**
     * Listagem de solicitações para a secretaria (restrito à instituição do usuário)
     */
    public function index(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        $status = $request->query('status'); // pendente, aprovado, rejeitado, all

        $query = ChurchMemberApplication::where('institution_id', $institutionId)
            ->with(['reviewer:id,name', 'approvedPerson:id,name'])
            ->orderBy('created_at', 'desc');

        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $applications = $query->paginate(20);

        return response()->json($applications);
    }

    /**
     * Detalhes de uma solicitação específica
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $institutionId = $request->user()->institution_id;

        $application = ChurchMemberApplication::where('institution_id', $institutionId)
            ->with(['reviewer:id,name', 'approvedPerson:id,name'])
            ->findOrFail($id);

        return response()->json($application);
    }

    /**
     * Aprovação da solicitação: cria o membro oficialmente no sistema e atualiza o status
     */
    public function approve(Request $request, int $id): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        $user = $request->user();

        $application = ChurchMemberApplication::where('institution_id', $institutionId)
            ->where('status', 'pendente')
            ->findOrFail($id);

        return DB::transaction(function () use ($application, $institutionId, $user) {
            // Cria ou vincula o registro na tabela de Pessoas (Rol de Membros)
            $person = Person::create([
                'institution_id' => $institutionId,
                'name' => $application->full_name,
                'birth_date' => $application->birth_date,
                'gender' => $application->gender ?: 'M',
                'marital_status' => $application->marital_status ?: 'solteiro',
                'cpf' => $application->cpf,
                'rg' => $application->rg,
                'email' => $application->email,
                'phone' => $application->phone,
                'address' => $application->address,
                'address_number' => $application->address_number,
                'address_complement' => $application->address_complement,
                'neighborhood' => $application->neighborhood,
                'city' => $application->city,
                'state' => $application->state,
                'postal_code' => $application->postal_code,
                'profession' => $application->profession,
                'father_name' => $application->father_name,
                'mother_name' => $application->mother_name,
                'spouse_name' => $application->spouse_name,
                'is_communicant' => $application->is_communicant,
                'ecclesiastical_condition' => $application->ecclesiastical_condition ?: 'comungante',
                'origin_church' => $application->origin_church,
                'reception_mode' => $application->reception_mode ?: 'profissao_fe_batismo',
                'baptism_date' => $application->baptism_date,
                'baptism_church' => $application->baptism_church,
                'profession_of_faith_date' => $application->profession_of_faith_date,
                'notes' => $application->notes,
                'is_active' => true,
            ]);

            $application->update([
                'status' => 'aprovado',
                'reviewed_by_user_id' => $user->id,
                'reviewed_at' => now(),
                'approved_person_id' => $person->id,
            ]);

            AuditLog::create([
                'user_id' => $user->id,
                'institution_id' => $institutionId,
                'action' => 'aprovar_cadastro_membro',
                'entity_type' => 'ChurchMemberApplication',
                'entity_id' => $application->id,
                'details' => json_encode([
                    'person_id' => $person->id,
                    'member_name' => $person->name,
                ]),
            ]);

            return response()->json([
                'message' => 'Solicitação aprovada com sucesso! O membro foi integrado ao Rol de Membros da instituição.',
                'person_id' => $person->id,
                'application' => $application,
            ]);
        });
    }

    /**
     * Rejeição da solicitação com justificativa registrada
     */
    public function reject(Request $request, int $id): JsonResponse
    {
        $institutionId = $request->user()->institution_id;
        $user = $request->user();

        $request->validate([
            'reason' => 'required|string|max:500'
        ]);

        $application = ChurchMemberApplication::where('institution_id', $institutionId)
            ->where('status', 'pendente')
            ->findOrFail($id);

        $application->update([
            'status' => 'rejeitado',
            'reviewed_by_user_id' => $user->id,
            'reviewed_at' => now(),
            'rejection_reason' => $request->input('reason'),
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'institution_id' => $institutionId,
            'action' => 'rejeitar_cadastro_membro',
            'entity_type' => 'ChurchMemberApplication',
            'entity_id' => $application->id,
            'details' => json_encode([
                'reason' => $request->input('reason'),
                'candidate_name' => $application->full_name,
            ]),
        ]);

        return response()->json([
            'message' => 'Solicitação rejeitada.',
            'application' => $application,
        ]);
    }

    private function resolveInstitution(string $slugOrId): ?Institution
    {
        if (is_numeric($slugOrId)) {
            return Institution::find((int) $slugOrId);
        }

        return Institution::where('short_name', $slugOrId)
            ->orWhere('code', $slugOrId)
            ->first();
    }
}
