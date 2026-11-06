<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChurchAppConfig extends Model
{
    use HasFactory;

    protected $table = 'church_app_configs';

    protected $fillable = [
        'institution_id',
        'modules_config',
    ];

    protected $casts = [
        'modules_config' => 'array',
    ];

    public static function defaultModules(): array
    {
        return [
            'mural' => true,
            'minha_igreja' => true,
            'ebd' => true,
            'biblia_hinario' => true,
            'agenda_eventos' => true,
            'vida_crista' => true,
            'biblioteca' => true,
            'minha_ficha' => true,
            'dizimos_ofertas' => true,
            'prestacao_contas' => true,
            'solicitacoes_secretaria' => true,
        ];
    }

    public function institution(): BelongsTo
    {
        return $this->belongsTo(Institution::class);
    }
}
