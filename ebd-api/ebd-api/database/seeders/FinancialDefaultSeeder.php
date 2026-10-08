<?php

namespace Database\Seeders;

use App\Models\FinancialAccount;
use App\Models\FinancialCategory;
use App\Models\FinancialCostCenter;
use App\Models\Institution;
use Illuminate\Database\Seeder;

class FinancialDefaultSeeder extends Seeder
{
    public function run(): void
    {
        $institutions = Institution::all();

        // Se não houver instituição, criamos o plano com institution_id null ou executamos para cada instituição
        if ($institutions->isEmpty()) {
            $this->seedForInstitution(null);
        } else {
            foreach ($institutions as $inst) {
                $this->seedForInstitution($inst->id);
            }
        }
    }

    public function seedForInstitution(?int $institutionId): void
    {
        // 1. Contas Padrão
        $accounts = [
            ['name' => 'Caixa Central / Tesouraria', 'account_type' => 'caixa', 'initial_balance' => 0.00],
            ['name' => 'Conta Corrente Principal', 'account_type' => 'corrente', 'bank_name' => 'Banco do Brasil', 'initial_balance' => 0.00],
        ];

        foreach ($accounts as $acc) {
            FinancialAccount::firstOrCreate(
                ['institution_id' => $institutionId, 'name' => $acc['name']],
                $acc + ['current_balance' => $acc['initial_balance'], 'is_active' => true]
            );
        }

        // 2. Centros de Custo Padrão
        $costCenters = [
            ['code' => 'CC-01', 'name' => 'Conselho & Administração Geral', 'description' => 'Despesas e receitas gerais da igreja e conselho'],
            ['code' => 'CC-02', 'name' => 'EBD - Escola Bíblica Dominical', 'description' => 'Revistas, materiais pedagógicos e eventos da EBD'],
            ['code' => 'CC-03', 'name' => 'Ministério de Louvor e Som', 'description' => 'Equipamentos de som, instrumentos e manutenção musical'],
            ['code' => 'CC-04', 'name' => 'Diaconia & Ação Social', 'description' => 'Socorro a famílias, cestas básicas e zeladoria'],
            ['code' => 'CC-05', 'name' => 'Missões & Evangelização', 'description' => 'Sustento missionário, folhetos e viagens missionárias'],
            ['code' => 'CC-06', 'name' => 'Mocidade (UMP)', 'description' => 'Atividades, encontros e retiros da juventude'],
            ['code' => 'CC-07', 'name' => 'Sociedade Feminina (SAF)', 'description' => 'Reuniões, congressos e projetos das mulheres'],
            ['code' => 'CC-08', 'name' => 'Homens Presbiterianos (UPH)', 'description' => 'Encontros de oração e projetos dos homens'],
            ['code' => 'CC-09', 'name' => 'Ministério Infantil (UCP / EBF)', 'description' => 'Trabalho com crianças, cultinho e material lúdico'],
            ['code' => 'CC-10', 'name' => 'Patrimônio & Obras', 'description' => 'Reformas, ampliações, climatização e infraestrutura'],
        ];

        foreach ($costCenters as $cc) {
            FinancialCostCenter::firstOrCreate(
                ['institution_id' => $institutionId, 'name' => $cc['name']],
                $cc + ['is_active' => true]
            );
        }

        // 3. Categorias Contábeis / Plano de Contas
        $categories = [
            // RECEITAS
            ['code' => '1.01', 'name' => 'Dízimos', 'type' => 'receita', 'description' => 'Dízimos arrecadados de membros e congregados'],
            ['code' => '1.02', 'name' => 'Ofertas Gerais de Culto', 'type' => 'receita', 'description' => 'Ofertas regulares levantadas nos cultos'],
            ['code' => '1.03', 'name' => 'Ofertas Especiais e Missionárias', 'type' => 'receita', 'description' => 'Ofertas destinadas a missões ou alçadas específicas'],
            ['code' => '1.04', 'name' => 'Ofertas da EBD', 'type' => 'receita', 'description' => 'Arrecadação de ofertas das classes da Escola Dominical'],
            ['code' => '1.05', 'name' => 'Doações e Campanhas de Obras', 'type' => 'receita', 'description' => 'Doações específicas para patrimônio e obras'],
            ['code' => '1.06', 'name' => 'Eventos, Cantinas e Retiros', 'type' => 'receita', 'description' => 'Inscrições em retiros e arrecadação de cantinas'],
            ['code' => '1.07', 'name' => 'Rendimentos Financeiros', 'type' => 'receita', 'description' => 'Rendimentos de poupança ou aplicação bancária'],
            ['code' => '1.08', 'name' => 'Outras Receitas', 'type' => 'receita', 'description' => 'Receitas eventuais diversas'],

            // DESPESAS - PESSOAL
            ['code' => '2.01.01', 'name' => 'Prebenda e Sustento Pastoral', 'type' => 'despesa', 'description' => 'Prebenda e sustento ministerial pastoral'],
            ['code' => '2.01.02', 'name' => 'INSS, Previdência e Encargos', 'type' => 'despesa', 'description' => 'Encargos previdenciários e obrigações trabalhistas'],
            ['code' => '2.01.03', 'name' => 'Honorários e Preletores Convidados', 'type' => 'despesa', 'description' => 'Ajudas de custo a pastores convidados e preletores'],
            ['code' => '2.01.04', 'name' => 'Secretaria e Apoio Administrativo', 'type' => 'despesa', 'description' => 'Compensações de secretaria e atendimento'],

            // DESPESAS - PREDIAIS E CONSUMO
            ['code' => '2.02.01', 'name' => 'Energia Elétrica', 'type' => 'despesa', 'description' => 'Conta de luz da igreja e anexos'],
            ['code' => '2.02.02', 'name' => 'Água e Saneamento', 'type' => 'despesa', 'description' => 'Conta de água e esgoto do templo'],
            ['code' => '2.02.03', 'name' => 'Internet, Telefonia e TI', 'type' => 'despesa', 'description' => 'Link de internet, telefone e softwares'],
            ['code' => '2.02.04', 'name' => 'Material de Limpeza e Copa', 'type' => 'despesa', 'description' => 'Produtos de limpeza, descartáveis e café/água'],
            ['code' => '2.02.05', 'name' => 'Manutenção Predial e Reparos', 'type' => 'despesa', 'description' => 'Serviços elétricos, hidráulicos e pintura de rotina'],

            // DESPESAS - DEPARTAMENTAIS / EBD / MINISTÉRIOS
            ['code' => '2.03.01', 'name' => 'EBD - Revistas e Material Didático', 'type' => 'despesa', 'description' => 'Revistas da EBD (Editora Cultura Cristã / CEP) e livros'],
            ['code' => '2.03.02', 'name' => 'EBD - Lanches e Atividades Pedagógicas', 'type' => 'despesa', 'description' => 'Lanche dominical dos alunos e atividades em sala'],
            ['code' => '2.03.03', 'name' => 'Música e Som - Equipamentos e Cabos', 'type' => 'despesa', 'description' => 'Instrumentos, microfones, cabos e manutenção de som'],
            ['code' => '2.03.04', 'name' => 'Diaconia - Ação Social e Cestas', 'type' => 'despesa', 'description' => 'Cestas de alimentos e apoio a famílias carentes'],
            ['code' => '2.03.05', 'name' => 'Ministério Infantil - EBF e Recursos', 'type' => 'despesa', 'description' => 'Materiais lúdicos, papelaria e Escola Bíblica de Férias'],
            ['code' => '2.03.06', 'name' => 'Sociedades Internas (UMP, SAF, UPH)', 'type' => 'despesa', 'description' => 'Subsídios para atividades das sociedades internas'],

            // DESPESAS - MISSÕES E ECLESIÁSTICO
            ['code' => '2.04.01', 'name' => 'Sustento Missionário', 'type' => 'despesa', 'description' => 'Repasses para missionários e agências missionárias (APMT/JMN)'],
            ['code' => '2.04.02', 'name' => 'Quota Presbiterial / Sínodo / SC', 'type' => 'despesa', 'description' => 'Contribuições estatutárias ao Presbitério e Supremo Concílio'],

            // DESPESAS - ADMINISTRAÇÃO E TAXAS
            ['code' => '2.05.01', 'name' => 'Honorários Contábeis', 'type' => 'despesa', 'description' => 'Mensalidade do escritório de contabilidade'],
            ['code' => '2.05.02', 'name' => 'Tarifas Bancárias e Taxas de Operação', 'type' => 'despesa', 'description' => 'Cestas bancárias, taxas de boletos e transferências'],
            ['code' => '2.05.03', 'name' => 'Material de Escritório e Gráfica', 'type' => 'despesa', 'description' => 'Papel, toner de impressora e boletins dominicais'],

            // DESPESAS - PATRIMÔNIO
            ['code' => '2.06.01', 'name' => 'Obras e Reformas Estruturais', 'type' => 'despesa', 'description' => 'Construção, telhado, ampliação do templo'],
            ['code' => '2.06.02', 'name' => 'Aquisição de Bens e Equipamentos', 'type' => 'despesa', 'description' => 'Compra de computadores, ar-condicionado, projetor'],
        ];

        foreach ($categories as $cat) {
            FinancialCategory::firstOrCreate(
                ['institution_id' => $institutionId, 'code' => $cat['code']],
                $cat + ['is_active' => true]
            );
        }
    }
}
