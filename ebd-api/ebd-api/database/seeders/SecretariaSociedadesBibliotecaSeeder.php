<?php

namespace Database\Seeders;

use App\Models\AtaConselho;
use App\Models\BibliotecaEmprestimo;
use App\Models\BibliotecaLivro;
use App\Models\CartaTransferencia;
use App\Models\DiscipuladoCatecumeno;
use App\Models\FinancialCostCenter;
use App\Models\Institution;
use App\Models\Person;
use App\Models\SociedadeAtividade;
use App\Models\SociedadeAta;
use App\Models\SociedadeDiretoria;
use App\Models\SociedadeInterna;
use App\Models\SociedadeMembro;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class SecretariaSociedadesBibliotecaSeeder extends Seeder
{
    public function run(): void
    {
        $institution = Institution::find(5) ?: Institution::first();
        if (!$institution) {
            return;
        }
        $instId = $institution->id;

        $pastor = User::where('institution_id', $instId)->where('username', 'admin')->first() ?: User::first();
        $pastorId = $pastor ? $pastor->id : 1;

        $people = Person::where('institution_id', $instId)->get();
        if ($people->count() < 10) {
            $people = Person::all();
        }

        // 1. Atualizar e enriquecer pessoas com dados canônicos
        $totalPeople = $people->count();
        $rollCounter = 101;

        foreach ($people as $index => $person) {
            $status = 'comungante';
            $receptionType = 'profissao_fe_batismo';
            $exitType = null;
            $exitDate = null;

            if ($index === $totalPeople - 1) {
                $status = 'falecido';
                $exitType = 'Falecimento';
                $exitDate = Carbon::create(2026, 3, 14);
            } elseif ($index === $totalPeople - 2) {
                $status = 'sob_disciplina';
            } elseif ($index % 5 === 0) {
                $status = 'nao_comungante';
                $receptionType = 'batismo_infantil';
            } elseif ($index % 4 === 0) {
                $status = 'comungante';
                $receptionType = 'transferencia';
            }

            $person->canonical_status = $status;
            $person->roll_number = 'ROL-' . str_pad($rollCounter++, 4, '0', STR_PAD_LEFT);
            $person->reception_type = $receptionType;
            $person->reception_date = Carbon::create(2020 + ($index % 6), (($index * 2) % 12) + 1, 10);
            $person->baptism_date = Carbon::create(2015 + ($index % 10), 5, 20);
            if ($status === 'comungante') {
                $person->profession_date = Carbon::create(2020 + ($index % 6), (($index * 2) % 12) + 1, 10);
            }
            $person->exit_type = $exitType;
            $person->exit_date = $exitDate;
            $person->marital_status = ($index % 2 === 0) ? 'Casado(a)' : 'Solteiro(a)';
            if ($index % 2 === 0) {
                $person->spouse_name = 'Cônjuge de ' . explode(' ', $person->full_name)[0];
                $person->marriage_date = Carbon::create(2018, 7, 15);
            }
            $person->phone = '(66) 99' . rand(1000, 9999) . '-' . rand(1000, 9999);
            $person->email = strtolower(str_replace(' ', '.', $person->full_name)) . '@ipb.org.br';
            $person->cpf = sprintf('%03d.%03d.%03d-%02d', rand(100, 999), rand(100, 999), rand(100, 999), rand(10, 99));
            $person->save();
        }

        // 2. Atas do Conselho (Livro de Atas Digital)
        $atas = [
            [
                'institution_id' => $instId,
                'numero_ata' => 'Ata nº 102/2026',
                'tipo' => 'Ordinária',
                'data_reuniao' => Carbon::create(2026, 1, 18),
                'horario' => '19:30',
                'local' => 'Gabinete Pastoral / Sala do Conselho',
                'pastor_presidente' => 'Rev. Marcos Silva',
                'secretario_conselho' => 'Presb. José Carlos Prado',
                'presbiters_presentes' => ['Presb. José Carlos Prado', 'Presb. Antônio Mendes', 'Presb. Roberto Almeida'],
                'abertura' => 'O Rev. Marcos abriu os trabalhos com leitura do Salmo 122 e oração pelo rebanho e pelas famílias da comunidade.',
                'pauta' => '1. Leitura e aprovação da ata anterior; 2. Exame do movimento financeiro de encerramento do exercício de 2025; 3. Planejamento do calendário de atividades da EBD e Sociedades Internas para 2026.',
                'deliberacoes' => 'O Conselho APROVOU por unanimidade as contas do exercício findo, congratulando a Tesouraria. Deliberou ainda a aprovação do calendário geral de atividades de 2026, com foco na revitalização da UMP e fortalecimento da SAF.',
                'status' => 'Assinada',
            ],
            [
                'institution_id' => $instId,
                'numero_ata' => 'Ata nº 103/2026',
                'tipo' => 'Extraordinária',
                'data_reuniao' => Carbon::create(2026, 2, 22),
                'horario' => '20:00',
                'local' => 'Templo Principal',
                'pastor_presidente' => 'Rev. Marcos Silva',
                'secretario_conselho' => 'Presb. José Carlos Prado',
                'presbiters_presentes' => ['Presb. José Carlos Prado', 'Presb. Antônio Mendes', 'Presb. Roberto Almeida', 'Presb. Fernando Dias'],
                'abertura' => 'Invocação da bênção do Senhor mediante oração feita pelo Presb. Antônio Mendes e hino 94 do Novo Cântico.',
                'pauta' => 'Exame e recepção de irmãos candidatos à Profissão de Fé e Batismo, oriundos da classe de catecúmenos.',
                'deliberacoes' => 'Examinados os irmãos sobre sua fé nas Escrituras Sagradas, nos Símbolos de Fé de Westminster e sua disposição em se submeter ao governo da Igreja de Cristo, o Conselho deliberou por unanimidade recebê-los em plena comunhão, marcando a cerimônia para o próximo domingo.',
                'status' => 'Aprovada',
            ],
            [
                'institution_id' => $instId,
                'numero_ata' => 'Ata nº 104/2026',
                'tipo' => 'Ordinária',
                'data_reuniao' => Carbon::create(2026, 3, 15),
                'horario' => '19:30',
                'local' => 'Gabinete Pastoral',
                'pastor_presidente' => 'Rev. Marcos Silva',
                'secretario_conselho' => 'Presb. José Carlos Prado',
                'presbiters_presentes' => ['Presb. José Carlos Prado', 'Presb. Roberto Almeida', 'Presb. Fernando Dias'],
                'abertura' => 'O Presidente declarou aberta a sessão com leitura de Efésios 4:1-16 e oração de intercessão pelos enfermos.',
                'pauta' => '1. Expediente da Secretaria: pedido de Carta de Transferência; 2. Reforma das salas do departamento infantil da EBD.',
                'deliberacoes' => 'O Conselho concedeu com recomendação fraternal a Carta de Transferência solicitada. Autorizou a Tesouraria a despender até R$ 8.500,00 para aquisição de mobiliário e pintura das salas da UCP e EBD.',
                'status' => 'Assinada',
            ],
        ];

        foreach ($atas as $ataData) {
            AtaConselho::firstOrCreate(
                ['institution_id' => $instId, 'numero_ata' => $ataData['numero_ata']],
                $ataData
            );
        }

        // 3. Cartas de Transferência
        if ($people->count() >= 3) {
            $cartas = [
                [
                    'institution_id' => $instId,
                    'numero_carta' => 'CT-012/2026',
                    'tipo' => 'Emitida',
                    'person_id' => $people[0]->id,
                    'igreja_origem' => 'Igreja Presbiteriana em Campo Verde - MT',
                    'igreja_destino' => 'Primeira Igreja Presbiteriana de Cuiabá - MT',
                    'cidade_uf' => 'Cuiabá - MT',
                    'data_emissao' => Carbon::create(2026, 2, 10),
                    'data_validade' => Carbon::create(2026, 8, 10),
                    'observacoes' => 'Membro em plena comunhão, transferido por motivo de mudança profissional.',
                    'status' => 'Concluída',
                ],
                [
                    'institution_id' => $instId,
                    'numero_carta' => 'CT-015/2026',
                    'tipo' => 'Emitida',
                    'person_id' => $people[1]->id,
                    'igreja_origem' => 'Igreja Presbiteriana em Campo Verde - MT',
                    'igreja_destino' => 'Igreja Presbiteriana de Rondonópolis - MT',
                    'cidade_uf' => 'Rondonópolis - MT',
                    'data_emissao' => Carbon::create(2026, 3, 20),
                    'data_validade' => Carbon::create(2026, 9, 20),
                    'observacoes' => 'Carta expedida conforme resolução da Ata nº 104.',
                    'status' => 'Ativa',
                ],
                [
                    'institution_id' => $instId,
                    'numero_carta' => 'CT-008/2026',
                    'tipo' => 'Recebida',
                    'person_id' => $people[2]->id,
                    'igreja_origem' => 'Igreja Presbiteriana de Primavera do Leste - MT',
                    'igreja_destino' => 'Igreja Presbiteriana em Campo Verde - MT',
                    'cidade_uf' => 'Campo Verde - MT',
                    'data_emissao' => Carbon::create(2026, 1, 15),
                    'data_validade' => Carbon::create(2026, 7, 15),
                    'observacoes' => 'Recepção homologada pelo Conselho da Igreja.',
                    'status' => 'Concluída',
                ],
            ];

            foreach ($cartas as $cartaData) {
                CartaTransferencia::firstOrCreate(
                    ['institution_id' => $instId, 'numero_carta' => $cartaData['numero_carta']],
                    $cartaData
                );
            }
        }

        // 4. Sociedades Internas & Diretorias & Atividades
        $sociedadesConfig = [
            [
                'sigla' => 'SAF',
                'nome' => 'Sociedade Auxiliadora Feminina',
                'faixa_etaria' => 'Mulheres a partir de 25 anos',
                'lema' => 'Sejamos verdadeiras auxiliadoras, cooperando com alegria na obra do Senhor.',
                'diretoria' => [
                    ['cargo' => 'Presidente', 'offset' => 0],
                    ['cargo' => 'Vice-Presidente', 'offset' => 1],
                    ['cargo' => '1ª Secretária', 'offset' => 2],
                    ['cargo' => 'Tesoureira', 'offset' => 3],
                ],
                'atividades' => [
                    ['titulo' => 'Reunião Plenária e Oração', 'tipo' => 'Reunião', 'data' => Carbon::create(2026, 10, 15), 'local' => 'Salão Social', 'descricao' => 'Estudo da revista SAF em Marcha e momento de intercessão.'],
                    ['titulo' => 'Chá da Primavera e Visitação', 'tipo' => 'Comunhão', 'data' => Carbon::create(2026, 11, 8), 'local' => 'Espaço Gourmet', 'descricao' => 'Confraternização com convidadas e arrecadação de alimentos.'],
                ],
            ],
            [
                'sigla' => 'UPH',
                'nome' => 'União Presbiteriana de Homens',
                'faixa_etaria' => 'Homens a partir de 25 anos',
                'lema' => 'Confiança em Jesus, entusiasmo na ação e amor fraternal.',
                'diretoria' => [
                    ['cargo' => 'Presidente', 'offset' => 4],
                    ['cargo' => 'Vice-Presidente', 'offset' => 5],
                    ['cargo' => 'Secretário Executivo', 'offset' => 6],
                    ['cargo' => 'Tesoureiro', 'offset' => 7],
                ],
                'atividades' => [
                    ['titulo' => 'Café da Manhã com a Palavra', 'tipo' => 'Comunhão', 'data' => Carbon::create(2026, 10, 17), 'local' => 'Pátio da Igreja', 'descricao' => 'Devocional ministrada pelo pastor e testemunhos.'],
                    ['titulo' => 'Mutirão de Apoio Diaconal', 'tipo' => 'Serviço', 'data' => Carbon::create(2026, 10, 24), 'local' => 'Comunidade Local', 'descricao' => 'Auxílio a famílias em situação de vulnerabilidade.'],
                ],
            ],
            [
                'sigla' => 'UMP',
                'nome' => 'União de Mocidade Presbiteriana',
                'faixa_etaria' => 'Jovens de 18 a 35 anos',
                'lema' => 'Alegres na esperança, fortes na fé, dedicados no amor, unidos no trabalho.',
                'diretoria' => [
                    ['cargo' => 'Presidente', 'offset' => 8],
                    ['cargo' => 'Vice-Presidente', 'offset' => 9],
                    ['cargo' => '1º Secretário', 'offset' => 0],
                    ['cargo' => 'Tesoureiro', 'offset' => 1],
                ],
                'atividades' => [
                    ['titulo' => 'Culto Jovem "Enraizados"', 'tipo' => 'Culto', 'data' => Carbon::create(2026, 10, 18), 'local' => 'Templo Principal', 'descricao' => 'Louvor congregacional e pregação expositiva.'],
                    ['titulo' => 'Retiro de Carnaval / Acampamento', 'tipo' => 'Retiro', 'data' => Carbon::create(2027, 2, 6), 'local' => 'Chácara Moriá', 'descricao' => 'Estudos bíblicos intensivos, louvor e gincanas.'],
                ],
            ],
            [
                'sigla' => 'UPA',
                'nome' => 'União Presbiteriana de Adolescentes',
                'faixa_etaria' => 'Adolescentes de 12 a 17 anos',
                'lema' => 'Ao Mestre servindo com amor e honra.',
                'diretoria' => [
                    ['cargo' => 'Presidente', 'offset' => 2],
                    ['cargo' => 'Vice-Presidente', 'offset' => 3],
                    ['cargo' => 'Secretário(a)', 'offset' => 4],
                    ['cargo' => 'Tesoureiro(a)', 'offset' => 5],
                ],
                'atividades' => [
                    ['titulo' => 'Luau da UPA', 'tipo' => 'Comunhão', 'data' => Carbon::create(2026, 10, 31), 'local' => 'Área Externa', 'descricao' => 'Fogueira, violão e partilha de testemunhos escolares.'],
                ],
            ],
            [
                'sigla' => 'UCP',
                'nome' => 'União de Crianças Presbiterianas',
                'faixa_etaria' => 'Crianças até 11 anos',
                'lema' => 'Batalhando pela fé e crescendo na graça.',
                'diretoria' => [
                    ['cargo' => 'Conselheira / Orientadora', 'offset' => 6],
                    ['cargo' => 'Presidente Mirim', 'offset' => 7],
                    ['cargo' => 'Secretário(a) Mirim', 'offset' => 8],
                ],
                'atividades' => [
                    ['titulo' => 'Tarde Bíblica Infantil', 'tipo' => 'Ensino', 'data' => Carbon::create(2026, 10, 12), 'local' => 'Salas da EBD', 'descricao' => 'Teatro de fantoches da Reforma Protestante e lanche.'],
                ],
            ],
        ];

        foreach ($sociedadesConfig as $conf) {
            $soc = SociedadeInterna::firstOrCreate(
                ['institution_id' => $instId, 'sigla' => $conf['sigla']],
                [
                    'nome' => $conf['nome'],
                    'faixa_etaria' => $conf['faixa_etaria'],
                    'lema' => $conf['lema'],
                    'ano_exercicio' => 2026,
                ]
            );

            // Diretoria
            foreach ($conf['diretoria'] as $dir) {
                $targetPerson = $people[$dir['offset'] % $people->count()] ?? $people->first();
                SociedadeDiretoria::firstOrCreate(
                    [
                        'sociedade_id' => $soc->id,
                        'cargo' => $dir['cargo'],
                        'ano' => 2026,
                    ],
                    [
                        'person_id' => $targetPerson->id,
                    ]
                );
            }

            // Atividades
            foreach ($conf['atividades'] as $atv) {
                SociedadeAtividade::firstOrCreate(
                    [
                        'sociedade_id' => $soc->id,
                        'titulo' => $atv['titulo'],
                        'data' => $atv['data'],
                    ],
                    [
                        'tipo' => $atv['tipo'],
                        'local' => $atv['local'],
                        'descricao' => $atv['descricao'],
                    ]
                );
            }

            // Membros Iniciais (Sócios Efetivos da Diretoria e Pessoas Elegíveis)
            foreach ($conf['diretoria'] as $dir) {
                $targetPerson = $people[$dir['offset'] % $people->count()] ?? $people->first();
                SociedadeMembro::firstOrCreate(
                    [
                        'sociedade_id' => $soc->id,
                        'person_id' => $targetPerson->id,
                    ],
                    [
                        'tipo_socio' => 'efetivo',
                        'data_admissao' => '2026-01-10',
                        'status' => 'ativo',
                        'cargo_atual' => $dir['cargo'],
                        'observacoes' => 'Eleita(o) em Assembleia Geral Eletiva',
                    ]
                );
            }

            // Livro de Atas da Sociedade (Primeira Ata Formal do Ano)
            SociedadeAta::firstOrCreate(
                [
                    'sociedade_id' => $soc->id,
                    'numero_ata' => 'Ata nº 01/2026',
                ],
                [
                    'titulo' => "Reunião Plenária Ordinária de Abertura do Exercício ({$soc->sigla})",
                    'tipo_reuniao' => 'Plenária Ordinária',
                    'data_reuniao' => '2026-01-18',
                    'horario' => '19:30',
                    'local' => 'Salão Social da Igreja',
                    'pauta' => '1. Oração e meditação; 2. Apresentação da diretoria do ano; 3. Votação do plano anual de trabalho.',
                    'conteudo' => "Aos dezoito dias do mês de janeiro de dois mil e vinte e seis, às 19h30, reuniu-se ordinariamente a {$soc->nome} ({$soc->sigla}) em seu salão social. Aberta a sessão com hino e oração pela presidente, foram apresentados os oficiais eleitos para o ano de 2026. A plenária discutiu e aprovou por unanimidade o calendário de atividades e programações comunitárias. O tesoureiro apresentou o plano de despesas vinculado ao centro de custo e nada mais havendo a tratar, a reunião foi encerrada às 21h00 com oração de gratidão.",
                    'presentes_count' => 15,
                    'status' => 'Assinada',
                    'visto_conselho_data' => '2026-02-15',
                    'visto_conselho_relator' => 'Rev. Pastor Titular',
                ]
            );
        }

        // 5. Discipulado & Catecúmenos
        if ($people->count() >= 4) {
            $discipulados = [
                [
                    'institution_id' => $instId,
                    'person_id' => $people[0]->id,
                    'mentor_id' => $pastorId,
                    'fase' => 'Classe de Catecúmenos',
                    'data_inicio' => Carbon::create(2026, 8, 2),
                    'licoes_concluidas' => 7,
                    'total_licoes' => 10,
                    'observacoes' => 'Excelente assiduidade aos domingos. Estudando as doutrinas da Graça.',
                ],
                [
                    'institution_id' => $instId,
                    'person_id' => $people[1]->id,
                    'mentor_id' => $pastorId,
                    'fase' => 'Novo Convertido',
                    'data_inicio' => Carbon::create(2026, 9, 1),
                    'licoes_concluidas' => 3,
                    'total_licoes' => 10,
                    'observacoes' => 'Primeira experiência na fé cristã reformada. Mostra grande interesse pela Bíblia.',
                ],
                [
                    'institution_id' => $instId,
                    'person_id' => $people[2]->id,
                    'mentor_id' => $pastorId,
                    'fase' => 'Apto para Batismo/Profissão',
                    'data_inicio' => Carbon::create(2026, 6, 1),
                    'licoes_concluidas' => 10,
                    'total_licoes' => 10,
                    'data_conclusao' => Carbon::create(2026, 9, 28),
                    'observacoes' => 'Concluiu todo o currículo de catecúmenos. Pronto para exame perante o Conselho.',
                ],
                [
                    'institution_id' => $instId,
                    'person_id' => $people[3]->id,
                    'mentor_id' => $pastorId,
                    'fase' => 'Concluído',
                    'data_inicio' => Carbon::create(2026, 2, 1),
                    'licoes_concluidas' => 10,
                    'total_licoes' => 10,
                    'data_conclusao' => Carbon::create(2026, 5, 20),
                    'observacoes' => 'Profissão de Fé e Batismo realizados com bênção para a comunidade.',
                ],
            ];

            foreach ($discipulados as $discData) {
                DiscipuladoCatecumeno::firstOrCreate(
                    [
                        'institution_id' => $instId,
                        'person_id' => $discData['person_id'],
                    ],
                    $discData
                );
            }
        }

        // 6. Biblioteca & Livros
        $livros = [
            [
                'institution_id' => $instId,
                'titulo' => 'As Institutas da Religião Cristã (Edição Clássica)',
                'autor' => 'João Calvino',
                'categoria' => 'Teologia Sistemática',
                'editora' => 'Cultura Cristã',
                'ano' => 2006,
                'isbn' => '978-85-7622-098-7',
                'quantidade_total' => 3,
                'quantidade_disponivel' => 2,
                'localizacao' => 'Estante A1 - Obras Clássicas',
            ],
            [
                'institution_id' => $instId,
                'titulo' => 'Teologia Sistemática',
                'autor' => 'Louis Berkhof',
                'categoria' => 'Teologia Sistemática',
                'editora' => 'LPC',
                'ano' => 2012,
                'isbn' => '978-85-7622-290-5',
                'quantidade_total' => 2,
                'quantidade_disponivel' => 1,
                'localizacao' => 'Estante A2',
            ],
            [
                'institution_id' => $instId,
                'titulo' => 'Santidade: Sem a Qual Ninguém Verá o Senhor',
                'autor' => 'J. C. Ryle',
                'categoria' => 'Vida Cristã',
                'editora' => 'Fiel',
                'ano' => 2017,
                'isbn' => '978-85-8132-387-9',
                'quantidade_total' => 4,
                'quantidade_disponivel' => 4,
                'localizacao' => 'Estante B1',
            ],
            [
                'institution_id' => $instId,
                'titulo' => 'O Deus que Intervém',
                'autor' => 'Francis Schaeffer',
                'categoria' => 'Apologética',
                'editora' => 'Cultura Cristã',
                'ano' => 2003,
                'isbn' => '978-85-7622-023-9',
                'quantidade_total' => 2,
                'quantidade_disponivel' => 2,
                'localizacao' => 'Estante B2',
            ],
            [
                'institution_id' => $instId,
                'titulo' => 'O Conhecimento de Deus',
                'autor' => 'J. I. Packer',
                'categoria' => 'Teologia Prática',
                'editora' => 'Mundo Cristão',
                'ano' => 2014,
                'isbn' => '978-85-7325-982-1',
                'quantidade_total' => 3,
                'quantidade_disponivel' => 2,
                'localizacao' => 'Estante B3',
            ],
            [
                'institution_id' => $instId,
                'titulo' => 'Comentário Bíblico aos Romanos',
                'autor' => 'João Calvino',
                'categoria' => 'Comentários Bíblicos',
                'editora' => 'Paracletos',
                'ano' => 1997,
                'isbn' => '978-85-8742-105-0',
                'quantidade_total' => 2,
                'quantidade_disponivel' => 2,
                'localizacao' => 'Estante C1',
            ],
            [
                'institution_id' => $instId,
                'titulo' => 'A Cruz de Cristo',
                'autor' => 'John Stott',
                'categoria' => 'Doutrina Bíblica',
                'editora' => 'Vida Nova',
                'ano' => 2011,
                'isbn' => '978-85-2750-387-7',
                'quantidade_total' => 3,
                'quantidade_disponivel' => 3,
                'localizacao' => 'Estante C2',
            ],
            [
                'institution_id' => $instId,
                'titulo' => 'O Peregrino',
                'autor' => 'John Bunyan',
                'categoria' => 'Literatura Cristã',
                'editora' => 'Mundo Cristão',
                'ano' => 2018,
                'isbn' => '978-85-4330-312-3',
                'quantidade_total' => 5,
                'quantidade_disponivel' => 5,
                'localizacao' => 'Estante D1',
            ],
            [
                'institution_id' => $instId,
                'titulo' => 'O Conselheiro Capaz (Manual de Aconselhamento)',
                'autor' => 'Jay E. Adams',
                'categoria' => 'Aconselhamento Pastoral',
                'editora' => 'Fiel',
                'ano' => 2016,
                'isbn' => '978-85-9914-532-6',
                'quantidade_total' => 2,
                'quantidade_disponivel' => 2,
                'localizacao' => 'Estante D2',
            ],
            [
                'institution_id' => $instId,
                'titulo' => 'A Família da Aliança',
                'autor' => 'Gerard Van Groningen',
                'categoria' => 'Família & Aliança',
                'editora' => 'Cultura Cristã',
                'ano' => 2008,
                'isbn' => '978-85-7622-234-9',
                'quantidade_total' => 2,
                'quantidade_disponivel' => 2,
                'localizacao' => 'Estante D3',
            ],
        ];

        $savedLivros = [];
        foreach ($livros as $livroData) {
            $savedLivros[] = BibliotecaLivro::firstOrCreate(
                ['institution_id' => $instId, 'titulo' => $livroData['titulo']],
                $livroData
            );
        }

        // 7. Empréstimos Ativos
        if (count($savedLivros) >= 2 && $people->count() >= 2) {
            BibliotecaEmprestimo::firstOrCreate(
                [
                    'livro_id' => $savedLivros[0]->id,
                    'person_id' => $people[0]->id,
                    'status' => 'Emprestado',
                ],
                [
                    'data_emprestimo' => Carbon::create(2026, 9, 25),
                    'data_prevista_devolucao' => Carbon::create(2026, 10, 15),
                    'observacoes' => 'Empréstimo concedido para preparação de aula de EBD.',
                ]
            );

            BibliotecaEmprestimo::firstOrCreate(
                [
                    'livro_id' => $savedLivros[1]->id,
                    'person_id' => $people[1]->id,
                    'status' => 'Emprestado',
                ],
                [
                    'data_emprestimo' => Carbon::create(2026, 9, 28),
                    'data_prevista_devolucao' => Carbon::create(2026, 10, 18),
                    'observacoes' => 'Membro em discipulado e leitura dirigida.',
                ]
            );
        }
    }
}
