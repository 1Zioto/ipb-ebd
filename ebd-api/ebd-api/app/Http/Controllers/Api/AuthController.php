<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Resources\UserResource;
use App\Models\AuditLog;
use App\Models\Institution;
use App\Models\InstitutionHistory;
use App\Models\InstitutionLinkRequest;
use App\Models\Role;
use App\Models\User;
use App\Support\Audit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);
        try {
            $user = User::where('username', $request->username)->first();

            if (! $user || ! Hash::check($request->password, $user->password)) {
                throw ValidationException::withMessages([
                    'username' => ['Credenciais inválidas.'],
                ]);
            }

            if (! $user->is_active) {
                throw ValidationException::withMessages([
                    'username' => ['Usuário inativo.'],
                ]);
            }

            $user->forceFill(['last_login_at' => now()])->save();
            $user->load('roles.permissions');

            $token = $user->createToken('api')->plainTextToken;

            try {
                AuditLog::create([
                    'user_id' => $user->id,
                    'action' => 'auth.login',
                    'entity_type' => 'user',
                    'entity_id' => $user->id,
                    'ip' => $request->ip(),
                    'user_agent' => substr((string) $request->userAgent(), 0, 255),
                ]);
            } catch (\Throwable $e) {
                // ignora falha em log de auditoria secundário
            }

            return response()->json([
                'token' => $token,
                'user' => new UserResource($user),
            ]);
        } catch (ValidationException $e) {
            throw $e;
        } catch (\Throwable $e) {
            return response()->json([
                'message' => 'Erro no login: ' . $e->getMessage(),
                'file' => $e->getFile() . ':' . $e->getLine(),
            ], 422);
        }
    }

    public function registerChurch(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'church_name' => 'required|string|max:200',
            'short_name' => 'required|string|max:100',
            'type' => 'nullable|string|max:50',
            'city' => 'nullable|string|max:100',
            'state' => 'nullable|string|max:50',
            'superior_code' => 'nullable|string|max:30',
            'admin_name' => 'required|string|max:150',
            'admin_username' => 'required|string|max:50|unique:users,username',
            'admin_email' => 'nullable|email|max:180',
            'password' => 'required|string|min:6',
        ]);

        try {
            return DB::transaction(function () use ($validated, $request) {
                $type = $validated['type'] ?? 'igreja';

                // 1. Criar a nova instituição
                $institution = Institution::create([
                    'name' => $validated['church_name'],
                    'short_name' => $validated['short_name'],
                    'type' => $type,
                    'status' => 'ativa',
                    'city' => $validated['city'] ?? null,
                    'state' => $validated['state'] ?? null,
                ]);

                // 2. Se informou código de instituição superior, solicitar vínculo
                if (! empty($validated['superior_code'])) {
                    $superior = Institution::where('code', strtoupper(trim($validated['superior_code'])))->first();
                    if ($superior && $superior->id !== $institution->id) {
                        InstitutionLinkRequest::create([
                            'requester_institution_id' => $institution->id,
                            'target_institution_id' => $superior->id,
                            'type' => 'vinculo_superior',
                            'status' => 'pendente',
                            'reason' => 'Solicitação de vínculo enviada durante o cadastro da igreja.',
                        ]);
                    }
                }

                // 3. Criar usuário administrador para a igreja
                $user = User::create([
                    'name' => $validated['admin_name'],
                    'username' => $validated['admin_username'],
                    'email' => $validated['admin_email'] ?? null,
                    'password' => $validated['password'],
                    'institution_id' => $institution->id,
                    'is_active' => true,
                ]);

                // 4. Atribuir papel de superintendência por padrão para gestão total da EBD/igreja
                $role = Role::where('slug', 'superintendencia')->orWhere('name', 'superintendencia')->first();
                if ($role) {
                    $user->roles()->attach($role->id);
                }

                InstitutionHistory::create([
                    'institution_id' => $institution->id,
                    'event_type' => 'criacao',
                    'title' => 'Nova Igreja Cadastrada via Tela de Login',
                    'description' => "Igreja [{$institution->name}] cadastrada com sucesso. Código gerado: {$institution->code}.",
                    'user_id' => $user->id,
                ]);

                AuditLog::create([
                    'user_id' => $user->id,
                    'action' => 'auth.register_church',
                    'entity_type' => 'Institution',
                    'entity_id' => $institution->id,
                    'new_values' => ['institution_name' => $institution->name, 'username' => $user->username],
                    'ip' => $request->ip(),
                    'user_agent' => substr((string) $request->userAgent(), 0, 255),
                ]);

                $user->load('roles.permissions');
                $token = $user->createToken('api')->plainTextToken;

                return response()->json([
                    'message' => 'Igreja e usuário cadastrados com sucesso!',
                    'token' => $token,
                    'user' => new UserResource($user),
                    'institution' => [
                        'id' => $institution->id,
                        'name' => $institution->name,
                        'code' => $institution->code,
                    ],
                ], 201);
            });
        } catch (\Throwable $e) {
            return response()->json([
                'message' => 'Erro ao cadastrar igreja: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function me(Request $request): UserResource
    {
        $request->user()->load('roles.permissions');
        return new UserResource($request->user());
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        Audit::log('auth.logout', 'user', $request->user()->id);
        return response()->json(['message' => 'Sessão encerrada.']);
    }
}
