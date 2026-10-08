<?php

namespace Database\Seeders;

use App\Models\ColetaDizimo;
use App\Models\Institution;
use App\Models\LancamentoDizimo;
use App\Models\Person;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class ColetasFictionalDataSeeder extends Seeder
{
    public function run(): void
    {
        $institution = Institution::find(5) ?? Institution::first();
        if (!$institution) {
            return;
        }

        $admin = User::first();
        $adminId = $admin ? $admin->id : 1;

        // 1. Garantir membros da igreja
        $membersData = [
            ['full_name' => 'Rev. Carlos Eduardo Silveira', 'envelope_number' => '001', 'birth_date' => '1982-04-15'],
            ['full_name' => 'Presb. Marcos Vinícius Toledo', 'envelope_number' => '002', 'birth_date' => '1975-08-22'],
            ['full_name' => 'Presb. Roberto Alencar Fontes', 'envelope_number' => '003', 'birth_date' => '1979-11-03'],
            ['full_name' => 'Diác. André Luiz Ramos', 'envelope_number' => '004', 'birth_date' => '1986-02-18'],
            ['full_name' => 'Diác. Felipe Mendes Bastos', 'envelope_number' => '005', 'birth_date' => '1991-09-29'],
            ['full_name' => 'Mariana Castro Silveira', 'envelope_number' => '006', 'birth_date' => '1984-06-12'],
            ['full_name' => 'Lucas Gabriel Rocha', 'envelope_number' => '007', 'birth_date' => '1998-03-05'],
            ['full_name' => 'Beatriz Helena Guimarães', 'envelope_number' => '008', 'birth_date' => '1994-07-19'],
            ['full_name' => 'Paulo Henrique Antunes', 'envelope_number' => '009', 'birth_date' => '1970-12-14'],
            ['full_name' => 'Camila Siqueira Paiva', 'envelope_number' => '010', 'birth_date' => '1989-10-30'],
            ['full_name' => 'Daniela Martins Prado', 'envelope_number' => '011', 'birth_date' => '1993-01-25'],
            ['full_name' => 'José Fernando Peixoto', 'envelope_number' => '012', 'birth_date' => '1968-05-08'],
        ];

        $people = [];
        foreach ($membersData as $m) {
            $people[] = Person::firstOrCreate(
                [
                    'institution_id' => $institution->id,
                    'full_name' => $m['full_name'],
                ],
                [
                    'envelope_number' => $m['envelope_number'],
                    'birth_date' => $m['birth_date'],
                    'is_active' => true,
                    'is_tither' => true,
                    'tither_since' => '2020-01-01',
                    'can_teach' => true,
                    'can_superintend' => true,
                ]
            );
        }

        // 2. Coletas para os Domingos
        $sundays = [
            // Julho 2026
            '2026-07-05', '2026-07-12', '2026-07-19', '2026-07-26',
            // Agosto 2026
            '2026-08-02', '2026-08-09', '2026-08-16', '2026-08-23', '2026-08-30',
            // Setembro 2026
            '2026-09-06', '2026-09-13', '2026-09-20', '2026-09-27',
            // Outubro 2026
            '2026-10-04', '2026-10-11',
        ];

        foreach ($sundays as $sundayStr) {
            $date = Carbon::parse($sundayStr);
            $isLastSunday = ($sundayStr === '2026-10-11');

            // --- A) CULTO MATUTINO (EBD) ---
            $coletaManha = ColetaDizimo::updateOrCreate(
                [
                    'institution_id' => $institution->id,
                    'date' => $date->toDateString(),
                    'service_meeting' => 'Culto Matutino & EBD',
                ],
                [
                    'description' => 'Coleta do Culto Matutino e Escola Bíblica Dominical de ' . $date->format('d/m/Y'),
                    'status' => 'Fechada',
                    'created_by' => $adminId,
                    'opened_at' => $date->copy()->setTime(8, 30),
                    'closed_by' => $adminId,
                    'closed_at' => $date->copy()->setTime(11, 45),
                    'verified_by' => $adminId,
                    'verified_at' => $date->copy()->setTime(12, 0),
                    'notes' => 'Conferência realizada pela superintendência e tesouraria.',
                ]
            );

            // Lançamentos da manhã
            LancamentoDizimo::where('coleta_id', $coletaManha->id)->delete();
            $lancamentosManha = [
                ['person' => $people[1], 'amount' => 750.00, 'type' => 'dizimo', 'notes' => 'Dízimo mensal via envelope'],
                ['person' => $people[7], 'amount' => 380.00, 'type' => 'dizimo', 'notes' => 'Dízimo mensal'],
                ['person' => $people[9], 'amount' => 420.00, 'type' => 'dizimo', 'notes' => 'Dízimo mensal'],
                ['person' => null, 'amount' => 290.00, 'type' => 'oferta', 'notes' => 'Oferta geral das classes da EBD'],
                ['person' => null, 'amount' => 85.50, 'type' => 'oferta', 'notes' => 'Oferta da classe infantil'],
            ];

            $totalManha = 0;
            $unidManha = 0;
            foreach ($lancamentosManha as $item) {
                LancamentoDizimo::create([
                    'coleta_id' => $coletaManha->id,
                    'person_id' => $item['person'] ? $item['person']->id : null,
                    'amount' => $item['amount'],
                    'contribution_type' => $item['type'],
                    'is_unidentified' => is_null($item['person']),
                    'notes' => $item['notes'],
                    'created_by' => $adminId,
                ]);
                $totalManha += $item['amount'];
                if (is_null($item['person'])) {
                    $unidManha++;
                }
            }

            $coletaManha->update([
                'total_amount' => $totalManha,
                'entry_count' => count($lancamentosManha),
                'unidentified_count' => $unidManha,
            ]);

            // --- B) CULTO SOLENE VESPERTINO ---
            $statusNoite = $isLastSunday ? 'Aberta' : 'Fechada';
            $coletaNoite = ColetaDizimo::updateOrCreate(
                [
                    'institution_id' => $institution->id,
                    'date' => $date->toDateString(),
                    'service_meeting' => 'Culto Solene Vespertino',
                ],
                [
                    'description' => 'Culto Solene Vespertino de Adoração de ' . $date->format('d/m/Y'),
                    'status' => $statusNoite,
                    'created_by' => $adminId,
                    'opened_at' => $date->copy()->setTime(18, 0),
                    'closed_by' => $isLastSunday ? null : $adminId,
                    'closed_at' => $isLastSunday ? null : $date->copy()->setTime(20, 30),
                    'verified_by' => $isLastSunday ? null : $adminId,
                    'verified_at' => $isLastSunday ? null : $date->copy()->setTime(20, 45),
                    'notes' => $isLastSunday ? 'Coleta em andamento para lançamentos da tesouraria.' : 'Contagem finalizada e conferida pelos diáconos de plantão.',
                ]
            );

            LancamentoDizimo::where('coleta_id', $coletaNoite->id)->delete();
            $lancamentosNoite = [
                ['person' => $people[0], 'amount' => 1200.00, 'type' => 'dizimo', 'notes' => 'Dízimo pastoral'],
                ['person' => $people[2], 'amount' => 950.00, 'type' => 'dizimo', 'notes' => 'Dízimo via envelope'],
                ['person' => $people[3], 'amount' => 600.00, 'type' => 'dizimo', 'notes' => 'Dízimo mensal'],
                ['person' => $people[4], 'amount' => 450.00, 'type' => 'dizimo', 'notes' => 'Dízimo mensal'],
                ['person' => $people[5], 'amount' => 500.00, 'type' => 'dizimo', 'notes' => 'Dízimo mensal'],
                ['person' => $people[6], 'amount' => 320.00, 'type' => 'dizimo', 'notes' => 'Dízimo mensal'],
                ['person' => $people[8], 'amount' => 850.00, 'type' => 'dizimo', 'notes' => 'Dízimo mensal'],
                ['person' => $people[10], 'amount' => 400.00, 'type' => 'dizimo', 'notes' => 'Dízimo mensal'],
                ['person' => $people[11], 'amount' => 650.00, 'type' => 'dizimo', 'notes' => 'Dízimo mensal'],
                ['person' => null, 'amount' => 740.00, 'type' => 'oferta', 'notes' => 'Oferta alçada em dinheiro durante o ofertório'],
                ['person' => null, 'amount' => 350.00, 'type' => 'oferta_missoes', 'notes' => 'Oferta específica para Missões Nacionais e Mundiais'],
            ];

            $totalNoite = 0;
            $unidNoite = 0;
            foreach ($lancamentosNoite as $item) {
                LancamentoDizimo::create([
                    'coleta_id' => $coletaNoite->id,
                    'person_id' => $item['person'] ? $item['person']->id : null,
                    'amount' => $item['amount'],
                    'contribution_type' => $item['type'],
                    'is_unidentified' => is_null($item['person']),
                    'notes' => $item['notes'],
                    'created_by' => $adminId,
                ]);
                $totalNoite += $item['amount'];
                if (is_null($item['person'])) {
                    $unidNoite++;
                }
            }

            $coletaNoite->update([
                'total_amount' => $totalNoite,
                'entry_count' => count($lancamentosNoite),
                'unidentified_count' => $unidNoite,
            ]);
        }
    }
}
