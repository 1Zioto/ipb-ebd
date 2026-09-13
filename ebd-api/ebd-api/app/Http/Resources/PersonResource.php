<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PersonResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'full_name' => $this->full_name,
            'birth_date' => $this->birth_date?->toDateString(),
            'age' => $this->age,
            'is_active' => $this->is_active,
            'can_teach' => $this->can_teach,
            'can_superintend' => $this->can_superintend,
            'notes' => $this->notes,
            'family' => $this->whenLoaded('families', fn () => $this->families->first() ? [
                'id' => $this->families->first()->id,
                'name' => $this->families->first()->name,
                'relationship' => $this->families->first()->pivot->relationship,
                'is_head' => (bool) $this->families->first()->pivot->is_head,
            ] : null),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
