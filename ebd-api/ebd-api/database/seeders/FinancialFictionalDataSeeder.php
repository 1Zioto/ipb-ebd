<?php

namespace Database\Seeders;

use App\Models\FinancialAccount;
use App\Models\FinancialCategory;
use App\Models\FinancialCostCenter;
use App\Models\FinancialMonthClosing;
use App\Models\FinancialTransaction;
use App\Models\Institution;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class FinancialFictionalDataSeeder extends Seeder
{
    public function run(): void
    {
        // Encontra ou usa a instituição 5 (Igreja Presbiteriana em Campo Verde) ou primeira instituição
        $institution = Institution::find(5) ?: Institution::first();
        if (! $institution) {
            $this->command?->error('Nenhuma instituição encontrada para semear dados fictícios.');
            return;
        }

        $user = User::where('institution_id', $institution->id)->first() ?: User::first();
        if (! $user) {
            $this->command?->error('Nenhum usuário encontrado.');
            return;
        }

        $institutionId = $institution->id;
        $userId = $user->id;

        // Limpa transações anteriores de teste nesta instituição se existirem
        FinancialTransaction::where('institution_id', $institutionId)->forceDelete();
        FinancialMonthClosing::where('institution_id', $institutionId)->delete();

        // Obtém ou define contas
        $contaCorrente = FinancialAccount::firstOrCreate(
            ['institution_id' => $institutionId, 'name' => 'Banco do Brasil - CC 48.291-0'],
            [
                'account_type' => 'corrente',
                'bank_name' => 'Banco do Brasil',
                'agency' => '3291-4',
                'account_number' => '48.291-0',
                'initial_balance' => 15420.50,
                'current_balance' => 15420.50,
                'is_active' => true,
            ]
        );

        $caixaTesouraria = FinancialAccount::firstOrCreate(
            ['institution_id' => $institutionId, 'name' => 'Caixa Físico / Tesouraria'],
            [
                'account_type' => 'caixa',
                'initial_balance' => 850.00,
                'current_balance' => 850.00,
                'is_active' => true,
            ]
        );

        // Mapeia categorias
        $catDizimos = FinancialCategory::where('institution_id', $institutionId)->where('code', '1.01')->first();
        $catOfertasGerais = FinancialCategory::where('institution_id', $institutionId)->where('code', '1.02')->first();
        $catOfertasMissoes = FinancialCategory::where('institution_id', $institutionId)->where('code', '1.03')->first();
        $catOfertasEbd = FinancialCategory::where('institution_id', $institutionId)->where('code', '1.04')->first();
        $catEventos = FinancialCategory::where('institution_id', $institutionId)->where('code', '1.06')->first();
        $catRendimentos = FinancialCategory::where('institution_id', $institutionId)->where('code', '1.07')->first();

        $catPrebenda = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.01.01')->first();
        $catInss = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.01.02')->first();
        $catPreletores = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.01.03')->first();
        $catZeladoria = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.01.04')->first();
        $catEnergia = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.02.01')->first();
        $catAgua = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.02.02')->first();
        $catInternet = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.02.03')->first();
        $catLimpeza = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.02.04')->first();
        $catManutencao = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.02.05')->first();
        $catRevistasEbd = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.03.01')->first();
        $catLanchesEbd = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.03.02')->first();
        $catSom = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.03.03')->first();
        $catDiaconia = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.03.04')->first();
        $catInfantil = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.03.05')->first();
        $catUmp = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.03.06')->first();
        $catMissoes = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.04.01')->first();
        $catQuota = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.04.02')->first();
        $catHonorariosContabeis = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.05.01')->first();
        $catTarifas = FinancialCategory::where('institution_id', $institutionId)->where('code', '2.05.02')->first();

        // Mapeia centros de custo
        $ccConselho = FinancialCostCenter::where('institution_id', $institutionId)->where('code', 'CC-01')->first();
        $ccEbd = FinancialCostCenter::where('institution_id', $institutionId)->where('code', 'CC-02')->first();
        $ccLouvor = FinancialCostCenter::where('institution_id', $institutionId)->where('code', 'CC-03')->first();
        $ccDiaconia = FinancialCostCenter::where('institution_id', $institutionId)->where('code', 'CC-04')->first();
        $ccMissoes = FinancialCostCenter::where('institution_id', $institutionId)->where('code', 'CC-05')->first();
        $ccUmp = FinancialCostCenter::where('institution_id', $institutionId)->where('code', 'CC-06')->first();
        $ccInfantil = FinancialCostCenter::where('institution_id', $institutionId)->where('code', 'CC-09')->first();
        $ccObras = FinancialCostCenter::where('institution_id', $institutionId)->where('code', 'CC-10')->first();

        // Definição dos meses: Julho, Agosto, Setembro e Outubro (2026)
        $monthsConfig = [
            [
                'year' => 2026,
                'month' => 7,
                'closing_status' => 'fechado',
                'notes' => 'Fechamento aprovado pelo Conselho da Igreja e encaminhado para o escritório de contabilidade em 04/08/2026.',
                'dizimos' => [4210.00, 3950.00, 4850.00, 5100.00],
                'ofertas' => [520.00, 480.00, 610.00, 590.00],
                'ebd_ofertas' => [210.00, 195.00, 240.00, 220.00],
                'energia' => 840.50,
                'agua' => 195.30,
                'limpeza' => 380.00,
                'manutencao' => 450.00,
                'has_revistas' => true,
                'has_ebf' => true,
            ],
            [
                'year' => 2026,
                'month' => 8,
                'closing_status' => 'fechado',
                'notes' => 'Conciliação bancária conferida. Balancete de Agosto sem divergências, assinado pelo Conselho Fiscal.',
                'dizimos' => [4550.00, 4120.00, 4380.00, 5420.00, 4890.00],
                'ofertas' => [610.00, 540.00, 580.00, 720.00, 650.00],
                'ebd_ofertas' => [230.00, 210.00, 190.00, 280.00, 250.00],
                'energia' => 910.20,
                'agua' => 215.80,
                'limpeza' => 410.00,
                'manutencao' => 620.00,
                'has_som' => true,
            ],
            [
                'year' => 2026,
                'month' => 9,
                'closing_status' => 'fechado',
                'notes' => 'Movimentações de Setembro auditadas. Inclui arrecadação de cantina e subsídio da UMP.',
                'dizimos' => [4890.00, 4620.00, 4980.00, 5750.00],
                'ofertas' => [680.00, 590.00, 640.00, 780.00],
                'ebd_ofertas' => [240.00, 260.00, 220.00, 310.00],
                'energia' => 875.40,
                'agua' => 205.10,
                'limpeza' => 395.00,
                'manutencao' => 310.00,
                'has_ump_evento' => true,
            ],
            [
                'year' => 2026,
                'month' => 10,
                'closing_status' => 'aberto',
                'notes' => 'Mês em andamento. Fechamento previsto para o primeiro domingo de novembro.',
                'dizimos' => [5200.00],
                'ofertas' => [710.00],
                'ebd_ofertas' => [290.00],
                'energia' => 895.00,
                'agua' => 210.00,
                'limpeza' => 420.00,
                'manutencao' => 180.00,
                'has_revistas' => true,
            ],
        ];

        $transactionsToInsert = [];

        foreach ($monthsConfig as $m) {
            $year = $m['year'];
            $month = $m['month'];

            // 1. Dízimos dos Domingos
            foreach ($m['dizimos'] as $idx => $val) {
                $day = 1 + ($idx * 7);
                $date = Carbon::createFromDate($year, $month, min($day, 28))->toDateString();

                $transactionsToInsert[] = [
                    'institution_id' => $institutionId,
                    'financial_account_id' => $contaCorrente->id,
                    'financial_category_id' => $catDizimos?->id,
                    'financial_cost_center_id' => $ccConselho?->id,
                    'type' => 'receita',
                    'date' => $date,
                    'competency_date' => $date,
                    'amount' => $val,
                    'description' => "Coleta de Dízimos - Culto de Domingo (" . ($idx + 1) . "º Domingo)",
                    'entity_name' => 'Membros e Contribuintes',
                    'document_number' => "DZ-{$year}{$month}-0" . ($idx + 1),
                    'payment_method' => 'pix',
                    'status' => 'pago',
                    'paid_at' => $date . ' 21:30:00',
                    'notes' => 'Dízimos identificados e envelopes conferidos.',
                    'created_by' => $userId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            // 2. Ofertas Gerais de Culto
            foreach ($m['ofertas'] as $idx => $val) {
                $day = 1 + ($idx * 7);
                $date = Carbon::createFromDate($year, $month, min($day, 28))->toDateString();

                $transactionsToInsert[] = [
                    'institution_id' => $institutionId,
                    'financial_account_id' => $caixaTesouraria->id,
                    'financial_category_id' => $catOfertasGerais?->id,
                    'financial_cost_center_id' => $ccConselho?->id,
                    'type' => 'receita',
                    'date' => $date,
                    'competency_date' => $date,
                    'amount' => $val,
                    'description' => "Ofertas Gerais de Culto - " . ($idx + 1) . "º Domingo",
                    'entity_name' => 'Igreja / Congregação',
                    'document_number' => "OF-{$year}{$month}-0" . ($idx + 1),
                    'payment_method' => 'dinheiro',
                    'status' => 'pago',
                    'paid_at' => $date . ' 21:00:00',
                    'created_by' => $userId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            // 3. Ofertas da EBD
            foreach ($m['ebd_ofertas'] as $idx => $val) {
                $day = 1 + ($idx * 7);
                $date = Carbon::createFromDate($year, $month, min($day, 28))->toDateString();

                $transactionsToInsert[] = [
                    'institution_id' => $institutionId,
                    'financial_account_id' => $caixaTesouraria->id,
                    'financial_category_id' => $catOfertasEbd?->id,
                    'financial_cost_center_id' => $ccEbd?->id,
                    'type' => 'receita',
                    'date' => $date,
                    'competency_date' => $date,
                    'amount' => $val,
                    'description' => "Ofertas das Classes da EBD - " . ($idx + 1) . "º Domingo",
                    'entity_name' => 'Superintendência da EBD',
                    'document_number' => "EBD-{$year}{$month}-0" . ($idx + 1),
                    'payment_method' => 'dinheiro',
                    'status' => 'pago',
                    'paid_at' => $date . ' 11:30:00',
                    'created_by' => $userId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            // 4. Oferta Missionária Mensal (dia 14)
            $dateMissoes = Carbon::createFromDate($year, $month, 14)->toDateString();
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catOfertasMissoes?->id,
                'financial_cost_center_id' => $ccMissoes?->id,
                'type' => 'receita',
                'date' => $dateMissoes,
                'competency_date' => $dateMissoes,
                'amount' => 1450.00,
                'description' => 'Campanha Mensal de Oferta Missionária',
                'entity_name' => 'Secretaria de Missões da IPB',
                'document_number' => "MIS-{$year}{$month}",
                'payment_method' => 'pix',
                'status' => 'pago',
                'paid_at' => $dateMissoes . ' 20:00:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 5. Rendimento de Aplicação (dia 28)
            $dateRend = Carbon::createFromDate($year, $month, 28)->toDateString();
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catRendimentos?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'receita',
                'date' => $dateRend,
                'competency_date' => $dateRend,
                'amount' => 112.45,
                'description' => 'Rendimento de Aplicação CDB / Tesouraria BB',
                'entity_name' => 'Banco do Brasil',
                'document_number' => "EXT-{$year}{$month}",
                'payment_method' => 'outro',
                'status' => 'pago',
                'paid_at' => $dateRend . ' 00:00:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // Evento UMP se configurado
            if (! empty($m['has_ump_evento'])) {
                $dateUmp = Carbon::createFromDate($year, $month, 18)->toDateString();
                $transactionsToInsert[] = [
                    'institution_id' => $institutionId,
                    'financial_account_id' => $contaCorrente->id,
                    'financial_category_id' => $catEventos?->id,
                    'financial_cost_center_id' => $ccUmp?->id,
                    'type' => 'receita',
                    'date' => $dateUmp,
                    'competency_date' => $dateUmp,
                    'amount' => 840.00,
                    'description' => 'Inscrições Congresso da Mocidade Presbiteriana (UMP)',
                    'entity_name' => 'Participantes do Congresso',
                    'document_number' => "EV-UMP-{$month}",
                    'payment_method' => 'pix',
                    'status' => 'pago',
                    'paid_at' => $dateUmp . ' 18:00:00',
                    'created_by' => $userId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            // DESPESAS FIXAS MENSAIS

            // 1. Prebenda Pastoral (dia 05)
            $datePrebenda = Carbon::createFromDate($year, $month, 5)->toDateString();
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catPrebenda?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'despesa',
                'date' => $datePrebenda,
                'competency_date' => $datePrebenda,
                'amount' => 5800.00,
                'description' => 'Prebenda e Sustento Pastoral Ministerial',
                'entity_name' => 'Rev. Pastor Titular',
                'document_number' => "REC-PREB-{$year}{$month}",
                'payment_method' => 'pix',
                'status' => 'pago',
                'paid_at' => $datePrebenda . ' 10:00:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 2. INSS e Previdência Social Pastoral (dia 15)
            $dateInss = Carbon::createFromDate($year, $month, 15)->toDateString();
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catInss?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'despesa',
                'date' => $dateInss,
                'competency_date' => $dateInss,
                'amount' => 1160.00,
                'description' => 'GPS - Previdência Social e Encargos Pastorais',
                'entity_name' => 'Receita Federal do Brasil',
                'document_number' => "GPS-{$year}{$month}",
                'payment_method' => 'boleto',
                'status' => 'pago',
                'paid_at' => $dateInss . ' 14:00:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 3. Zeladoria e Limpeza (dia 05)
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catZeladoria?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'despesa',
                'date' => $datePrebenda,
                'competency_date' => $datePrebenda,
                'amount' => 1412.00,
                'description' => 'Serviços de Zeladoria e Higienização do Templo',
                'entity_name' => 'Maria de Fátima Silva (Zeladora)',
                'document_number' => "REC-ZEL-{$year}{$month}",
                'payment_method' => 'pix',
                'status' => 'pago',
                'paid_at' => $datePrebenda . ' 11:30:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 4. Energia Elétrica (dia 10)
            $dateEnergia = Carbon::createFromDate($year, $month, 10)->toDateString();
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catEnergia?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'despesa',
                'date' => $dateEnergia,
                'competency_date' => $dateEnergia,
                'amount' => $m['energia'],
                'description' => 'Conta de Energia Elétrica - Templo Central e Salas EBD',
                'entity_name' => 'EDP Espírito Santo Distribuição',
                'document_number' => "EDP-{$year}{$month}-01",
                'payment_method' => 'boleto',
                'status' => 'pago',
                'paid_at' => $dateEnergia . ' 09:15:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 5. Água e Esgoto (dia 12)
            $dateAgua = Carbon::createFromDate($year, $month, 12)->toDateString();
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catAgua?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'despesa',
                'date' => $dateAgua,
                'competency_date' => $dateAgua,
                'amount' => $m['agua'],
                'description' => 'Fatura de Água e Saneamento',
                'entity_name' => 'CESAN - Cia Espírito-Santense de Saneamento',
                'document_number' => "CES-{$year}{$month}",
                'payment_method' => 'boleto',
                'status' => 'pago',
                'paid_at' => $dateAgua . ' 10:00:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 6. Internet e TI (dia 15)
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catInternet?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'despesa',
                'date' => $dateInss,
                'competency_date' => $dateInss,
                'amount' => 189.90,
                'description' => 'Link Dedicado Fibra Óptica 500Mbps - Transmissões e Secretaria',
                'entity_name' => 'Vivo Telefônica Brasil',
                'document_number' => "FAT-VIVO-{$year}{$month}",
                'payment_method' => 'boleto',
                'status' => 'pago',
                'paid_at' => $dateInss . ' 09:30:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 7. Material de Limpeza (dia 16)
            $dateLimp = Carbon::createFromDate($year, $month, 16)->toDateString();
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $caixaTesouraria->id,
                'financial_category_id' => $catLimpeza?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'despesa',
                'date' => $dateLimp,
                'competency_date' => $dateLimp,
                'amount' => $m['limpeza'],
                'description' => 'Produtos de limpeza, álcool, papel toalha e descartáveis',
                'entity_name' => 'Atacadão Distribuidora',
                'document_number' => "NF-ATAC-{$year}{$month}",
                'payment_method' => 'dinheiro',
                'status' => 'pago',
                'paid_at' => $dateLimp . ' 15:00:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 8. Manutenção Predial (dia 20)
            $dateManut = Carbon::createFromDate($year, $month, 20)->toDateString();
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catManutencao?->id,
                'financial_cost_center_id' => $ccObras?->id,
                'type' => 'despesa',
                'date' => $dateManut,
                'competency_date' => $dateManut,
                'amount' => $m['manutencao'],
                'description' => 'Manutenção elétrica, substituição de lâmpadas de LED e reparos hidráulicos',
                'entity_name' => 'Eletro Campo Verde Materiais',
                'document_number' => "NF-MANUT-{$year}{$month}",
                'payment_method' => 'pix',
                'status' => 'pago',
                'paid_at' => $dateManut . ' 16:30:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 9. Lanches da EBD (dia 22)
            $dateLanche = Carbon::createFromDate($year, $month, 22)->toDateString();
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $caixaTesouraria->id,
                'financial_category_id' => $catLanchesEbd?->id,
                'financial_cost_center_id' => $ccEbd?->id,
                'type' => 'despesa',
                'date' => $dateLanche,
                'competency_date' => $dateLanche,
                'amount' => 450.00,
                'description' => 'Lanche dominical dos alunos e professores da EBD (pães, sucos, frutas)',
                'entity_name' => 'Padaria Pão Nosso',
                'document_number' => "REC-EBD-{$year}{$month}",
                'payment_method' => 'dinheiro',
                'status' => 'pago',
                'paid_at' => $dateLanche . ' 12:00:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 10. Diaconia / Cestas de Alimentos (dia 11)
            $dateDiac = Carbon::createFromDate($year, $month, 11)->toDateString();
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catDiaconia?->id,
                'financial_cost_center_id' => $ccDiaconia?->id,
                'type' => 'despesa',
                'date' => $dateDiac,
                'competency_date' => $dateDiac,
                'amount' => 680.00,
                'description' => 'Aquisição de 4 cestas básicas para auxílio a famílias em vulnerabilidade',
                'entity_name' => 'Supermercado Central',
                'document_number' => "NF-DIAC-{$year}{$month}",
                'payment_method' => 'pix',
                'status' => 'pago',
                'paid_at' => $dateDiac . ' 14:15:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 11. Sustento Missionário (dia 10)
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catMissoes?->id,
                'financial_cost_center_id' => $ccMissoes?->id,
                'type' => 'despesa',
                'date' => $dateEnergia,
                'competency_date' => $dateEnergia,
                'amount' => 1500.00,
                'description' => 'Repasse mensal de sustento missionário - Campo Sertão (APMT)',
                'entity_name' => 'Agência Presbiteriana de Missões Transculturais (APMT)',
                'document_number' => "APMT-REP-{$year}{$month}",
                'payment_method' => 'pix',
                'status' => 'pago',
                'paid_at' => $dateEnergia . ' 10:45:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 12. Quota Presbiterial (dia 20)
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catQuota?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'despesa',
                'date' => $dateManut,
                'competency_date' => $dateManut,
                'amount' => 850.00,
                'description' => 'Quota estatutária do Presbitério de Vitória (PRVT / IPB)',
                'entity_name' => 'Presbitério de Vitória',
                'document_number' => "QUOTA-PRVT-{$year}{$month}",
                'payment_method' => 'pix',
                'status' => 'pago',
                'paid_at' => $dateManut . ' 11:00:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 13. Honorários Contábeis (dia 10)
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catHonorariosContabeis?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'despesa',
                'date' => $dateEnergia,
                'competency_date' => $dateEnergia,
                'amount' => 650.00,
                'description' => 'Honorários mensais - Assessoria e Escrituração Contábil',
                'entity_name' => 'Exata Contabilidade & Auditoria Eireli',
                'document_number' => "NFS-CONT-{$year}{$month}",
                'payment_method' => 'pix',
                'status' => 'pago',
                'paid_at' => $dateEnergia . ' 13:30:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // 14. Tarifas Bancárias (dia 28)
            $transactionsToInsert[] = [
                'institution_id' => $institutionId,
                'financial_account_id' => $contaCorrente->id,
                'financial_category_id' => $catTarifas?->id,
                'financial_cost_center_id' => $ccConselho?->id,
                'type' => 'despesa',
                'date' => $dateRend,
                'competency_date' => $dateRend,
                'amount' => 49.90,
                'description' => 'Tarifa de Pacote de Serviços PJ / Manutenção Bancária',
                'entity_name' => 'Banco do Brasil',
                'document_number' => "TAR-BB-{$year}{$month}",
                'payment_method' => 'outro',
                'status' => 'pago',
                'paid_at' => $dateRend . ' 01:00:00',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            // Despesas eventuais específicas
            if (! empty($m['has_revistas'])) {
                $dateRev = Carbon::createFromDate($year, $month, 3)->toDateString();
                $transactionsToInsert[] = [
                    'institution_id' => $institutionId,
                    'financial_account_id' => $contaCorrente->id,
                    'financial_category_id' => $catRevistasEbd?->id,
                    'financial_cost_center_id' => $ccEbd?->id,
                    'type' => 'despesa',
                    'date' => $dateRev,
                    'competency_date' => $dateRev,
                    'amount' => 980.00,
                    'description' => 'Revistas da EBD - Trimestre (Editora Cultura Cristã / CEP)',
                    'entity_name' => 'Editora Cultura Cristã - CEP IPB',
                    'document_number' => "NF-CEP-{$year}{$month}",
                    'payment_method' => 'boleto',
                    'status' => 'pago',
                    'paid_at' => $dateRev . ' 11:00:00',
                    'created_by' => $userId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            if (! empty($m['has_ebf'])) {
                $dateEbf = Carbon::createFromDate($year, $month, 18)->toDateString();
                $transactionsToInsert[] = [
                    'institution_id' => $institutionId,
                    'financial_account_id' => $contaCorrente->id,
                    'financial_category_id' => $catInfantil?->id,
                    'financial_cost_center_id' => $ccInfantil?->id,
                    'type' => 'despesa',
                    'date' => $dateEbf,
                    'competency_date' => $dateEbf,
                    'amount' => 850.00,
                    'description' => 'Materiais lúdicos, lembrancinhas e lanches da Escola Bíblica de Férias (EBF)',
                    'entity_name' => 'Livraria & Papelaria Criativa',
                    'document_number' => "NF-EBF-{$year}{$month}",
                    'payment_method' => 'pix',
                    'status' => 'pago',
                    'paid_at' => $dateEbf . ' 15:40:00',
                    'created_by' => $userId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            if (! empty($m['has_som'])) {
                $dateSom = Carbon::createFromDate($year, $month, 24)->toDateString();
                $transactionsToInsert[] = [
                    'institution_id' => $institutionId,
                    'financial_account_id' => $contaCorrente->id,
                    'financial_category_id' => $catSom?->id,
                    'financial_cost_center_id' => $ccLouvor?->id,
                    'type' => 'despesa',
                    'date' => $dateSom,
                    'competency_date' => $dateSom,
                    'amount' => 520.00,
                    'description' => 'Manutenção mesa de som e compra de 2 microfones Shure com cabos blindados',
                    'entity_name' => 'Mega Som Instrumentos Musicais',
                    'document_number' => "NF-SOM-{$year}{$month}",
                    'payment_method' => 'pix',
                    'status' => 'pago',
                    'paid_at' => $dateSom . ' 17:00:00',
                    'created_by' => $userId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
        }

        // Insere as transações
        foreach ($transactionsToInsert as $txData) {
            FinancialTransaction::create($txData);
        }

        // Recalcula saldos das contas
        $contaCorrente->recalculateBalance();
        $caixaTesouraria->recalculateBalance();

        // Cria os fechamentos de mês oficiais usando o FinancialService
        $service = app(\App\Services\Financial\FinancialService::class);
        foreach ($monthsConfig as $m) {
            if ($m['closing_status'] === 'fechado') {
                $service->closeMonth($m['year'], $m['month'], $m['notes'], $user, $institutionId);
            }
        }
    }
}
