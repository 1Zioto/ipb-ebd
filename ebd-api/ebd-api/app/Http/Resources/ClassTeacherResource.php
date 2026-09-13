<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ClassTeacherResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'class_id' => $this->class_id,
            'person_id' => $this->person_id,
            'person_name' => $this->whenLoaded('person', fn () => $this->person->full_name),
            'is_active' => $this->is_active,
        ];
    }
}
