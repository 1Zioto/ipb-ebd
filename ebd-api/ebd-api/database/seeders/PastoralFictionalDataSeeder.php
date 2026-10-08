<?php

namespace Database\Seeders;

use App\Models\AcompanhamentoDizimo;
use App\Models\AlertaDizimo;
use App\Models\Institution;
use App\Models\Person;
use App\Models\SolicitacaoDiaconato;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class PastoralFictionalDataSeeder extends Seeder
{
    public function run(): void
    {
        $institution = Institution::find(5) ?: Institution::first();
        if (!$institution) {
            return;
        }

        $institutionId = $institution->id;

        $pastor = User::where('institution_id', $institutionId)->where('username', 'admin')->first()
            ?: User::first();
        $pastorId = $pastor ? $pastor->id : 1;

        $people = Person::where('institution_id', $institutionId)->get();
        if ($people->count() < 10) {
            $people = Person::all();
        }

        if ($people->isEmpty()) {
            return;
        }

        $cases = [
            [
                'person_offset' => 1,
                'alert_type' => 'queda_relevante',
                'status' => 'Em acompanhamento',
                'variation_percentage' => -45.50,
                'avg' => 1250.00,
                'detection_date' => '2026-09-15',
                'notes_alert' => 'Redução atípica observada nos últimos 2 meses.',
                'acompanhamentos' => [
                    [
                        'date' => '2026-09-18',
                        'type' => 'Visita Pastoral Domiciliar',
                        'notes' => 'Visita pastoral realizada na residência da família pelo Rev. Carlos Eduardo. O irmão relatou que foi desligado da empresa no final de agosto e está buscando nova colocação no setor de logística. Lemos Filipenses 4:11-19, oramos juntos e ungimos a família. Todos demonstraram fé madura e serenidade.',
                        'next_action' => 'Verificar rede de contatos para oportunidades de trabalho e contatar junta diaconal para apoio preventivo.',
                        'review_date' => '2026-10-15',
                        'status' => 'Em acompanhamento',
                        'conclusion' => null,
                    ],
                    [
                        'date' => '2026-10-02',
                        'type' => 'Contato Telefônico / Oração',
                        'notes' => 'Irmão informou que participou de duas entrevistas de emprego esta semana. Mantendo ânimo e constância nos cultos e na EBD com a esposa e filhos.',
                        'next_action' => 'Acompanhar resultado das entrevistas até meados de outubro.',
                        'review_date' => '2026-10-20',
                        'status' => 'Em acompanhamento',
                        'conclusion' => null,
                    ],
                ],
                'diaconato' => [
                    'notes' => 'Favor realizar visita de carinho e verificar se a família necessita de apoio pontual com cesta de alimentos neste mês de transição profissional.',
                    'status' => 'pendente',
                ],
            ],
            [
                'person_offset' => 3,
                'alert_type' => 'interrupcao_contribuicao',
                'status' => 'Em acompanhamento',
                'variation_percentage' => -100.00,
                'avg' => 850.00,
                'detection_date' => '2026-09-22',
                'notes_alert' => 'Sem registro de contribuição nos últimos 45 dias.',
                'acompanhamentos' => [
                    [
                        'date' => '2026-09-26',
                        'type' => 'Aconselhamento Pastoral no Gabinete',
                        'notes' => 'Conversa pastoral fraterna no gabinete da igreja. A irmã explicou que sua mãe idosa precisou de cirurgia ortopédica de urgência em Vitória, gerando gastos vultosos com medicamentos e internação hospitalar. A irmã pediu orações pela recuperação e reiterou seu compromisso com Deus e a igreja local.',
                        'next_action' => 'Incluir mãe da irmã na escala de oração da SAF e do presbitério.',
                        'review_date' => '2026-10-25',
                        'status' => 'Em acompanhamento',
                        'conclusion' => null,
                    ],
                ],
                'diaconato' => null,
            ],
            [
                'person_offset' => 5,
                'alert_type' => 'queda_relevante',
                'status' => 'Novo',
                'variation_percentage' => -38.20,
                'avg' => 2100.00,
                'detection_date' => '2026-10-01',
                'notes_alert' => 'Variação negativa identificada no fechamento de setembro.',
                'acompanhamentos' => [],
                'diaconato' => null,
            ],
            [
                'person_offset' => 7,
                'alert_type' => 'interrupcao_contribuicao',
                'status' => 'Em análise',
                'variation_percentage' => -100.00,
                'avg' => 600.00,
                'detection_date' => '2026-10-03',
                'notes_alert' => 'Membro ausente das últimas coletas.',
                'acompanhamentos' => [
                    [
                        'date' => '2026-10-05',
                        'type' => 'Mensagem Pastoral',
                        'notes' => 'Pastor enviou mensagem expressando saudade e perguntando pelo bem-estar da família. Aguardando retorno.',
                        'next_action' => 'Ligar para o irmão caso não responda até o próximo domingo.',
                        'review_date' => '2026-10-12',
                        'status' => 'Em análise',
                        'conclusion' => null,
                    ],
                ],
                'diaconato' => null,
            ],
            [
                'person_offset' => 9,
                'alert_type' => 'queda_relevante',
                'status' => 'Resolvido',
                'variation_percentage' => -60.00,
                'avg' => 1800.00,
                'detection_date' => '2026-08-10',
                'notes_alert' => 'Alerta resolvido após esclarecimento pastoral.',
                'acompanhamentos' => [
                    [
                        'date' => '2026-08-14',
                        'type' => 'Reunião Pastoral Presencial',
                        'notes' => 'O irmão informou que passou a concentrar as contribuições através de débito bancário conjunto com a esposa pelo envelope unificado da família. Não há qualquer crise financeira ou pessoal, apenas reorganização das contas do lar.',
                        'next_action' => 'Atualizar ficha de cadastro familiar.',
                        'review_date' => '2026-08-14',
                        'status' => 'Resolvido',
                        'conclusion' => 'Alteração na forma de contribuição',
                    ],
                ],
                'diaconato' => null,
            ],
            [
                'person_offset' => 11,
                'alert_type' => 'queda_relevante',
                'status' => 'Resolvido',
                'variation_percentage' => -50.00,
                'avg' => 950.00,
                'detection_date' => '2026-07-20',
                'notes_alert' => 'Acompanhamento finalizado com êxito.',
                'acompanhamentos' => [
                    [
                        'date' => '2026-07-25',
                        'type' => 'Visita Pastoral',
                        'notes' => 'Visita realizada na residência. Família superou período de transição profissional. Irmão já contratado e estabilizado. Louvor e oração de gratidão a Deus no encerramento.',
                        'next_action' => 'Caso encerrado com ação de graças.',
                        'review_date' => '2026-08-30',
                        'status' => 'Resolvido',
                        'conclusion' => 'Acompanhamento realizado',
                    ],
                ],
                'diaconato' => null,
            ],
            [
                'person_offset' => 13,
                'alert_type' => 'interrupcao_contribuicao',
                'status' => 'Novo',
                'variation_percentage' => -100.00,
                'avg' => 700.00,
                'detection_date' => '2026-10-05',
                'notes_alert' => 'Membro recém-notificado pelo motor de alertas.',
                'acompanhamentos' => [],
                'diaconato' => null,
            ],
        ];

        foreach ($cases as $c) {
            $person = $people->values()[$c['person_offset'] % $people->count()];

            $alerta = AlertaDizimo::updateOrCreate(
                [
                    'person_id' => $person->id,
                    'detection_date' => $c['detection_date'],
                ],
                [
                    'alert_type' => $c['alert_type'],
                    'start_date' => Carbon::parse($c['detection_date'])->subMonths(2)->toDateString(),
                    'variation_percentage' => $c['variation_percentage'],
                    'reference_calculation' => [
                        'reference_average' => $c['avg'],
                        'recent_average' => $c['avg'] * (1 + ($c['variation_percentage'] / 100)),
                        'months_analyzed' => 6,
                    ],
                    'status' => $c['status'],
                    'pastor_id' => $pastorId,
                    'notes' => $c['notes_alert'],
                    'resolved_at' => $c['status'] === 'Resolvido' ? Carbon::parse($c['detection_date'])->addDays(15) : null,
                ]
            );

            // Inserir acompanhamentos
            foreach ($c['acompanhamentos'] as $acomp) {
                AcompanhamentoDizimo::updateOrCreate(
                    [
                        'alerta_id' => $alerta->id,
                        'date' => $acomp['date'],
                    ],
                    [
                        'person_id' => $person->id,
                        'responsible_id' => $pastorId,
                        'type' => $acomp['type'],
                        'notes' => $acomp['notes'],
                        'next_action' => $acomp['next_action'],
                        'review_date' => $acomp['review_date'],
                        'status' => $acomp['status'],
                        'conclusion' => $acomp['conclusion'],
                    ]
                );
            }

            // Inserir solicitação ao Diaconato se houver
            if (!empty($c['diaconato'])) {
                SolicitacaoDiaconato::updateOrCreate(
                    [
                        'person_id' => $person->id,
                        'pastor_id' => $pastorId,
                    ],
                    [
                        'pastor_notes' => $c['diaconato']['notes'],
                        'status' => $c['diaconato']['status'],
                    ]
                );
            }
        }
    }
}
