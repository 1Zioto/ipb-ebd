<?php

namespace Database\Seeders;

use App\Models\AttendanceSession;
use App\Models\ClassRoom;
use App\Models\ClassTeacher;
use App\Models\EbdEvent;
use App\Models\Institution;
use App\Models\Person;
use App\Models\SuperintendentSchedule;
use App\Models\TeacherSchedule;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class SchedulesFictionalDataSeeder extends Seeder
{
    public function run(): void
    {
        $institution = Institution::find(5) ?: Institution::first();
        if (! $institution) {
            $this->command?->error('Nenhuma instituição encontrada.');
            return;
        }

        $institutionId = $institution->id;

        $user = User::where('institution_id', $institutionId)->first() ?: User::first();
        $userId = $user ? $user->id : 1;

        // 1. Cadastrar / Garantir Professores e Superintendentes
        $peopleDefinitions = [
            [
                'full_name' => 'Rev. Carlos Eduardo Silveira',
                'envelope_number' => '001',
                'birth_date' => '1982-04-15',
                'can_teach' => true,
                'can_superintend' => true,
                'notes' => 'Pastor Titular da IP Campo Verde',
            ],
            [
                'full_name' => 'Presb. Marcos Vinícius Toledo',
                'envelope_number' => '002',
                'birth_date' => '1975-08-22',
                'can_teach' => true,
                'can_superintend' => true,
                'notes' => 'Superintendente Geral da EBD',
            ],
            [
                'full_name' => 'Presb. Roberto Alencar Fontes',
                'envelope_number' => '003',
                'birth_date' => '1979-11-03',
                'can_teach' => true,
                'can_superintend' => true,
                'notes' => 'Superintendente Adjunto e Professor de Adultos',
            ],
            [
                'full_name' => 'Diác. André Luiz Ramos',
                'envelope_number' => '004',
                'birth_date' => '1986-02-18',
                'can_teach' => false,
                'can_superintend' => true,
                'notes' => 'Superintendência de Apoio e Logística',
            ],
            [
                'full_name' => 'Diác. Felipe Mendes Bastos',
                'envelope_number' => '005',
                'birth_date' => '1991-09-29',
                'can_teach' => true,
                'can_superintend' => true,
                'notes' => 'Superintendência de Apoio e Professor Substituto',
            ],
            [
                'full_name' => 'Mariana Castro Silveira',
                'envelope_number' => '006',
                'birth_date' => '1984-06-12',
                'can_teach' => true,
                'can_superintend' => false,
                'notes' => 'Professora da Classe de Casais',
            ],
            [
                'full_name' => 'Lucas Gabriel Rocha',
                'envelope_number' => '007',
                'birth_date' => '1998-03-05',
                'can_teach' => true,
                'can_superintend' => false,
                'notes' => 'Líder da Mocidade (UMP) e Professor',
            ],
            [
                'full_name' => 'Beatriz Helena Guimarães',
                'envelope_number' => '008',
                'birth_date' => '1994-07-19',
                'can_teach' => true,
                'can_superintend' => false,
                'notes' => 'Pedagoga e Professora do Berçário & Maternal',
            ],
            [
                'full_name' => 'Paulo Henrique Antunes',
                'envelope_number' => '009',
                'birth_date' => '1970-12-14',
                'can_teach' => true,
                'can_superintend' => true,
                'notes' => 'Professor da Classe Bereana (Adultos)',
            ],
            [
                'full_name' => 'Camila Siqueira Paiva',
                'envelope_number' => '010',
                'birth_date' => '1989-10-30',
                'can_teach' => true,
                'can_superintend' => false,
                'notes' => 'Professora da Classe de Juniores',
            ],
            [
                'full_name' => 'Daniela Martins Prado',
                'envelope_number' => '011',
                'birth_date' => '1993-01-25',
                'can_teach' => true,
                'can_superintend' => false,
                'notes' => 'Professora da Classe de Primários',
            ],
            [
                'full_name' => 'Juliana Freitas Albuquerque',
                'envelope_number' => '013',
                'birth_date' => '1990-05-18',
                'can_teach' => true,
                'can_superintend' => false,
                'notes' => 'Professora da Classe de Adolescentes',
            ],
            [
                'full_name' => 'Ricardo Morais Fontes',
                'envelope_number' => '014',
                'birth_date' => '1985-11-20',
                'can_teach' => true,
                'can_superintend' => false,
                'notes' => 'Professor da Classe de Mocidade / Jovens',
            ],
            [
                'full_name' => 'Renata Vasconcelos Lima',
                'envelope_number' => '015',
                'birth_date' => '1995-03-12',
                'can_teach' => true,
                'can_superintend' => false,
                'notes' => 'Professora Auxiliar dos Primários e Berçário',
            ],
        ];

        $peopleMap = [];
        foreach ($peopleDefinitions as $def) {
            $person = Person::updateOrCreate(
                [
                    'institution_id' => $institutionId,
                    'full_name' => $def['full_name'],
                ],
                [
                    'envelope_number' => $def['envelope_number'],
                    'birth_date' => $def['birth_date'],
                    'can_teach' => $def['can_teach'],
                    'can_superintend' => $def['can_superintend'],
                    'notes' => $def['notes'],
                    'is_active' => true,
                    'is_tither' => true,
                    'tither_since' => '2021-01-01',
                ]
            );
            $peopleMap[$def['full_name']] = $person;
        }

        // 2. Cadastrar / Garantir Classes da EBD
        $classesDefinitions = [
            [
                'name' => 'Berçário & Maternal',
                'age_range' => '0 a 3 anos',
                'description' => 'Primeiros passos na fé com histórias bíblicas ilustradas e cânticos.',
                'display_order' => 1,
                'primary_teachers' => ['Beatriz Helena Guimarães', 'Renata Vasconcelos Lima'],
            ],
            [
                'name' => 'Primários (Cordeirinhos de Cristo)',
                'age_range' => '4 a 6 anos',
                'description' => 'Aprendizado dos princípios bíblicos básicos e memorização de versículos.',
                'display_order' => 2,
                'primary_teachers' => ['Daniela Martins Prado', 'Renata Vasconcelos Lima'],
            ],
            [
                'name' => 'Juniores',
                'age_range' => '7 a 10 anos',
                'description' => 'Histórias dos heróis da fé e cronologia bíblica.',
                'display_order' => 3,
                'primary_teachers' => ['Camila Siqueira Paiva', 'Diác. Felipe Mendes Bastos'],
            ],
            [
                'name' => 'Adolescentes (Embaixadores do Rei)',
                'age_range' => '11 a 14 anos',
                'description' => 'Fundamentos da fé cristã e introdução ao Breve Catecismo.',
                'display_order' => 4,
                'primary_teachers' => ['Juliana Freitas Albuquerque', 'Lucas Gabriel Rocha'],
            ],
            [
                'name' => 'Mocidade (Jovens UMP)',
                'age_range' => '15 a 24 anos',
                'description' => 'Cosmovisão cristã, teologia bíblica e vida cristã na universidade e trabalho.',
                'display_order' => 5,
                'primary_teachers' => ['Lucas Gabriel Rocha', 'Ricardo Morais Fontes'],
            ],
            [
                'name' => 'Adultos (Classe Bereana)',
                'age_range' => '25+ anos',
                'description' => 'Estudo expositivo das Escrituras e doutrinas da graça reformadas.',
                'display_order' => 6,
                'primary_teachers' => ['Paulo Henrique Antunes', 'Presb. Roberto Alencar Fontes'],
            ],
            [
                'name' => 'Casais (Família da Fé)',
                'age_range' => 'Casais',
                'description' => 'Princípios bíblicos para o casamento e edificação do lar cristão.',
                'display_order' => 7,
                'primary_teachers' => ['Mariana Castro Silveira', 'Rev. Carlos Eduardo Silveira'],
            ],
        ];

        $classesMap = [];
        foreach ($classesDefinitions as $cDef) {
            $class = ClassRoom::updateOrCreate(
                [
                    'institution_id' => $institutionId,
                    'name' => $cDef['name'],
                ],
                [
                    'age_range' => $cDef['age_range'],
                    'description' => $cDef['description'],
                    'display_order' => $cDef['display_order'],
                    'is_active' => true,
                ]
            );
            $classesMap[$cDef['name']] = $class;

            // Vincular professores titulares da classe
            foreach ($cDef['primary_teachers'] as $teacherName) {
                if (isset($peopleMap[$teacherName])) {
                    ClassTeacher::firstOrCreate([
                        'class_id' => $class->id,
                        'person_id' => $peopleMap[$teacherName]->id,
                    ], [
                        'is_active' => true,
                    ]);
                }
            }
        }

        // 3. Domingos a serem escalados (Setembro, Outubro e Novembro de 2026)
        $sundays = [
            // Setembro 2026 (concluído)
            '2026-09-06' => ['status' => 'finalizada'],
            '2026-09-13' => ['status' => 'finalizada'],
            '2026-09-20' => ['status' => 'finalizada'],
            '2026-09-27' => ['status' => 'finalizada'],
            // Outubro 2026 (Mês Atual - foco imediato da tela!)
            '2026-10-04' => ['status' => 'finalizada'],
            '2026-10-11' => ['status' => 'pendente'],
            '2026-10-18' => ['status' => 'pendente'],
            '2026-10-25' => ['status' => 'pendente'],
            // Novembro 2026 (planejamento futuro)
            '2026-11-01' => ['status' => 'pendente'],
            '2026-11-08' => ['status' => 'pendente'],
            '2026-11-15' => ['status' => 'pendente'],
            '2026-11-22' => ['status' => 'pendente'],
            '2026-11-29' => ['status' => 'pendente'],
        ];

        // Lista circular de superintendentes para revezamento
        $superintendentsPool = [
            [
                'name' => 'Presb. Marcos Vinícius Toledo',
                'note' => 'Superintendência geral: Abertura solene, oração e avisos da EBD.',
            ],
            [
                'name' => 'Presb. Roberto Alencar Fontes',
                'note' => 'Superintendência e recepção aos novos alunos e visitantes.',
            ],
            [
                'name' => 'Diác. André Luiz Ramos',
                'note' => 'Logística das salas, distribuição de materiais e conferência de presença.',
            ],
            [
                'name' => 'Rev. Carlos Eduardo Silveira',
                'note' => 'Devocional pastoral conjunto no templo antes do início das salas.',
            ],
            [
                'name' => 'Diác. Felipe Mendes Bastos',
                'note' => 'Apoio geral à superintendência e organização do ofertório da EBD.',
            ],
            [
                'name' => 'Paulo Henrique Antunes',
                'note' => 'Superintendência e apresentação do relatório de frequência do trimestre.',
            ],
        ];

        // Roteiro / Temas das lições por classe para alternância de professores
        $classLessonThemes = [
            'Berçário & Maternal' => [
                ['teacher' => 'Beatriz Helena Guimarães', 'theme' => 'Deus Criou o Céu e a Terra (História Ilustrada)'],
                ['teacher' => 'Renata Vasconcelos Lima', 'theme' => 'Noé e o Arco-Íris da Aliança (Cânticos e Fantoches)'],
                ['teacher' => 'Beatriz Helena Guimarães', 'theme' => 'O Menino Jesus no Templo'],
                ['teacher' => 'Renata Vasconcelos Lima', 'theme' => 'A Ovelhinha Perdida e o Bom Pastor'],
            ],
            'Primários (Cordeirinhos de Cristo)' => [
                ['teacher' => 'Daniela Martins Prado', 'theme' => 'Lição 1: Deus Chama Abraão'],
                ['teacher' => 'Renata Vasconcelos Lima', 'theme' => 'Lição 2: José no Egito - Fidelidade e Perdão'],
                ['teacher' => 'Daniela Martins Prado', 'theme' => 'Lição 3: Moisés e a Travessia do Mar Vermelho'],
                ['teacher' => 'Daniela Martins Prado', 'theme' => 'Lição 4: Samuel Ouve a Voz do Senhor'],
            ],
            'Juniores' => [
                ['teacher' => 'Camila Siqueira Paiva', 'theme' => 'Lição 1: Davi e Golias - Confiando no Deus Todo-Poderoso'],
                ['teacher' => 'Diác. Felipe Mendes Bastos', 'theme' => 'Lição 2: Salomão e o Pedido de Sabedoria'],
                ['teacher' => 'Camila Siqueira Paiva', 'theme' => 'Lição 3: Elias e os Profetas de Baal no Monte Carmelo'],
                ['teacher' => 'Camila Siqueira Paiva', 'theme' => 'Lição 4: Daniel e seus Amigos na Babilônia'],
            ],
            'Adolescentes (Embaixadores do Rei)' => [
                ['teacher' => 'Juliana Freitas Albuquerque', 'theme' => 'Lição 1: Quem Sou Eu? Identidade e Autoestima em Cristo'],
                ['teacher' => 'Lucas Gabriel Rocha', 'theme' => 'Lição 2: Amizades, Redes Sociais e Pressão do Grupo'],
                ['teacher' => 'Juliana Freitas Albuquerque', 'theme' => 'Lição 3: Conhecendo o Breve Catecismo - O Fim Principal do Homem'],
                ['teacher' => 'Juliana Freitas Albuquerque', 'theme' => 'Lição 4: Oração e Vida Devocional na Juventude'],
            ],
            'Mocidade (Jovens UMP)' => [
                ['teacher' => 'Lucas Gabriel Rocha', 'theme' => 'Lição 1: Cosmovisão Reformada no Trabalho e na Faculdade'],
                ['teacher' => 'Ricardo Morais Fontes', 'theme' => 'Lição 2: Namoro, Relacionamentos e Pureza Bíblica'],
                ['teacher' => 'Lucas Gabriel Rocha', 'theme' => 'Lição 3: As Cinco Solas na Prática Contemporânea'],
                ['teacher' => 'Ricardo Morais Fontes', 'theme' => 'Lição 4: Engajamento Cultural e Missão Urbana'],
            ],
            'Adultos (Classe Bereana)' => [
                ['teacher' => 'Paulo Henrique Antunes', 'theme' => 'Estudo em Romanos: Justificação pela Fé Somente'],
                ['teacher' => 'Presb. Roberto Alencar Fontes', 'theme' => 'A Soberana Graça na Eleição e Redenção'],
                ['teacher' => 'Paulo Henrique Antunes', 'theme' => 'A Vida no Espírito: Santificação e Luta contra o Pecado'],
                ['teacher' => 'Rev. Carlos Eduardo Silveira', 'theme' => 'A Aliança da Graça e a Família Pactual'],
            ],
            'Casais (Família da Fé)' => [
                ['teacher' => 'Mariana Castro Silveira', 'theme' => 'Lição 1: Comunicação Afetiva e Resolução de Conflitos'],
                ['teacher' => 'Rev. Carlos Eduardo Silveira', 'theme' => 'Lição 2: Papéis Bíblicos do Marido e da Esposa'],
                ['teacher' => 'Mariana Castro Silveira', 'theme' => 'Lição 3: Finanças à Luz da Bíblia e Planejamento Familiar'],
                ['teacher' => 'Mariana Castro Silveira', 'theme' => 'Lição 4: A Educação Cristã dos Filhos em Tempos Desafiadores'],
            ],
        ];

        $sundayIndex = 0;

        foreach ($sundays as $dateStr => $eventMeta) {
            $date = Carbon::parse($dateStr);
            $superInfo = $superintendentsPool[$sundayIndex % count($superintendentsPool)];
            $superPerson = $peopleMap[$superInfo['name']] ?? null;

            // 4. Criar ou Atualizar EbdEvent
            $event = EbdEvent::updateOrCreate(
                [
                    'event_date' => $date->toDateString(),
                    'type' => 'regular',
                ],
                [
                    'institution_id' => $institutionId,
                    'status' => $eventMeta['status'],
                    'is_auto_generated' => false,
                    'created_by' => $userId,
                    'superintendent_person_id' => $superPerson?->id,
                    'superintendent_name_snapshot' => $superPerson?->full_name,
                    'notes' => 'Encontro Regular da EBD em ' . $date->format('d/m/Y'),
                ]
            );

            // 5. Escala de Superintendente (SuperintendentSchedule)
            if ($superPerson) {
                SuperintendentSchedule::updateOrCreate(
                    [
                        'ebd_event_id' => $event->id,
                    ],
                    [
                        'scheduled_person_id' => $superPerson->id,
                        'notes' => $superInfo['note'],
                    ]
                );
            }

            // 6. Escala de Professores para Cada Classe (TeacherSchedule)
            foreach ($classesMap as $className => $classRoom) {
                $lessonList = $classLessonThemes[$className] ?? [];
                if (empty($lessonList)) {
                    continue;
                }

                $lesson = $lessonList[$sundayIndex % count($lessonList)];
                $teacherPerson = $peopleMap[$lesson['teacher']] ?? null;

                if (! $teacherPerson) {
                    continue;
                }

                TeacherSchedule::updateOrCreate(
                    [
                        'ebd_event_id' => $event->id,
                        'class_id' => $classRoom->id,
                    ],
                    [
                        'scheduled_person_id' => $teacherPerson->id,
                        'notes' => $lesson['theme'],
                    ]
                );

                // Garantir AttendanceSession para a classe neste evento
                AttendanceSession::firstOrCreate(
                    [
                        'ebd_event_id' => $event->id,
                        'class_id' => $classRoom->id,
                    ],
                    [
                        'status' => $eventMeta['status'] === 'finalizada' ? 'finalizada' : 'pendente',
                        'teacher_person_id' => $teacherPerson->id,
                        'teacher_name_snapshot' => $teacherPerson->full_name,
                        'class_name_snapshot' => $classRoom->name,
                        'material_mode' => 'individual',
                        'created_by' => $userId,
                    ]
                );
            }

            $sundayIndex++;
        }

        $this->command?->info('Escalas fictícias geradas com sucesso para ' . count($sundays) . ' domingos (Setembro a Novembro de 2026)!');
    }
}
