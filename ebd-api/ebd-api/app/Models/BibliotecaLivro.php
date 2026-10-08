<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class BibliotecaLivro extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'biblioteca_livros';

    protected $fillable = [
        'institution_id',
        'titulo',
        'autor',
        'categoria',
        'editora',
        'ano',
        'isbn',
        'quantidade_total',
        'quantidade_disponivel',
        'localizacao',
    ];

    public function emprestimos(): HasMany
    {
        return $this->hasMany(BibliotecaEmprestimo::class, 'livro_id');
    }
}
