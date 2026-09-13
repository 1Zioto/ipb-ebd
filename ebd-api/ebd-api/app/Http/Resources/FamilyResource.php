<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FamilyResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'institution_id' => $this->institution_id,
            'name' => $this->name,
            'phone' => $this->phone,
            'whatsapp' => $this->whatsapp,
            'email' => $this->email,
            'zipcode' => $this->zipcode,
            'street' => $this->street,
            'number' => $this->number,
            'complement' => $this->complement,
            'district' => $this->district,
            'city' => $this->city,
            'state' => $this->state,
            'notes' => $this->notes,
            'is_active' => $this->is_active,
            'members_count' => $this->whenCounted('members'),
            'members' => $this->whenLoaded('members', fn () => $this->members->map(fn ($person) => [
                'id' => $person->id,
                'full_name' => $person->full_name,
                'birth_date' => $person->birth_date?->toDateString(),
                'age' => $person->age,
                'is_active' => $person->is_active,
                'relationship' => $person->pivot->relationship,
                'is_head' => (bool) $person->pivot->is_head,
            ])->values()),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
