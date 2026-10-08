<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Permission;
use App\Models\Role;
use App\Models\User;
use App\Support\Audit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SystemAdminController extends Controller
{
    public function users(Request $request)
    {
        $users = User::query()->with('roles.permissions')->orderBy('name')->paginate(50);
        return UserResource::collection($users);
    }

    public function storeUser(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:180'],
            'username' => ['required', 'string', 'max:80', 'regex:/^[a-zA-Z0-9._-]+$/', 'unique:users,username'],
            'email' => ['nullable', 'email', 'max:180', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'person_id' => ['nullable', 'integer', 'exists:people,id'],
            'is_active' => ['boolean'],
            'role_ids' => ['required', 'array', 'min:1'],
            'role_ids.*' => ['integer', 'exists:roles,id'],
        ]);
        $roleIds = $data['role_ids'];
        unset($data['role_ids']);
        $user = User::create($data);
        $user->roles()->sync($roleIds);
        Audit::log('user.created', 'user', $user->id, null, ['name' => $user->name, 'roles' => $roleIds]);
        return (new UserResource($user->load('roles.permissions')))->response()->setStatusCode(201);
    }

    public function updateUser(Request $request, User $user)
    {
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:180'],
            'username' => ['sometimes', 'required', 'string', 'max:80', 'regex:/^[a-zA-Z0-9._-]+$/', Rule::unique('users')->ignore($user->id)],
            'email' => ['nullable', 'email', 'max:180', Rule::unique('users')->ignore($user->id)],
            'password' => ['nullable', 'string', 'min:8'],
            'person_id' => ['nullable', 'integer', 'exists:people,id'],
            'is_active' => ['boolean'],
            'role_ids' => ['sometimes', 'array', 'min:1'],
            'role_ids.*' => ['integer', 'exists:roles,id'],
        ]);
        if ($request->user()->is($user) && array_key_exists('is_active', $data) && ! $data['is_active']) {
            return response()->json(['message' => 'Você não pode desativar seu próprio usuário.'], 422);
        }
        $old = ['name' => $user->name, 'username' => $user->username, 'is_active' => $user->is_active, 'roles' => $user->roles()->pluck('roles.id')->all()];
        $roleIds = $data['role_ids'] ?? null;
        unset($data['role_ids']);
        if (empty($data['password'])) unset($data['password']);
        $user->update($data);
        if ($roleIds !== null) $user->roles()->sync($roleIds);
        Audit::log('user.updated', 'user', $user->id, $old, ['name' => $user->name, 'username' => $user->username, 'is_active' => $user->is_active, 'roles' => $roleIds]);
        return new UserResource($user->load('roles.permissions'));
    }

    public function destroyUser(Request $request, User $user): JsonResponse
    {
        if ($request->user()->is($user)) {
            return response()->json(['message' => 'Você não pode excluir seu próprio usuário.'], 422);
        }

        if ($user->roles()->where('slug', 'programador')->exists()) {
            $otherProgrammers = User::whereHas('roles', fn ($q) => $q->where('slug', 'programador'))
                ->where('id', '!=', $user->id)
                ->where('is_active', true)
                ->count();
            if ($otherProgrammers === 0) {
                return response()->json(['message' => 'Não é permitido excluir o único usuário com papel Programador.'], 422);
            }
        }

        Audit::log('user.deleted', 'user', $user->id, [
            'name' => $user->name,
            'username' => $user->username,
            'email' => $user->email,
        ], null);

        $user->delete();

        return response()->json(['message' => 'Usuário excluído com sucesso.']);
    }

    public function roles(): JsonResponse
    {
        return response()->json(Role::with('permissions:id,name,slug')->orderBy('name')->get());
    }

    public function permissions(): JsonResponse
    {
        return response()->json(Permission::orderBy('name')->get(['id', 'name', 'slug']));
    }

    public function updateRole(Request $request, Role $role): JsonResponse
    {
        if ($role->slug === 'programador') {
            return response()->json(['message' => 'As permissões do papel Programador são protegidas.'], 422);
        }
        $data = $request->validate(['permission_ids' => ['required', 'array'], 'permission_ids.*' => ['integer', 'exists:permissions,id']]);
        $old = $role->permissions()->pluck('permissions.id')->all();
        $role->permissions()->sync($data['permission_ids']);
        Audit::log('role.permissions.updated', 'role', $role->id, ['permissions' => $old], ['permissions' => $data['permission_ids']]);
        return response()->json($role->load('permissions:id,name,slug'));
    }
}
