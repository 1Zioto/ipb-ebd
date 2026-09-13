<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EnrollmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'class_id' => $this->class_id,
            'person_id' => $this->person_id,
            'person_name' => $this->whenLoaded('person', fn () => $this->person->full_name),
            'age' => $this->whenLoaded('person', fn () => $this->person->age),
            'enrolled_at' => $this->enrolled_at?->toDateString(),
            'unenrolled_at' => $this->unenrolled_at?->toDateString(),
            'is_active' => $this->is_active,
        ];
    }
}
