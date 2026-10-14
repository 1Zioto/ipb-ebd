<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Supremo Concílio
        $supremoId = DB::table('institutions')
            ->where('type', 'supremo_concilio')
            ->value('id');

        if (! $supremoId) {
            $supremoId = DB::table('institutions')->insertGetId([
                'name' => 'Supremo Concílio da Igreja Presbiteriana do Brasil',
                'short_name' => 'SC-IPB',
                'type' => 'supremo_concilio',
                'status' => 'ativa',
                'city' => 'Brasília',
                'state' => 'DF',
                'country' => 'Brasil',
                'code' => 'INST-SCIPB1',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 2. Sínodo Central Espíritossantense (SCE)
        // Se existir "Sínodo Central", atualiza para o nome canônico completo
        $sinodo = DB::table('institutions')
            ->where('type', 'sinodo')
            ->where(function ($q) {
                $q->where('name', 'like', '%Central%')
                    ->orWhere('short_name', 'SCE')
                    ->orWhere('id', 2);
            })
            ->first();

        if ($sinodo) {
            DB::table('institutions')->where('id', $sinodo->id)->update([
                'name' => 'Sínodo Central Espíritossantense',
                'short_name' => 'SCE',
                'parent_institution_id' => $supremoId,
                'denominational_code' => '12',
                'city' => 'Vitória',
                'state' => 'ES',
                'country' => 'Brasil',
                'status' => 'ativa',
                'updated_at' => now(),
            ]);
            $sinodoId = $sinodo->id;
        } else {
            $sinodoId = DB::table('institutions')->insertGetId([
                'name' => 'Sínodo Central Espíritossantense',
                'short_name' => 'SCE',
                'type' => 'sinodo',
                'status' => 'ativa',
                'parent_institution_id' => $supremoId,
                'denominational_code' => '12',
                'city' => 'Vitória',
                'state' => 'ES',
                'country' => 'Brasil',
                'code' => 'INST-SCE012',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 3. Presbitério Sudeste Espírito Santo (PSES)
        $presbSudeste = DB::table('institutions')
            ->where('type', 'presbiterio')
            ->where(function ($q) {
                $q->where('name', 'like', '%Sudeste%')
                    ->orWhere('short_name', 'PSES')
                    ->orWhere('denominational_code', '218');
            })
            ->first();

        if ($presbSudeste) {
            DB::table('institutions')->where('id', $presbSudeste->id)->update([
                'name' => 'Presbitério Sudeste Espírito Santo',
                'short_name' => 'PSES',
                'parent_institution_id' => $sinodoId,
                'denominational_code' => '218',
                'city' => 'Cariacica',
                'state' => 'ES',
                'status' => 'ativa',
                'updated_at' => now(),
            ]);
            $presbId = $presbSudeste->id;
        } else {
            $presbId = DB::table('institutions')->insertGetId([
                'name' => 'Presbitério Sudeste Espírito Santo',
                'short_name' => 'PSES',
                'type' => 'presbiterio',
                'status' => 'ativa',
                'parent_institution_id' => $sinodoId,
                'denominational_code' => '218',
                'city' => 'Cariacica',
                'state' => 'ES',
                'country' => 'Brasil',
                'code' => 'INST-PSES218',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 4. Igreja Presbiteriana de Campo Verde (ID 5 ou por nome)
        $igrejaCampoVerde = DB::table('institutions')
            ->where('id', 5)
            ->orWhere(function ($q) {
                $q->where('name', 'like', '%Campo Verde%')
                    ->where('type', 'igreja');
            })
            ->first();

        if ($igrejaCampoVerde) {
            DB::table('institutions')->where('id', $igrejaCampoVerde->id)->update([
                'name' => 'Igreja Presbiteriana de Campo Verde',
                'short_name' => 'IP Campo Verde',
                'type' => 'igreja',
                'status' => 'ativa',
                'parent_institution_id' => $presbId,
                'denominational_code' => '2520',
                'city' => 'Cariacica',
                'state' => 'ES',
                'district' => 'Campo Verde',
                'street' => 'Av. Obede Emerick',
                'number' => 'S/N',
                'zipcode' => '29155-845',
                'email' => 'contato@ipbemcampoverde.com.br',
                'website' => 'http://ipbemcampoverde.com.br',
                'organization_date' => '1995-12-31',
                'updated_at' => now(),
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Não reverter para dados incorretos
    }
};
