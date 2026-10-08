<?php

namespace Database\Seeders;

use App\Models\Person;
use App\Models\SolicitacaoDiaconato;
use App\Models\User;
use Illuminate\Database\Seeder;

class DiaconatoFictionalDataSeeder extends Seeder
{
    public function run(): void
    {
        $pastor = User::first();
        $diaconos = User::where('id', '!=', $pastor->id ?? 0)->get();
        if ($diaconos->isEmpty()) {
            $diaconos = collect([$pastor]);
        }

        $fictionalRequests = [
            [
                'person_id' => 2, // Ana Clara Souza
                'pastor_notes' => 'Favor realizar visita de carinho e verificar se a família necessita de apoio pontual com cesta de alimentos neste mês de transição profissional.',
                'status' => 'Em atendimento',
                'diacono_offset' => 0,
                'created_at' => now()->subDays(5),
            ],
            [
                'person_id' => 69, // Beatriz Helena Guimarães
                'pastor_notes' => 'Irmã Beatriz passou por procedimento cirúrgico na semana passada e está convalescendo em casa. Solicito visita de apoio diaconal, oração e verificar se necessita de transporte para a consulta médica de retorno na terça-feira.',
                'status' => 'Pendente',
                'diacono_offset' => null,
                'created_at' => now()->subDays(2),
            ],
            [
                'person_id' => 54, // Carlos Eduardo Lima
                'pastor_notes' => 'A família teve despesas inesperadas com internação infantil e medicamento de alto custo. Favor agendar visita diaconal com discrição para avaliar a possibilidade de subsídio da farmácia básica pela junta diaconal.',
                'status' => 'Em atendimento',
                'diacono_offset' => 1,
                'created_at' => now()->subDays(7),
            ],
            [
                'person_id' => 17, // Bernardo Almeida
                'pastor_notes' => 'Após o último temporal com vendaval, houve destelhamento parcial na residência do irmão Bernardo. A junta diaconal realizou o mutirão no sábado com entrega de telhas e reparo da cobertura.',
                'status' => 'Concluído',
                'diacono_offset' => 0,
                'created_at' => now()->subDays(18),
            ],
            [
                'person_id' => 45, // Bruno Tavares
                'pastor_notes' => 'Internado para exames complementares e tratamento no Hospital Regional. Visita pastoral já realizada; solicitamos aos diáconos de plantão levar uma palavra bíblica de ânimo e suporte à esposa que o acompanha.',
                'status' => 'Em atendimento',
                'diacono_offset' => 0,
                'created_at' => now()->subDays(3),
            ],
            [
                'person_id' => 42, // Amanda Rezende
                'pastor_notes' => 'Irmã Amanda está buscando recolocação profissional após mudança recente. Diaconato já acolheu, incluiu no mural de oportunidades da igreja e intercedeu pelas necessidades da família.',
                'status' => 'Concluído',
                'diacono_offset' => 1,
                'created_at' => now()->subDays(14),
            ],
            [
                'person_id' => 10, // Alice Costa
                'pastor_notes' => 'Irmã idosa residindo sozinha. Solicito que a equipe diaconal inclua em sua escala quinzenal de visitas e oração, prestando assistência nas pequenas demandas domésticas.',
                'status' => 'Pendente',
                'diacono_offset' => null,
                'created_at' => now()->subDay(),
            ],
            [
                'person_id' => 30, // Cecília Monteiro
                'pastor_notes' => 'Família acolheu parentes do interior para tratamento de saúde na cidade. Diaconato realizou contato fraterno e disponibilizou apoio de transporte e acolhimento comunitário.',
                'status' => 'Concluído',
                'diacono_offset' => 0,
                'created_at' => now()->subDays(25),
            ],
        ];

        foreach ($fictionalRequests as $item) {
            $person = Person::find($item['person_id']);
            if (!$person) {
                continue;
            }

            $diacono = null;
            if ($item['diacono_offset'] !== null && $diaconos->isNotEmpty()) {
                $idx = $item['diacono_offset'] % $diaconos->count();
                $diacono = $diaconos[$idx];
            }

            // Atualiza existente ou cria nova
            $existing = SolicitacaoDiaconato::where('person_id', $person->id)->first();
            if ($existing) {
                $existing->update([
                    'pastor_notes' => $item['pastor_notes'],
                    'status' => $item['status'],
                    'diacono_id' => $diacono?->id ?? $existing->diacono_id,
                ]);
            } else {
                SolicitacaoDiaconato::create([
                    'institution_id' => $person->institution_id ?? 5,
                    'person_id' => $person->id,
                    'pastor_id' => $pastor->id ?? 1,
                    'diacono_id' => $diacono?->id,
                    'pastor_notes' => $item['pastor_notes'],
                    'status' => $item['status'],
                    'created_at' => $item['created_at'],
                    'updated_at' => now(),
                ]);
            }
        }
    }
}
