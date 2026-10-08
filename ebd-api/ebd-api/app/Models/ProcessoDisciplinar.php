<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProcessoDisciplinar extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'processos_disciplinares';

    protected $fillable = [
        'institution_id',
        'person_id',
        'numero_processo',
        'tipo_falta',
        'descricao_falta',
        'medida_disciplinar',
        'data_abertura',
        'data_julgamento',
        'data_restauracao',
        'prazo_meses',
        'relator_presbitero',
        'ata_conselho_id',
        'status',
        'observacoes_pastorais',
    ];

    protected function casts(): array
    {
        return [
            'data_abertura' => 'date',
            'data_julgamento' => 'date',
            'data_restauracao' => 'date',
            'prazo_meses' => 'integer',
        ];
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class);
    }

    public function ataConselho(): BelongsTo
    {
        return $this->belongsTo(AtaConselho::class);
    }
}
