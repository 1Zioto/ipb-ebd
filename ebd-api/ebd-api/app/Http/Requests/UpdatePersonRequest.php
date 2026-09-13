<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePersonRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('person'));
    }

    public function rules(): array
    {
        return [
            'full_name' => ['sometimes', 'required', 'string', 'max:180'],
            'birth_date' => ['nullable', 'date', 'before_or_equal:today'],
            'is_active' => ['boolean'],
            'can_teach' => ['boolean'],
            'can_superintend' => ['boolean'],
            'notes' => ['nullable', 'string'],
        ];
    }
}
