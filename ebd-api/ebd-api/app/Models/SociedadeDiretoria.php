<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SociedadeDiretoria extends Model
{
    use HasFactory;

    protected $table = 'sociedade_diretoria';

    protected $fillable = [
        'sociedade_id',
        'cargo',
        'person_id',
        'ano',
    ];

    public function sociedade(): BelongsTo
    {
        return $this->belongsTo(SociedadeInterna::class, 'sociedade_id');
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
    }
}
