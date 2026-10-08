<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ParecerExameContas extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'pareceres_exame_contas';

    protected $fillable = [
        'institution_id',
        'numero_parecer',
        'ano_exercicio',
        'periodo',
        'data_emissao',
        'relator',
        'membros_comissao',
        'resultado',
        'total_receitas_auditado',
        'total_despesas_auditado',
        'saldo_apurado',
        'conformidade_livro_caixa',
        'conformidade_extratos_bancarios',
        'conformidade_comprovantes_fiscais',
        'conformidade_cotas_conciliares',
        'ressalvas_e_recomendacoes',
        'texto_conclusao',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'ano_exercicio' => 'integer',
            'data_emissao' => 'date',
            'membros_comissao' => 'array',
            'total_receitas_auditado' => 'decimal:2',
            'total_despesas_auditado' => 'decimal:2',
            'saldo_apurado' => 'decimal:2',
            'conformidade_livro_caixa' => 'boolean',
            'conformidade_extratos_bancarios' => 'boolean',
            'conformidade_comprovantes_fiscais' => 'boolean',
            'conformidade_cotas_conciliares' => 'boolean',
        ];
    }
}
