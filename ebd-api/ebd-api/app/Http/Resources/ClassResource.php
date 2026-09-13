<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ClassResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'age_range' => $this->age_range,
            'display_order' => $this->display_order,
            'is_active' => $this->is_active,
            'students_count' => $this->whenCounted('students'),
            'teachers_count' => $this->whenCounted('teachers'),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
