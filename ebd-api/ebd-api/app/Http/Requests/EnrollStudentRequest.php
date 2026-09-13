<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class EnrollStudentRequest extends FormRequest
{
    public function authorize(): bool { return $this->user()->hasPermission('enrollment.manage'); }

    public function rules(): array
    {
        return [
            'person_id' => ['required', 'integer', 'exists:people,id'],
            'enrolled_at' => ['nullable', 'date'],
        ];
    }
}
