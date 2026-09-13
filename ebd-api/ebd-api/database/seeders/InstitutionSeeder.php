<?php

namespace Database\Seeders;

use App\Models\Institution;
use App\Models\InstitutionHistory;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class InstitutionSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Supremo Concílio
        $supremo = Institution::firstOrCreate(
            ['cnpj' => '00.000.000/0001-00'],
            [
                'name' => 'Supremo Concílio da Igreja Presbiteriana',
                'short_name' => 'Supremo Concílio',
                'type' => 'supremo_concilio',
                'status' => 'ativa',
                'parent_institution_id' => null,
                'city' => 'Brasília',
                'state' => 'DF',
                'country' => 'Brasil',
                'notes' => 'Órgão de autoridade máxima da denominação.',
            ]
        );

        // 2. Sínodo Central
        $sinodo = Institution::firstOrCreate(
            ['name' => 'Sínodo Central'],
            [
                'short_name' => 'Sínodo Central',
                'type' => 'sinodo',
                'status' => 'ativa',
                'parent_institution_id' => $supremo->id,
                'city' => 'Vitória',
                'state' => 'ES',
                'country' => 'Brasil',
            ]
        );

        // 3. Presbitérios
        $presbVitoria = Institution::firstOrCreate(
            ['name' => 'Presbitério de Vitória'],
            [
                'short_name' => 'Presbitério de Vitória',
                'type' => 'presbiterio',
                'status' => 'ativa',
                'parent_institution_id' => $sinodo->id,
                'city' => 'Vitória',
                'state' => 'ES',
            ]
        );

        $presbNorte = Institution::firstOrCreate(
            ['name' => 'Presbitério Norte'],
            [
                'short_name' => 'Presbitério Norte',
                'type' => 'presbiterio',
                'status' => 'ativa',
                'parent_institution_id' => $sinodo->id,
                'city' => 'Linhares',
                'state' => 'ES',
            ]
        );

        // 4. Igrejas
        $igrejaCampoVerde = Institution::firstOrCreate(
            ['name' => 'Igreja Presbiteriana em Campo Verde'],
            [
                'short_name' => 'IP Campo Verde',
                'type' => 'igreja',
                'status' => 'ativa',
                'parent_institution_id' => $presbVitoria->id,
                'city' => 'Cariacica',
                'state' => 'ES',
                'street' => 'Rua Principal',
                'number' => '100',
                'district' => 'Campo Verde',
                'zipcode' => '29140-000',
                'phone' => '(27) 3333-4444',
                'email' => 'contato@ipcampoverde.org.br',
            ]
        );

        $igrejaVilaVelha = Institution::firstOrCreate(
            ['name' => 'Igreja Presbiteriana de Vila Velha'],
            [
                'short_name' => 'IP Vila Velha',
                'type' => 'igreja',
                'status' => 'ativa',
                'parent_institution_id' => $presbVitoria->id,
                'city' => 'Vila Velha',
                'state' => 'ES',
            ]
        );

        // 5. Congregações
        $congCampoGrande = Institution::firstOrCreate(
            ['name' => 'Congregação Campo Grande'],
            [
                'short_name' => 'Cong. Campo Grande',
                'type' => 'congregacao',
                'status' => 'ativa',
                'parent_institution_id' => $igrejaCampoVerde->id,
                'city' => 'Cariacica',
                'state' => 'ES',
            ]
        );

        $congJardimAmerica = Institution::firstOrCreate(
            ['name' => 'Congregação Jardim América'],
            [
                'short_name' => 'Cong. Jardim América',
                'type' => 'congregacao',
                'status' => 'ativa',
                'parent_institution_id' => $igrejaCampoVerde->id,
                'city' => 'Cariacica',
                'state' => 'ES',
            ]
        );

        // Registrar históricos iniciais
        foreach ([$supremo, $sinodo, $presbVitoria, $presbNorte, $igrejaCampoVerde, $igrejaVilaVelha, $congCampoGrande, $congJardimAmerica] as $inst) {
            InstitutionHistory::firstOrCreate(
                ['institution_id' => $inst->id, 'event_type' => 'criacao'],
                [
                    'title' => 'Instituição Organizada',
                    'description' => "Cadastro inicial da instituição {$inst->name}.",
                ]
            );
        }

        // Vincular todos os registros existentes sem instituição para a igreja Campo Verde por padrão
        $defaultInstId = $igrejaCampoVerde->id;

        $tables = [
            'people', 'users', 'classes', 'ebd_events', 'coletas_dizimos',
            'lancamentos_dizimos', 'consolidacao_dizimos_mensal', 'alertas_dizimos',
            'acompanhamento_dizimos', 'solicitacoes_diaconato', 'auditoria_dizimos',
            'audit_logs', 'announcements',
        ];

        foreach ($tables as $t) {
            if (DB::getSchemaBuilder()->hasTable($t) && DB::getSchemaBuilder()->hasColumn($t, 'institution_id')) {
                DB::table($t)->whereNull('institution_id')->update(['institution_id' => $defaultInstId]);
            }
        }
    }
}
