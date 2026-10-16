<?php

namespace Database\Seeders;

use App\Models\Institution;
use App\Models\Person;
use App\Models\SociedadeAta;
use App\Models\SociedadeAtividade;
use App\Models\SociedadeDiretoria;
use App\Models\SociedadeInterna;
use App\Models\SociedadeMembro;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SociedadesInternasDistribuicaoSeeder extends Seeder
{
    public function run(): void
    {
        $instId = 5; // Igreja Presbiteriana de Campo Verde

        echo ">>> Iniciando configuração das Sociedades Internas para Inst: {$instId}..." . PHP_EOL;

        // 1. Definição Oficial das 6 Sociedades Internas da IPB
        $sociedadesConfig = [
            'SAF' => [
                'sigla' => 'SAF',
                'nome' => 'Sociedade Auxiliadora Feminina',
                'faixa_etaria' => 'Mulheres a partir de 18 anos',
                'lema' => 'Sejamos verdadeiras auxiliadoras, cooperando com alegria na obra do Senhor.',
                'diretoria' => [
                    ['cargo' => 'Presidente', 'person_id' => 53], // Patrícia Oliveira Santos
                    ['cargo' => 'Vice-Presidente', 'person_id' => 55], // Fernanda Alves Costa
                    ['cargo' => '1ª Secretária', 'person_id' => 59], // Renata Ferreira Dias
                    ['cargo' => '2ª Secretária', 'person_id' => 67], // Mariana Castro Silveira
                    ['cargo' => 'Tesoureira', 'person_id' => 71], // Camila Siqueira Paiva
                ],
                'atividades' => [
                    ['titulo' => 'Reunião Plenária e Estudo de "SAF em Marcha"', 'tipo' => 'Reunião', 'data' => '2026-10-15', 'horario' => '19:30', 'local' => 'Salão Social', 'descricao' => 'Estudo bíblico, oração pelas missionárias e planejamento do Chá da Primavera.'],
                    ['titulo' => 'Chá da Primavera e Visitação aos Enfermos', 'tipo' => 'Comunhão', 'data' => '2026-11-07', 'horario' => '16:00', 'local' => 'Espaço Gourmet', 'descricao' => 'Tarde de louvor, confraternização e entrega de cestas de amor.'],
                    ['titulo' => 'Bazar Missionário Beneficente', 'tipo' => 'Serviço', 'data' => '2026-11-28', 'horario' => '09:00', 'local' => 'Pátio da Igreja', 'descricao' => 'Arrecadação de fundos para as missões transculturais da IPB.'],
                ],
                'ata' => [
                    'numero_ata' => 'Ata nº 01/2026',
                    'titulo' => 'Assembleia Geral Eletiva e Posse da Diretoria para o Exercício 2026',
                    'tipo_reuniao' => 'Assembleia Geral Eletiva',
                    'data_reuniao' => '2026-01-10',
                    'horario' => '19:30',
                    'local' => 'Salão Social',
                    'presidente_id' => 53,
                    'secretario_id' => 59,
                    'pauta' => '1. Eleição e posse da Diretoria para o ano de 2026; 2. Aprovação do plano de trabalho e oração.',
                    'conteudo' => 'Às dezenove horas e trinta minutos do dia dez de janeiro de dois mil e vinte e seis, reuniu-se a Sociedade Auxiliadora Feminina (SAF) em Assembleia Geral Eletiva, sob a presidência da irmã Patrícia Oliveira Santos. A reunião iniciou-se com o cântico oficial da SAF e oração conduzida pela irmã Fernanda Alves Costa. Prosseguindo, procedeu-se à eleição da Diretoria para o exercício de 2026, tendo sido eleitas por aclamação as seguintes irmãs: Presidente: Patrícia Oliveira Santos; Vice-Presidente: Fernanda Alves Costa; 1ª Secretária: Renata Ferreira Dias; 2ª Secretária: Mariana Castro Silveira; Tesoureira: Camila Siqueira Paiva.',
                    'presentes_count' => 11,
                    'status' => 'Aprovada',
                    'visto_conselho_data' => '2026-01-18',
                    'visto_conselho_relator' => 'Presb. Marcos Vinícius Toledo',
                ],
            ],
            'UPH' => [
                'sigla' => 'UPH',
                'nome' => 'União Presbiteriana de Homens',
                'faixa_etaria' => 'Homens a partir de 18 anos',
                'lema' => 'Confiança em Jesus, entusiasmo na ação e amor fraternal.',
                'diretoria' => [
                    ['cargo' => 'Presidente', 'person_id' => 63], // Presb. Marcos Vinícius Toledo
                    ['cargo' => 'Vice-Presidente', 'person_id' => 54], // Carlos Eduardo Lima
                    ['cargo' => 'Secretário Executivo', 'person_id' => 56], // Ricardo Gomes Pereira
                    ['cargo' => 'Tesoureiro', 'person_id' => 58], // André Luiz Souza
                    ['cargo' => 'Secretário de Evangelização', 'person_id' => 64], // Presb. Roberto Alencar Fontes
                ],
                'atividades' => [
                    ['titulo' => 'Café com a Palavra e Oração dos Homens', 'tipo' => 'Comunhão', 'data' => '2026-10-17', 'horario' => '07:30', 'local' => 'Pátio da Igreja', 'descricao' => 'Devocional bíblica, testemunhos e momentos de intercessão pelos lares e pela liderança.'],
                    ['titulo' => 'Mutirão de Apoio Diaconal e Manutenção', 'tipo' => 'Serviço', 'data' => '2026-10-24', 'horario' => '08:00', 'local' => 'Comunidade / Templo', 'descricao' => 'Apoio em reparos prediais para viúvas e famílias carentes da comunidade.'],
                    ['titulo' => 'Noite de Comunhão e Churrasco dos Sócios', 'tipo' => 'Comunhão', 'data' => '2026-11-21', 'horario' => '19:00', 'local' => 'Chácara Moriá', 'descricao' => 'Confraternização dos homens com palavra desafiadora sobre liderança bíblica no lar.'],
                ],
                'ata' => [
                    'numero_ata' => 'Ata nº 01/2026',
                    'titulo' => 'Plenária de Posse da Diretoria e Calendário Operacional',
                    'tipo_reuniao' => 'Plenária Ordinária',
                    'data_reuniao' => '2026-01-17',
                    'horario' => '08:00',
                    'local' => 'Gabinete Pastoral',
                    'presidente_id' => 63,
                    'secretario_id' => 56,
                    'pauta' => '1. Instalação da Diretoria para o ano de 2026; 2. Definição do calendário do Café dos Homens e projetos de ação social.',
                    'conteudo' => 'Aos dezessete dias do mês de janeiro de dois mil e vinte e seis, realizou-se a sessão solene de abertura da União Presbiteriana de Homens (UPH). O Presb. Marcos Vinícius Toledo procedeu à leitura do texto de Josué 24:15. Foram empossados os oficiais eleitos para a liderança dos homens presbiterianos.',
                    'presentes_count' => 14,
                    'status' => 'Aprovada',
                    'visto_conselho_data' => '2026-01-18',
                    'visto_conselho_relator' => 'Rev. Carlos Eduardo Silveira',
                ],
            ],
            'UMP' => [
                'sigla' => 'UMP',
                'nome' => 'União de Mocidade Presbiteriana',
                'faixa_etaria' => 'Jovens de 18 a 35 anos',
                'lema' => 'Alegres na esperança, fortes na fé, dedicados no amor, unidos no trabalho.',
                'diretoria' => [
                    ['cargo' => 'Presidente', 'person_id' => 68], // Lucas Gabriel Rocha
                    ['cargo' => 'Vice-Presidente', 'person_id' => 76], // Renata Vasconcelos Lima
                    ['cargo' => '1ª Secretária', 'person_id' => 72], // Daniela Martins Prado
                    ['cargo' => 'Tesoureira', 'person_id' => 69], // Beatriz Helena Guimarães
                    ['cargo' => 'Conselheiro', 'person_id' => 1], // Douglas Zioto
                ],
                'atividades' => [
                    ['titulo' => 'Culto Jovem "Inconformados"', 'tipo' => 'Culto', 'data' => '2026-10-18', 'horario' => '19:30', 'local' => 'Templo Principal', 'descricao' => 'Louvor congregacional jovem, momento de comunhão e pregação em Romanos 12.'],
                    ['titulo' => 'Vigília Jovem e Busca Espiritual', 'tipo' => 'Oração', 'data' => '2026-11-14', 'horario' => '22:00', 'local' => 'Sala da Mocidade', 'descricao' => 'Oração pelas universidades, vocação missionária e avivamento da igreja.'],
                    ['titulo' => 'Retiro de Carnaval / Acampamento Moriá', 'tipo' => 'Retiro', 'data' => '2027-02-06', 'horario' => '18:00', 'local' => 'Chácara Moriá', 'descricao' => 'Quatro dias de imersão bíblica, comunhão santa e evangelismo.'],
                ],
                'ata' => [
                    'numero_ata' => 'Ata nº 01/2026',
                    'titulo' => 'Reunião de Diretoria e Planejamento Anual da UMP',
                    'tipo_reuniao' => 'Reunião de Diretoria',
                    'data_reuniao' => '2026-01-11',
                    'horario' => '17:00',
                    'local' => 'Sala da UMP',
                    'presidente_id' => 68,
                    'secretario_id' => 72,
                    'pauta' => '1. Eleição interna dos departamentos; 2. Definição do lema jovem para 2026; 3. Organização do Culto Jovem mensal.',
                    'conteudo' => 'Reunida a diretoria da UMP, o presidente Lucas Gabriel Rocha agradeceu a presença de todos e orou pedindo discernimento divino. Definiu-se que a UMP atuará fortemente no acolhimento de novos jovens da EBD.',
                    'presentes_count' => 6,
                    'status' => 'Aprovada',
                    'visto_conselho_data' => '2026-01-18',
                    'visto_conselho_relator' => 'Presb. Marcos Vinícius Toledo',
                ],
            ],
            'UPA' => [
                'sigla' => 'UPA',
                'nome' => 'União Presbiteriana de Adolescentes',
                'faixa_etaria' => 'Adolescentes de 12 a 17 anos',
                'lema' => 'Ao Mestre servindo com amor e honra.',
                'diretoria' => [
                    ['cargo' => 'Presidente', 'person_id' => 45], // Bruno Tavares
                    ['cargo' => 'Vice-Presidente', 'person_id' => 42], // Amanda Rezende
                    ['cargo' => '1ª Secretária', 'person_id' => 44], // Letícia Cavalcante
                    ['cargo' => 'Tesoureiro', 'person_id' => 49], // Thiago Coelho
                    ['cargo' => 'Conselheiro da UPH', 'person_id' => 54], // Carlos Eduardo Lima
                ],
                'atividades' => [
                    ['titulo' => 'Luau dos Adolescentes', 'tipo' => 'Comunhão', 'data' => '2026-10-31', 'horario' => '18:30', 'local' => 'Área Externa / Quadra', 'descricao' => 'Música, violão, dinâmica de integração e mensagem de santidade para a juventude.'],
                    ['titulo' => 'Gincana Bíblica da Reforma Protestante', 'tipo' => 'Ensino', 'data' => '2026-11-01', 'horario' => '16:00', 'local' => 'Salão Social', 'descricao' => 'Competição de perguntas sobre a história da IPB e os 5 Solas da Reforma.'],
                ],
                'ata' => [
                    'numero_ata' => 'Ata nº 01/2026',
                    'titulo' => 'Plenária de Abertura do Exercício e Recepção de Novos Sócios',
                    'tipo_reuniao' => 'Plenária Ordinária',
                    'data_reuniao' => '2026-01-25',
                    'horario' => '16:00',
                    'local' => 'Salão dos Adolescentes',
                    'presidente_id' => 45,
                    'secretario_id' => 44,
                    'pauta' => '1. Acolhida dos adolescentes vindos da UCP; 2. Calendário de reuniões semanais da UPA.',
                    'conteudo' => 'Sob a presidência do jovem Bruno Tavares e com a presença do conselheiro irmão Carlos Eduardo Lima, os adolescentes reuniram-se alegremente para louvar a Deus. Foram apresentados os 20 membros ativos da UPA.',
                    'presentes_count' => 20,
                    'status' => 'Aprovada',
                    'visto_conselho_data' => '2026-02-22',
                    'visto_conselho_relator' => 'Presb. Roberto Alencar Fontes',
                ],
            ],
            'UCP' => [
                'sigla' => 'UCP',
                'nome' => 'União de Crianças Presbiterianas',
                'faixa_etaria' => 'Crianças de 0 a 11 anos',
                'lema' => 'Batalhando pela fé e crescendo na graça.',
                'diretoria' => [
                    ['cargo' => 'Conselheira Orientadora', 'person_id' => 55], // Fernanda Alves Costa (SAF)
                    ['cargo' => 'Presidente Mirim', 'person_id' => 22], // Isabela Nunes
                    ['cargo' => 'Vice-Presidente Mirim', 'person_id' => 29], // Enzo Freitas
                    ['cargo' => 'Secretária Mirim', 'person_id' => 28], // Lívia Castro
                    ['cargo' => 'Tesoureiro Mirim', 'person_id' => 31], // Daniel Vieira
                ],
                'atividades' => [
                    ['titulo' => 'Festa da Primavera com Jesus', 'tipo' => 'Comunhão', 'data' => '2026-10-12', 'horario' => '14:00', 'local' => 'Salas da EBD', 'descricao' => 'Contação de histórias bíblicas com fantoches, brincadeiras e lanche festivo.'],
                    ['titulo' => 'Culto Infantil e Coralzinho da UCP', 'tipo' => 'Culto', 'data' => '2026-10-25', 'horario' => '19:00', 'local' => 'Templo Principal', 'descricao' => 'Apresentação musical das crianças para toda a igreja.'],
                ],
                'ata' => [
                    'numero_ata' => 'Ata nº 01/2026',
                    'titulo' => 'Reunião Inaugural da Turma Mirim da UCP',
                    'tipo_reuniao' => 'Plenária Ordinária',
                    'data_reuniao' => '2026-01-18',
                    'horario' => '15:00',
                    'local' => 'Salas Infantis',
                    'presidente_id' => 22,
                    'secretario_id' => 28,
                    'pauta' => '1. Posse da Diretoria Mirim; 2. Ensaio do Hino Oficial da UCP.',
                    'conteudo' => 'Com a supervisão afetuosa da conselheira Fernanda Alves Costa, as crianças reuniram-se com entusiasmo cantando o hino da UCP. As 30 crianças inscritas foram consagradas ao Senhor.',
                    'presentes_count' => 30,
                    'status' => 'Aprovada',
                    'visto_conselho_data' => '2026-01-18',
                    'visto_conselho_relator' => 'Rev. Carlos Eduardo Silveira',
                ],
            ],
            'UPI' => [
                'sigla' => 'UPI',
                'nome' => 'União Presbiteriana de Idosos',
                'faixa_etaria' => 'Membros da melhor idade (60 anos ou mais)',
                'lema' => 'Mesmo na velhice darão frutos; serão cheios de seiva e verdejantes (Salmo 92:14).',
                'diretoria' => [
                    ['cargo' => 'Coordenador Geral', 'person_id' => 73], // José Fernando Peixoto
                    ['cargo' => 'Vice-Coordenador', 'person_id' => 70], // Paulo Henrique Antunes
                    ['cargo' => 'Secretária', 'person_id' => 53], // Patrícia Oliveira Santos
                    ['cargo' => 'Tesoureiro', 'person_id' => 52], // Marcos Antônio Silva
                    ['cargo' => 'Conselheiro Pastoral', 'person_id' => 62], // Rev. Carlos Eduardo Silveira
                ],
                'atividades' => [
                    ['titulo' => 'Tarde de Oração e Cânticos Antigos', 'tipo' => 'Espiritual', 'data' => '2026-10-20', 'horario' => '15:00', 'local' => 'Templo Principal', 'descricao' => 'Cânticos do hinário Novo Cântico, testemunhos de fé e oração pela igreja.'],
                    ['titulo' => 'Passeio e Piquenique no Parque da Cidade', 'tipo' => 'Confraternização', 'data' => '2026-11-10', 'horario' => '09:00', 'local' => 'Parque da Cidade', 'descricao' => 'Caminhada leve, confraternização e lanche comunitário da melhor idade.'],
                ],
                'ata' => [
                    'numero_ata' => 'Ata nº 01/2026',
                    'titulo' => 'Instalação Oficial da União Presbiteriana de Idosos (UPI)',
                    'tipo_reuniao' => 'Assembleia de Fundação e Posse',
                    'data_reuniao' => '2026-01-24',
                    'horario' => '15:00',
                    'local' => 'Templo Principal',
                    'presidente_id' => 73,
                    'secretario_id' => 53,
                    'pauta' => '1. Instalação formal da UPI na Igreja Presbiteriana de Campo Verde; 2. Definição da coordenação.',
                    'conteudo' => 'Com aprovação do Conselho da Igreja, instalou-se festivamente a União Presbiteriana de Idosos (UPI). Foram aclamados como coordenadores os irmãos José Fernando Peixoto e Paulo Henrique Antunes.',
                    'presentes_count' => 12,
                    'status' => 'Aprovada',
                    'visto_conselho_data' => '2026-02-22',
                    'visto_conselho_relator' => 'Presb. Marcos Vinícius Toledo',
                ],
            ],
        ];

        // 2. Mapeamento Canônico dos 76 Membros da Congregação
        // UCP (0 a 11 anos): 30 crianças (IDs 2 a 31)
        $ucpPersonIds = range(2, 31);

        // UPA (12 a 17 anos): 20 adolescentes (IDs 32 a 51)
        $upaPersonIds = range(32, 51);

        // UMP (18 a 35 anos): 6 jovens (IDs 1, 68, 69, 72, 76, 66)
        $umpPersonIds = [1, 68, 69, 72, 76, 66];

        // SAF (Mulheres a partir de 18 anos): 11 irmãs (IDs 53, 55, 57, 59, 61, 67, 69, 71, 72, 74, 76)
        $safPersonIds = [53, 55, 57, 59, 61, 67, 69, 71, 72, 74, 76];

        // UPH (Homens a partir de 18 anos): 14 irmãos (IDs 1, 52, 54, 56, 58, 60, 62, 63, 64, 65, 68, 70, 73, 75)
        $uphPersonIds = [1, 52, 54, 56, 58, 60, 62, 63, 64, 65, 68, 70, 73, 75];

        // UPI (Terceira Idade / Veteranos): 6 veteranos (IDs 52, 53, 54, 63, 70, 73)
        $upiPersonIds = [52, 53, 54, 63, 70, 73];

        $membershipMap = [
            'UCP' => $ucpPersonIds,
            'UPA' => $upaPersonIds,
            'UMP' => $umpPersonIds,
            'SAF' => $safPersonIds,
            'UPH' => $uphPersonIds,
            'UPI' => $upiPersonIds,
        ];

        // Cache das pessoas para evitar N queries repetidas
        $allPeople = Person::where('institution_id', $instId)->get()->keyBy('id');

        foreach ($sociedadesConfig as $sigla => $config) {
            echo "-> Processando Sociedade: {$sigla} ({$config['nome']})..." . PHP_EOL;

            // 1. Cadastrar ou Atualizar a Sociedade
            $soc = SociedadeInterna::where('institution_id', $instId)->where('sigla', $sigla)->first();
            if (!$soc) {
                $soc = SociedadeInterna::create([
                    'institution_id' => $instId,
                    'sigla' => $sigla,
                    'nome' => $config['nome'],
                    'faixa_etaria' => $config['faixa_etaria'],
                    'lema' => $config['lema'],
                    'ano_exercicio' => 2026,
                ]);
            } else {
                $soc->update([
                    'nome' => $config['nome'],
                    'faixa_etaria' => $config['faixa_etaria'],
                    'lema' => $config['lema'],
                    'ano_exercicio' => 2026,
                ]);
            }

            // 2. Diretoria
            SociedadeDiretoria::where('sociedade_id', $soc->id)->delete();
            $cargosDiretoria = [];
            foreach ($config['diretoria'] as $dir) {
                SociedadeDiretoria::create([
                    'sociedade_id' => $soc->id,
                    'cargo' => $dir['cargo'],
                    'person_id' => $dir['person_id'],
                    'ano' => 2026,
                ]);
                $cargosDiretoria[$dir['person_id']] = $dir['cargo'];
            }

            // 3. Atividades
            foreach ($config['atividades'] as $atv) {
                $existeAtv = SociedadeAtividade::where('sociedade_id', $soc->id)->where('titulo', $atv['titulo'])->first();
                if (!$existeAtv) {
                    SociedadeAtividade::create([
                        'sociedade_id' => $soc->id,
                        'titulo' => $atv['titulo'],
                        'tipo' => $atv['tipo'],
                        'data' => $atv['data'],
                        'horario' => $atv['horario'] ?? '19:30',
                        'local' => $atv['local'],
                        'descricao' => $atv['descricao'],
                    ]);
                }
            }

            // 4. Ata Digital
            if (isset($config['ata'])) {
                $ata = $config['ata'];
                $existeAta = SociedadeAta::where('sociedade_id', $soc->id)->where('numero_ata', $ata['numero_ata'])->first();
                if (!$existeAta) {
                    SociedadeAta::create([
                        'sociedade_id' => $soc->id,
                        'numero_ata' => $ata['numero_ata'],
                        'titulo' => $ata['titulo'],
                        'tipo_reuniao' => $ata['tipo_reuniao'],
                        'data_reuniao' => $ata['data_reuniao'],
                        'horario' => $ata['horario'],
                        'local' => $ata['local'],
                        'presidente_id' => $ata['presidente_id'],
                        'secretario_id' => $ata['secretario_id'],
                        'pauta' => $ata['pauta'],
                        'conteudo' => $ata['conteudo'],
                        'presentes_count' => $ata['presentes_count'],
                        'status' => $ata['status'],
                        'visto_conselho_data' => $ata['visto_conselho_data'],
                        'visto_conselho_relator' => $ata['visto_conselho_relator'],
                    ]);
                }
            }

            // 5. Vincular Membros (Upsert em lote de alta performance)
            $membrosParaInserir = [];
            $personIds = $membershipMap[$sigla] ?? [];

            foreach ($personIds as $personId) {
                $person = $allPeople->get($personId);
                if (!$person) {
                    continue;
                }

                $cargo = $cargosDiretoria[$personId] ?? null;
                $tipo = ($person->canonical_status === 'comungante' || in_array($sigla, ['UCP', 'UPA'])) ? 'efetivo' : 'cooperador';
                $status = ($person->canonical_status === 'falecido') ? 'inativo' : ($person->is_active ? 'ativo' : 'inativo');

                $membrosParaInserir[] = [
                    'sociedade_id' => $soc->id,
                    'person_id' => $personId,
                    'tipo_socio' => $tipo,
                    'data_admissao' => $person->reception_date ? $person->reception_date->format('Y-m-d') : '2026-01-10',
                    'status' => $status,
                    'cargo_atual' => $cargo,
                    'observacoes' => $cargo ? "Membro da Diretoria ({$cargo})" : 'Sócio ativo e participante das programações regulares',
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            if (!empty($membrosParaInserir)) {
                // Upsert em lote: uma única consulta SQL rápida e atômica!
                DB::table('sociedade_membros')->upsert(
                    $membrosParaInserir,
                    ['sociedade_id', 'person_id'],
                    ['tipo_socio', 'data_admissao', 'status', 'cargo_atual', 'observacoes', 'updated_at']
                );
            }

            $totalSoc = DB::table('sociedade_membros')->where('sociedade_id', $soc->id)->count();
            echo "   [OK] {$sigla}: {$totalSoc} membros vinculados com sucesso!" . PHP_EOL;
        }

        echo ">>> Distribuição de Membros finalizada com 100% de sucesso!" . PHP_EOL;
    }
}
