<?php

namespace Database\Seeders;

use App\Models\Family;
use App\Models\Person;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class NucleosFamiliaresSeeder extends Seeder
{
    public function run(): void
    {
        $institutionId = 5;

        // Limpa vínculos anteriores da instituição 5 para reconstruir de forma limpa e harmônica
        $familyIds = Family::where('institution_id', $institutionId)->pluck('id');
        DB::table('family_members')->whereIn('family_id', $familyIds)->delete();
        Family::where('institution_id', $institutionId)->forceDelete();

        $familias = [
            [
                'name' => 'Família Silveira (Pastoral)',
                'phone' => '(27) 3386-1652',
                'whatsapp' => '(27) 99812-4001',
                'email' => 'carlos.silveira@ipb.org.br',
                'zipcode' => '29155-845',
                'street' => 'Av. Obede Emerick',
                'number' => '120',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família pastoral titular da IP Campo Verde.',
                'members' => [
                    ['person_id' => 62, 'relationship' => 'responsavel', 'is_head' => true],  // Rev. Carlos Eduardo Silveira
                    ['person_id' => 67, 'relationship' => 'conjuge', 'is_head' => false],     // Mariana Castro Silveira
                ],
            ],
            [
                'name' => 'Família Toledo',
                'phone' => '(27) 3386-2100',
                'whatsapp' => '(27) 99744-8822',
                'email' => 'marcos.toledo@ipb.org.br',
                'zipcode' => '29155-820',
                'street' => 'Rua José Himério Silva',
                'number' => '45',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família do Presb. Marcos Vinícius Toledo.',
                'members' => [
                    ['person_id' => 63, 'relationship' => 'responsavel', 'is_head' => true],  // Presb. Marcos Vinícius Toledo
                    ['person_id' => 71, 'relationship' => 'conjuge', 'is_head' => false],     // Camila Siqueira Paiva
                    ['person_id' => 35, 'relationship' => 'filho', 'is_head' => false],       // Benício Moraes
                    ['person_id' => 18, 'relationship' => 'filha', 'is_head' => false],       // Júlia Fernandes
                ],
            ],
            [
                'name' => 'Família Fontes',
                'phone' => '(27) 3386-3344',
                'whatsapp' => '(27) 99611-3030',
                'email' => 'roberto.fontes@ipb.org.br',
                'zipcode' => '29155-810',
                'street' => 'Rua São Sebastião',
                'number' => '88',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família do Presb. Roberto Alencar Fontes.',
                'members' => [
                    ['person_id' => 64, 'relationship' => 'responsavel', 'is_head' => true],  // Presb. Roberto Alencar Fontes
                    ['person_id' => 75, 'relationship' => 'outro', 'is_head' => false],       // Ricardo Morais Fontes
                    ['person_id' => 40, 'relationship' => 'filha', 'is_head' => false],       // Esther Azevedo
                ],
            ],
            [
                'name' => 'Família Ramos',
                'phone' => '(27) 3386-4555',
                'whatsapp' => '(27) 99882-1144',
                'email' => 'andre.ramos@ipb.org.br',
                'zipcode' => '29155-830',
                'street' => 'Rua Projetada B',
                'number' => '112',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família do Diác. André Luiz Ramos.',
                'members' => [
                    ['person_id' => 65, 'relationship' => 'responsavel', 'is_head' => true],  // Diác. André Luiz Ramos
                    ['person_id' => 72, 'relationship' => 'conjuge', 'is_head' => false],     // Daniela Martins Prado
                    ['person_id' => 39, 'relationship' => 'filho', 'is_head' => false],       // Vitor Hugo Ramos
                ],
            ],
            [
                'name' => 'Família Mendes Bastos',
                'phone' => '(27) 3386-5666',
                'whatsapp' => '(27) 99933-7711',
                'email' => 'felipe.bastos@ipb.org.br',
                'zipcode' => '29155-800',
                'street' => 'Av. Campo Verde',
                'number' => '305',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família do Diác. Felipe Mendes Bastos.',
                'members' => [
                    ['person_id' => 66, 'relationship' => 'responsavel', 'is_head' => true],  // Diác. Felipe Mendes Bastos
                    ['person_id' => 44, 'relationship' => 'conjuge', 'is_head' => false],     // Letícia Cavalcante
                ],
            ],
            [
                'name' => 'Família Peixoto',
                'phone' => '(27) 3226-7890',
                'whatsapp' => '(27) 99901-2345',
                'email' => 'jose.peixoto@ipb.org.br',
                'zipcode' => '29140-150',
                'street' => 'Rua das Palmeiras',
                'number' => '220',
                'district' => 'Jardim América',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de José Fernando Peixoto.',
                'members' => [
                    ['person_id' => 73, 'relationship' => 'responsavel', 'is_head' => true],  // José Fernando Peixoto
                    ['person_id' => 47, 'relationship' => 'filho', 'is_head' => false],       // Eduardo Peixoto
                ],
            ],
            [
                'name' => 'Família Silva',
                'phone' => '(27) 3386-9012',
                'whatsapp' => '(27) 99876-5432',
                'email' => 'marcos.silva@ipb.org.br',
                'zipcode' => '29155-815',
                'street' => 'Rua Getúlio Vargas',
                'number' => '140',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Marcos Antônio Silva.',
                'members' => [
                    ['person_id' => 52, 'relationship' => 'responsavel', 'is_head' => true],  // Marcos Antônio Silva
                    ['person_id' => 15, 'relationship' => 'filho', 'is_head' => false],       // Pedro Henrique Silva
                    ['person_id' => 10, 'relationship' => 'filha', 'is_head' => false],       // Alice Costa
                ],
            ],
            [
                'name' => 'Família Lima & Vasconcelos',
                'phone' => '(27) 3386-3456',
                'whatsapp' => '(27) 99765-4321',
                'email' => 'carlos.lima@ipb.org.br',
                'zipcode' => '29155-825',
                'street' => 'Rua da Glória',
                'number' => '54',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Carlos Eduardo Lima.',
                'members' => [
                    ['person_id' => 54, 'relationship' => 'responsavel', 'is_head' => true],  // Carlos Eduardo Lima
                    ['person_id' => 76, 'relationship' => 'conjuge', 'is_head' => false],     // Renata Vasconcelos Lima
                    ['person_id' => 4, 'relationship' => 'filha', 'is_head' => false],        // Maria Eduarda Lima
                ],
            ],
            [
                'name' => 'Família Rocha',
                'phone' => '(27) 3386-7891',
                'whatsapp' => '(27) 99654-3210',
                'email' => 'lucas.rocha@ipb.org.br',
                'zipcode' => '29155-835',
                'street' => 'Rua Bela Vista',
                'number' => '77',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família do Lucas Gabriel Rocha (UMP).',
                'members' => [
                    ['person_id' => 68, 'relationship' => 'responsavel', 'is_head' => true],  // Lucas Gabriel Rocha
                    ['person_id' => 24, 'relationship' => 'filha', 'is_head' => false],       // Luiza Rocha
                ],
            ],
            [
                'name' => 'Família Guimarães',
                'phone' => '(27) 3386-1122',
                'whatsapp' => '(27) 99543-2109',
                'email' => 'beatriz.guimaraes@ipb.org.br',
                'zipcode' => '29155-840',
                'street' => 'Rua Vitória',
                'number' => '18',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Beatriz Helena Guimarães.',
                'members' => [
                    ['person_id' => 69, 'relationship' => 'responsavel', 'is_head' => true],  // Beatriz Helena Guimarães
                    ['person_id' => 43, 'relationship' => 'outro', 'is_head' => false],       // Felipe Guimarães
                ],
            ],
            [
                'name' => 'Família Santos & Oliveira',
                'phone' => '(27) 3386-2233',
                'whatsapp' => '(27) 99432-1098',
                'email' => 'patricia.santos@ipb.org.br',
                'zipcode' => '29155-805',
                'street' => 'Av. Espírito Santo',
                'number' => '90',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Patrícia Oliveira Santos.',
                'members' => [
                    ['person_id' => 53, 'relationship' => 'responsavel', 'is_head' => true],  // Patrícia Oliveira Santos
                    ['person_id' => 3, 'relationship' => 'filho', 'is_head' => false],        // João Pedro Santos
                    ['person_id' => 5, 'relationship' => 'filho', 'is_head' => false],        // Miguel Oliveira
                ],
            ],
            [
                'name' => 'Família Costa & Alves',
                'phone' => '(27) 3386-3345',
                'whatsapp' => '(27) 99321-0987',
                'email' => 'fernanda.costa@ipb.org.br',
                'zipcode' => '29155-812',
                'street' => 'Rua 1º de Maio',
                'number' => '44',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Fernanda Alves Costa.',
                'members' => [
                    ['person_id' => 55, 'relationship' => 'responsavel', 'is_head' => true],  // Fernanda Alves Costa
                    ['person_id' => 8, 'relationship' => 'filha', 'is_head' => false],        // Helena Alves
                ],
            ],
            [
                'name' => 'Família Pereira & Gomes',
                'phone' => '(27) 3386-4456',
                'whatsapp' => '(27) 99210-9876',
                'email' => 'ricardo.pereira@ipb.org.br',
                'zipcode' => '29155-818',
                'street' => 'Rua Central',
                'number' => '102',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Ricardo Gomes Pereira.',
                'members' => [
                    ['person_id' => 56, 'relationship' => 'responsavel', 'is_head' => true],  // Ricardo Gomes Pereira
                    ['person_id' => 9, 'relationship' => 'filho', 'is_head' => false],        // Davi Pereira
                    ['person_id' => 12, 'relationship' => 'filha', 'is_head' => false],       // Beatriz Gomes
                ],
            ],
            [
                'name' => 'Família Souza & Ferreira',
                'phone' => '(27) 3386-5567',
                'whatsapp' => '(27) 99109-8765',
                'email' => 'andre.souza@ipb.org.br',
                'zipcode' => '29155-822',
                'street' => 'Rua do Comércio',
                'number' => '33',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de André Luiz Souza.',
                'members' => [
                    ['person_id' => 58, 'relationship' => 'responsavel', 'is_head' => true],  // André Luiz Souza
                    ['person_id' => 59, 'relationship' => 'conjuge', 'is_head' => false],     // Renata Ferreira Dias
                    ['person_id' => 2, 'relationship' => 'filha', 'is_head' => false],        // Ana Clara Souza
                    ['person_id' => 6, 'relationship' => 'filha', 'is_head' => false],        // Laura Ferreira
                ],
            ],
            [
                'name' => 'Família Ribeiro',
                'phone' => '(27) 3386-6678',
                'whatsapp' => '(27) 99098-7654',
                'email' => 'paulo.ribeiro@ipb.org.br',
                'zipcode' => '29155-828',
                'street' => 'Rua Santa Luzia',
                'number' => '60',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Paulo Henrique Ribeiro.',
                'members' => [
                    ['person_id' => 60, 'relationship' => 'responsavel', 'is_head' => true],  // Paulo Henrique Ribeiro
                    ['person_id' => 13, 'relationship' => 'filho', 'is_head' => false],       // Samuel Ribeiro
                ],
            ],
            [
                'name' => 'Família Almeida & Nunes',
                'phone' => '(27) 3386-7789',
                'whatsapp' => '(27) 98987-6543',
                'email' => 'cristiane.almeida@ipb.org.br',
                'zipcode' => '29155-842',
                'street' => 'Av. Cariacica',
                'number' => '210',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Cristiane Almeida Nunes.',
                'members' => [
                    ['person_id' => 61, 'relationship' => 'responsavel', 'is_head' => true],  // Cristiane Almeida Nunes
                    ['person_id' => 17, 'relationship' => 'filho', 'is_head' => false],       // Bernardo Almeida
                    ['person_id' => 22, 'relationship' => 'filha', 'is_head' => false],       // Isabela Nunes
                ],
            ],
            [
                'name' => 'Família Martins Rocha',
                'phone' => '(27) 3386-8890',
                'whatsapp' => '(27) 98876-5432',
                'email' => 'juliana.martins@ipb.org.br',
                'zipcode' => '29155-832',
                'street' => 'Rua Boa Esperança',
                'number' => '15',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Juliana Martins Rocha.',
                'members' => [
                    ['person_id' => 57, 'relationship' => 'responsavel', 'is_head' => true],  // Juliana Martins Rocha
                    ['person_id' => 11, 'relationship' => 'filho', 'is_head' => false],       // Gabriel Martins
                    ['person_id' => 26, 'relationship' => 'filha', 'is_head' => false],       // Mariana Dias
                ],
            ],
            [
                'name' => 'Família Antunes',
                'phone' => '(27) 3386-9901',
                'whatsapp' => '(27) 98765-4321',
                'email' => 'paulo.antunes@ipb.org.br',
                'zipcode' => '29155-838',
                'street' => 'Rua Nova',
                'number' => '50',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Paulo Henrique Antunes.',
                'members' => [
                    ['person_id' => 70, 'relationship' => 'responsavel', 'is_head' => true],  // Paulo Henrique Antunes
                    ['person_id' => 41, 'relationship' => 'filho', 'is_head' => false],       // Henrique Lopes
                ],
            ],
            [
                'name' => 'Família Zioto',
                'phone' => '(27) 3386-0012',
                'whatsapp' => '(27) 99600-1122',
                'email' => 'douglas.zioto@ipb.org.br',
                'zipcode' => '29155-814',
                'street' => 'Rua das Acácias',
                'number' => '80',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Douglas Zioto.',
                'members' => [
                    ['person_id' => 1, 'relationship' => 'responsavel', 'is_head' => true],   // Douglas Zioto
                    ['person_id' => 7, 'relationship' => 'filho', 'is_head' => false],        // Arthur Rodrigues
                ],
            ],
            [
                'name' => 'Família Freitas & Albuquerque',
                'phone' => '(27) 3386-1234',
                'whatsapp' => '(27) 98654-3210',
                'email' => 'juliana.albuquerque@ipb.org.br',
                'zipcode' => '29155-816',
                'street' => 'Rua do Sol',
                'number' => '95',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Família de Juliana Freitas Albuquerque.',
                'members' => [
                    ['person_id' => 74, 'relationship' => 'responsavel', 'is_head' => true],  // Juliana Freitas Albuquerque
                    ['person_id' => 29, 'relationship' => 'filho', 'is_head' => false],       // Enzo Freitas
                ],
            ],
            [
                'name' => 'Família Carvalho & Barbosa',
                'phone' => '(27) 3386-2345',
                'whatsapp' => '(27) 98543-2109',
                'email' => 'familia.carvalho@ipb.org.br',
                'zipcode' => '29155-824',
                'street' => 'Rua dos Cravos',
                'number' => '12',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 14, 'relationship' => 'responsavel', 'is_head' => true],  // Valentina Carvalho
                    ['person_id' => 16, 'relationship' => 'outro', 'is_head' => false],       // Manuela Barbosa
                ],
            ],
            [
                'name' => 'Família Araújo & Melo',
                'phone' => '(27) 3386-3457',
                'whatsapp' => '(27) 98432-1098',
                'email' => 'familia.araujo@ipb.org.br',
                'zipcode' => '29155-826',
                'street' => 'Rua da Amizade',
                'number' => '73',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 19, 'relationship' => 'responsavel', 'is_head' => true],  // Lucas Araújo
                    ['person_id' => 20, 'relationship' => 'filha', 'is_head' => false],       // Sophia Melo
                ],
            ],
            [
                'name' => 'Família Cardoso & Teixeira',
                'phone' => '(27) 3386-4568',
                'whatsapp' => '(27) 98321-0987',
                'email' => 'familia.cardoso@ipb.org.br',
                'zipcode' => '29155-834',
                'street' => 'Rua Esperança',
                'number' => '28',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 21, 'relationship' => 'responsavel', 'is_head' => true],  // Matheus Cardoso
                    ['person_id' => 23, 'relationship' => 'outro', 'is_head' => false],       // Rafael Teixeira
                ],
            ],
            [
                'name' => 'Família Moreira & Correia',
                'phone' => '(27) 3386-5679',
                'whatsapp' => '(27) 98210-9876',
                'email' => 'familia.moreira@ipb.org.br',
                'zipcode' => '29155-836',
                'street' => 'Rua Monte Sinai',
                'number' => '52',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 25, 'relationship' => 'responsavel', 'is_head' => true],  // Gustavo Moreira
                    ['person_id' => 27, 'relationship' => 'outro', 'is_head' => false],       // Heitor Correia
                ],
            ],
            [
                'name' => 'Família Castro & Monteiro',
                'phone' => '(27) 3386-6780',
                'whatsapp' => '(27) 98109-8765',
                'email' => 'familia.monteiro@ipb.org.br',
                'zipcode' => '29155-844',
                'street' => 'Rua das Orquídeas',
                'number' => '64',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 28, 'relationship' => 'responsavel', 'is_head' => true],  // Lívia Castro
                    ['person_id' => 30, 'relationship' => 'filha', 'is_head' => false],       // Cecília Monteiro
                ],
            ],
            [
                'name' => 'Família Vieira & Andrade',
                'phone' => '(27) 3386-7892',
                'whatsapp' => '(27) 98098-7654',
                'email' => 'familia.vieira@ipb.org.br',
                'zipcode' => '29155-846',
                'street' => 'Rua Belo Horizonte',
                'number' => '108',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 31, 'relationship' => 'responsavel', 'is_head' => true],  // Daniel Vieira
                    ['person_id' => 32, 'relationship' => 'filha', 'is_head' => false],       // Emanuelly Andrade
                ],
            ],
            [
                'name' => 'Família Batista & Campos',
                'phone' => '(27) 3386-8903',
                'whatsapp' => '(27) 97987-6543',
                'email' => 'familia.batista@ipb.org.br',
                'zipcode' => '29155-848',
                'street' => 'Rua dos Lírios',
                'number' => '39',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 33, 'relationship' => 'responsavel', 'is_head' => true],  // Caio Batista
                    ['person_id' => 34, 'relationship' => 'filha', 'is_head' => false],       // Yasmin Campos
                ],
            ],
            [
                'name' => 'Família Pinto & Cunha',
                'phone' => '(27) 3386-9014',
                'whatsapp' => '(27) 97876-5432',
                'email' => 'familia.cunha@ipb.org.br',
                'zipcode' => '29155-850',
                'street' => 'Rua da Paz',
                'number' => '81',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 36, 'relationship' => 'responsavel', 'is_head' => true],  // Lorena Pinto
                    ['person_id' => 37, 'relationship' => 'outro', 'is_head' => false],       // Nicolas Cunha
                ],
            ],
            [
                'name' => 'Família Farias & Rezende',
                'phone' => '(27) 3386-0125',
                'whatsapp' => '(27) 97765-4321',
                'email' => 'familia.farias@ipb.org.br',
                'zipcode' => '29155-852',
                'street' => 'Rua dos Missionários',
                'number' => '19',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 38, 'relationship' => 'responsavel', 'is_head' => true],  // Melissa Farias
                    ['person_id' => 42, 'relationship' => 'outro', 'is_head' => false],       // Amanda Rezende
                ],
            ],
            [
                'name' => 'Família Tavares & Neves',
                'phone' => '(27) 3386-1236',
                'whatsapp' => '(27) 97654-3210',
                'email' => 'familia.tavares@ipb.org.br',
                'zipcode' => '29155-854',
                'street' => 'Rua da Fé',
                'number' => '42',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 45, 'relationship' => 'responsavel', 'is_head' => true],  // Bruno Tavares
                    ['person_id' => 46, 'relationship' => 'outro', 'is_head' => false],       // Natália Neves
                ],
            ],
            [
                'name' => 'Família Borges & Coelho',
                'phone' => '(27) 3386-2347',
                'whatsapp' => '(27) 97543-2109',
                'email' => 'familia.coelho@ipb.org.br',
                'zipcode' => '29155-856',
                'street' => 'Rua Canaã',
                'number' => '67',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 48, 'relationship' => 'responsavel', 'is_head' => true],  // Camila Borges
                    ['person_id' => 49, 'relationship' => 'filho', 'is_head' => false],       // Thiago Coelho
                ],
            ],
            [
                'name' => 'Família Miranda & Duarte',
                'phone' => '(27) 3386-3458',
                'whatsapp' => '(27) 97432-1098',
                'email' => 'familia.miranda@ipb.org.br',
                'zipcode' => '29155-858',
                'street' => 'Rua Monte Hermom',
                'number' => '115',
                'district' => 'Campo Verde',
                'city' => 'Cariacica',
                'state' => 'ES',
                'notes' => 'Núcleo familiar da congregação.',
                'members' => [
                    ['person_id' => 50, 'relationship' => 'responsavel', 'is_head' => true],  // Gabriela Miranda
                    ['person_id' => 51, 'relationship' => 'outro', 'is_head' => false],       // Vinícius Duarte
                ],
            ],
        ];

        $totalInseridas = 0;
        $totalPessoas = 0;

        foreach ($familias as $data) {
            $membros = $data['members'] ?? [];
            unset($data['members']);

            $data['institution_id'] = $institutionId;
            $data['is_active'] = true;

            $family = Family::create($data);
            $totalInseridas++;

            foreach ($membros as $m) {
                DB::table('family_members')->insert([
                    'family_id' => $family->id,
                    'person_id' => $m['person_id'],
                    'relationship' => $m['relationship'],
                    'is_head' => $m['is_head'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                $totalPessoas++;
            }
        }

        $this->command?->info("{$totalInseridas} Núcleos Familiares criados com sucesso com {$totalPessoas} pessoas vinculadas!");
    }
}
