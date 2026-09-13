<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAdhocEventRequest extends FormRequest
{
    public function authorize(): bool { return $this->user()->hasPermission('event.create_adhoc'); }

    public function rules(): array
    {
        return [
            'event_date' => ['required', 'date'],
            'type' => ['required', 'in:regular,especial,evento,outro'],
            'notes' => ['nullable', 'string'],
            'class_ids' => ['nullable', 'array'],
            'class_ids.*' => ['integer', 'exists:classes,id'],
        ];
    }
}
