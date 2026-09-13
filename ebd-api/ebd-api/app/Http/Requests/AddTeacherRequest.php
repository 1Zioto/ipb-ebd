<?php

namespace App\Http\Requests;

use App\Models\Person;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class AddTeacherRequest extends FormRequest
{
    public function authorize(): bool { return $this->user()->hasPermission('class.manage'); }

    public function rules(): array
    {
        return [
            'person_id' => ['required', 'integer', 'exists:people,id'],
        ];
    }

    /** RN-03: só pessoas habilitadas (can_teach) podem ser professoras. */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function ($v) {
            $person = Person::find($this->input('person_id'));
            if ($person && ! $person->can_teach) {
                $v->errors()->add('person_id', 'Esta pessoa não está habilitada como professora (can_teach).');
            }
        });
    }
}
