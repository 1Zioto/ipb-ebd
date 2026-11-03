<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\AuditLog;
use App\Models\Institution;
use App\Models\InstitutionHistory;
use App\Models\InstitutionLinkRequest;
use App\Models\Role;
use App\Models\User;
use App\Models\UserDevice;
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
            'device_name' => 'nullable|string|max:120',
            'platform' => 'nullable|string|max:50',
            'client_version' => 'nullable|string|max:30',
        ]);

        try {
            $login = $request->username;
            $user = User::where('username', $login)->orWhere('email', $login)->first();

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
            $user->load('roles.permissions', 'institution', 'person');

            $token = $user->createToken('api')->plainTextToken;
            $tokenId = $user->tokens()->latest('id')->first()?->id;

            // Registra ou atualiza o dispositivo da sessão
            try {
                UserDevice::create([
                    'user_id' => $user->id,
                    'token_id' => $tokenId,
                    'device_name' => $request->device_name ?? 'Navegador Web / Dispositivo',
                    'platform' => $request->platform ?? 'web',
                    'client_version' => $request->client_version ?? '1.1.3',
                    'ip_address' => $request->ip(),
                    'user_agent' => substr((string) $request->userAgent(), 0, 255),
                    'last_active_at' => now(),
                    'is_revoked' => false,
                ]);
            } catch (\Throwable $e) {
                // ignora falha em registro de dispositivo secundário
            }

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
            'admin_email' => 'required|email|max:150|unique:users,email',
            'admin_username' => 'required|string|max:50|unique:users,username',
            'admin_password' => 'required|string|min:6',
        ]);

        try {
            return DB::transaction(function () use ($validated, $request) {
                $type = $validated['type'] ?? 'igreja_local';

                $parentInstitution = null;
                if (! empty($validated['superior_code'])) {
                    $parentInstitution = Institution::where('code', $validated['superior_code'])->first();
                }

                $institution = Institution::create([
                    'name' => $validated['church_name'],
                    'short_name' => $validated['short_name'],
                    'type' => $type,
                    'city' => $validated['city'] ?? null,
                    'state' => $validated['state'] ?? null,
                    'parent_institution_id' => $parentInstitution?->id,
                    'status' => 'active',
                ]);

                if ($parentInstitution) {
                    InstitutionHistory::create([
                        'institution_id' => $institution->id,
                        'event_type' => 'criacao',
                        'description' => "Cadastrada com vínculo superior à instituição [{$parentInstitution->name}]",
                        'registered_by' => 'Auto-registro',
                    ]);

                    InstitutionLinkRequest::create([
                        'requester_institution_id' => $institution->id,
                        'target_institution_id' => $parentInstitution->id,
                        'status' => 'pending',
                        'message' => 'Solicitação automática gerada no cadastro da igreja/congregação.',
                    ]);
                } else {
                    InstitutionHistory::create([
                        'institution_id' => $institution->id,
                        'event_type' => 'criacao',
                        'description' => 'Cadastrada no sistema de forma autônoma.',
                        'registered_by' => 'Auto-registro',
                    ]);
                }

                $adminRole = Role::firstOrCreate(
                    ['slug' => 'admin'],
                    ['name' => 'Administrador Geral', 'description' => 'Acesso total']
                );

                $user = User::create([
                    'name' => $validated['admin_name'],
                    'email' => $validated['admin_email'],
                    'username' => $validated['admin_username'],
                    'password' => Hash::make($validated['admin_password']),
                    'institution_id' => $institution->id,
                    'is_active' => true,
                    'last_login_at' => now(),
                ]);

                $user->roles()->attach($adminRole->id);

                AuditLog::create([
                    'user_id' => $user->id,
                    'action' => 'institution.self_registered',
                    'entity_type' => 'institution',
                    'entity_id' => $institution->id,
                    'ip' => $request->ip(),
                    'user_agent' => substr((string) $request->userAgent(), 0, 255),
                ]);

                $user->load('roles.permissions', 'institution');
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
        $request->user()->load('roles.permissions', 'institution', 'person');
        return new UserResource($request->user());
    }

    public function logout(Request $request): JsonResponse
    {
        $tokenId = $request->user()->currentAccessToken()?->id;
        if ($tokenId) {
            UserDevice::where('token_id', $tokenId)->update(['is_revoked' => true]);
            $request->user()->currentAccessToken()->delete();
        }
        Audit::log('auth.logout', 'user', $request->user()->id);
        return response()->json(['message' => 'Sessão encerrada com sucesso.']);
    }

    /**
     * Alterna entre os contextos: 'personal' (Área Pessoal) e 'management' (Gestão).
     */
    public function switchContext(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'context' => 'required|string|in:personal,management',
        ]);

        $user = $request->user();
        $roles = $user->roles->pluck('slug')->all();
        $permissions = $user->permissionSlugs();

        $managementRoles = [
            'admin', 'pastor', 'presbitero', 'diacono', 'superintendente',
            'professor', 'tesoureiro', 'secretario', 'conselho', 'diretoria',
        ];
        $hasManagementAccess = count(array_intersect($roles, $managementRoles)) > 0
            || count($permissions) > 0
            || $user->isProgrammer();

        if ($validated['context'] === 'management' && ! $hasManagementAccess) {
            return response()->json([
                'message' => 'Acesso negado ao contexto de Gestão. O usuário possui apenas acesso à Área Pessoal.',
            ], 403);
        }

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'auth.switch_context',
            'entity_type' => 'user',
            'entity_id' => $user->id,
            'ip' => $request->ip(),
            'user_agent' => substr((string) $request->userAgent(), 0, 255),
        ]);

        return response()->json([
            'active_context' => $validated['context'],
            'message' => 'Contexto alternado com sucesso para: ' . ($validated['context'] === 'management' ? 'Gestão Eclesiástica' : 'Área Pessoal'),
        ]);
    }
}
