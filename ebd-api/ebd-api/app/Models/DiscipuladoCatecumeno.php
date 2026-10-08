<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DiscipuladoCatecumeno extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'discipulado_catecumenos';

    protected $fillable = [
        'institution_id',
        'person_id',
        'mentor_id',
        'fase',
        'data_inicio',
        'data_conclusao',
        'licoes_concluidas',
        'total_licoes',
        'observacoes',
    ];

    protected function casts(): array
    {
        return [
            'data_inicio' => 'date',
            'data_conclusao' => 'date',
            'licoes_concluidas' => 'integer',
            'total_licoes' => 'integer',
        ];
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
    }

    public function mentor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'mentor_id');
    }
}
