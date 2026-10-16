<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SociedadeInterna extends Model
{
    use BelongsToInstitution, HasFactory;

    protected $table = 'sociedades_internas';

    protected $fillable = [
        'institution_id',
        'sigla',
        'nome',
        'lema',
        'faixa_etaria',
        'target_gender',
        'min_age',
        'max_age',
        'is_active',
        'notes',
        'financial_cost_center_id',
        'ano_exercicio',
    ];

    protected $casts = [
        'min_age' => 'integer',
        'max_age' => 'integer',
        'is_active' => 'boolean',
        'ano_exercicio' => 'integer',
    ];

    /**
     * Avalia a elegibilidade de uma pessoa em relação ao perfil de referência da sociedade.
     * Os limites são meramente referenciais e NÃO bloqueiam inclusão ou permanência.
     */
    public function evaluateEligibility(?Person $person): array
    {
        if (!$person) {
            return [
                'is_eligible' => false,
                'status' => 'desconhecido',
                'label' => 'Pessoa não encontrada',
                'reasons' => ['Pessoa não informada'],
            ];
        }

        $reasons = [];
        $status = 'dentro';

        // 1. Gênero
        $targetGender = $this->target_gender ?? 'Ambos';
        if ($targetGender !== 'Ambos' && !empty($person->gender) && strcasecmp($person->gender, $targetGender) !== 0) {
            $reasons[] = "Sexo ({$person->gender}) diverge do público de referência ({$targetGender})";
            $status = 'fora_genero';
        }

        // 2. Idade
        $age = $person->age;
        if ($age === null) {
            $reasons[] = 'Data de nascimento não informada';
            if ($status === 'dentro') {
                $status = 'sem_nascimento';
            }
        } else {
            if ($this->min_age !== null && $age < $this->min_age) {
                $reasons[] = "Idade ({$age} anos) abaixo da idade mínima ({$this->min_age} anos)";
                $status = 'abaixo_faixa';
            } elseif ($this->max_age !== null && $age > $this->max_age) {
                $reasons[] = "Idade ({$age} anos) acima da idade máxima ({$this->max_age} anos)";
                $status = 'acima_faixa';
            }
        }

        return [
            'is_eligible' => empty($reasons),
            'status' => $status,
            'label' => match ($status) {
                'dentro' => 'Dentro da faixa',
                'acima_faixa' => 'Acima da faixa',
                'abaixo_faixa' => 'Abaixo da faixa',
                'fora_genero' => 'Fora do público-alvo',
                'sem_nascimento' => 'Idade não informada',
                default => 'Fora de referência',
            },
            'reasons' => $reasons,
        ];
    }

    public function diretorias(): HasMany
    {
        return $this->hasMany(SociedadeDiretoria::class, 'sociedade_id');
    }

    public function atividades(): HasMany
    {
        return $this->hasMany(SociedadeAtividade::class, 'sociedade_id');
    }

    public function membros(): HasMany
    {
        return $this->hasMany(SociedadeMembro::class, 'sociedade_id');
    }

    public function atas(): HasMany
    {
        return $this->hasMany(SociedadeAta::class, 'sociedade_id');
    }

    public function costCenter(): BelongsTo
    {
        return $this->belongsTo(FinancialCostCenter::class, 'financial_cost_center_id');
    }
}
