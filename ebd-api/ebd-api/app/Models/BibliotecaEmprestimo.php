<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BibliotecaEmprestimo extends Model
{
    use HasFactory;

    protected $table = 'biblioteca_emprestimos';

    protected $fillable = [
        'livro_id',
        'person_id',
        'data_emprestimo',
        'data_prevista_devolucao',
        'data_devolucao',
        'status',
        'observacoes',
    ];

    protected function casts(): array
    {
        return [
            'data_emprestimo' => 'date',
            'data_prevista_devolucao' => 'date',
            'data_devolucao' => 'date',
        ];
    }

    public function livro(): BelongsTo
    {
        return $this->belongsTo(BibliotecaLivro::class, 'livro_id');
    }

    public function person(): BelongsTo
    {
        return $this->belongsTo(Person::class, 'person_id');
    }
}
