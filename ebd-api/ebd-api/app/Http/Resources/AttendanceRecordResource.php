<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AttendanceRecordResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'person_id' => $this->person_id,
            'person_name' => $this->person_name_snapshot,
            'present' => $this->present,
            'brought_bible' => $this->brought_bible,
            'brought_magazine' => $this->brought_magazine,
        ];
    }
}
