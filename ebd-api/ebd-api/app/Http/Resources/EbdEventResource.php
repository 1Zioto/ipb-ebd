<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EbdEventResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'event_date' => $this->event_date?->toDateString(),
            'type' => $this->type,
            'status' => $this->status,
            'is_auto_generated' => $this->is_auto_generated,
            'superintendent_person_id' => $this->superintendent_person_id,
            'superintendent_name' => $this->superintendent_name_snapshot,
            'notes' => $this->notes,
            'sessions_count' => $this->whenCounted('sessions'),
            'sessions' => SessionResource::collection($this->whenLoaded('sessions')),
            'created_at' => $this->created_at,
        ];
    }
}
