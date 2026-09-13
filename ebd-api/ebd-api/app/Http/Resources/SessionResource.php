<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SessionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'ebd_event_id' => $this->ebd_event_id,
            'class_id' => $this->class_id,
            'class_name' => $this->class_name_snapshot,
            'status' => $this->status,
            'status_reason' => $this->status_reason,
            'teacher_person_id' => $this->teacher_person_id,
            'teacher_name' => $this->teacher_name_snapshot,
            'material_mode' => $this->material_mode,
            'bibles_total' => $this->bibles_total,
            'magazines_total' => $this->magazines_total,
            'merged_into_class_id' => $this->merged_into_class_id,
            'finalized_at' => $this->finalized_at,
        ];
    }
}
