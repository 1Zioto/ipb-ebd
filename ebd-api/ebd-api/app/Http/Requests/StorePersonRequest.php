<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePersonRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', \App\Models\Person::class);
    }

    public function rules(): array
    {
        return [
            'full_name' => ['required', 'string', 'max:180'],
            'birth_date' => ['nullable', 'date', 'before_or_equal:today'],
            'is_active' => ['boolean'],
            'can_teach' => ['boolean'],
            'can_superintend' => ['boolean'],
            'notes' => ['nullable', 'string'],
        ];
    }
}
