<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $roles = $this->roles->pluck('slug')->all();
        $permissions = $this->permissionSlugs();

        // Usuário possui acesso à Gestão se tiver papéis administrativos ou permissões atribuídas
        $managementRoles = [
            'admin', 'pastor', 'presbitero', 'diacono', 'superintendente',
            'professor', 'tesoureiro', 'secretario', 'conselho', 'diretoria',
        ];
        $hasManagementAccess = count(array_intersect($roles, $managementRoles)) > 0
            || count($permissions) > 0
            || $this->isProgrammer();

        $availableContexts = ['personal'];
        if ($hasManagementAccess) {
            $availableContexts[] = 'management';
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'username' => $this->username,
            'email' => $this->email,
            'person_id' => $this->person_id,
            'institution_id' => $this->institution_id,
            'institution' => $this->institution ? [
                'id' => $this->institution->id,
                'name' => $this->institution->name,
                'short_name' => $this->institution->short_name,
                'type' => $this->institution->type,
                'code' => $this->institution->code,
                'logo' => $this->institution->logo,
                'cover_image' => $this->institution->cover_image,
                'primary_color' => $this->institution->primary_color ?? '#047857',
                'secondary_color' => $this->institution->secondary_color ?? '#065F46',
                'accent_color' => $this->institution->accent_color ?? '#10B981',
            ] : null,
            'has_management_access' => $hasManagementAccess,
            'available_contexts' => $availableContexts,
            'is_active' => $this->is_active,
            'is_pastor' => (bool) $this->is_pastor,
            'titulo_pastoral' => $this->titulo_pastoral,
            'cargo_pastoral' => $this->cargo_pastoral,
            'is_pastor_titular' => (bool) $this->is_pastor_titular,
            'role' => $roles[0] ?? 'membro',
            'roles' => $roles,
            'role_ids' => $this->roles->pluck('id'),
            'permissions' => $permissions,
            'is_programmer' => $this->isProgrammer(),
        ];
    }
}
