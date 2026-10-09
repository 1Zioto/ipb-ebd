<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
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
            ] : null,
            'is_active' => $this->is_active,
            'is_pastor' => (bool) $this->is_pastor,
            'titulo_pastoral' => $this->titulo_pastoral,
            'cargo_pastoral' => $this->cargo_pastoral,
            'is_pastor_titular' => (bool) $this->is_pastor_titular,
            'roles' => $this->roles->pluck('slug'),
            'role_ids' => $this->roles->pluck('id'),
            'permissions' => $this->permissionSlugs(),
            'is_programmer' => $this->isProgrammer(),
        ];
    }
}
