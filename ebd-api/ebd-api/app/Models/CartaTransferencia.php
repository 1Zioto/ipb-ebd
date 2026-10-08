<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CartaTransferencia extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'cartas_transferencia';

    protected $fillable = [
        'institution_id',
        'numero_carta',
        'tipo',
        'person_id',
        'igreja_origem',
        'igreja_destino',
        'cidade_uf',
        'data_emissao',
        'data_validade',
        'data_recebimento',
        'observacoes',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'data_emissao' => 'date',
            'data_validade' => 'date',
            'data_recebimento' => 'date',
        ];
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
    }
}
