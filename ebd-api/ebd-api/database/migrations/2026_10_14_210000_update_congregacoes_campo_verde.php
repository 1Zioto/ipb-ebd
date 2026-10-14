<?php

use App\Models\Institution;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Excluir Congregação Campo Grande (ID 7) e Congregação Jardim América (ID 8)
        DB::table('institutions')
            ->whereIn('id', [7, 8])
            ->update([
                'deleted_at' => now(),
                'status' => 'inativa',
            ]);

        // 2. Criar Congregação Presbiteriana de Bela Aurora vinculada à IP Campo Verde (ID 5)
        $exists = DB::table('institutions')
            ->where('parent_institution_id', 5)
            ->where('name', 'like', '%Bela Aurora%')
            ->whereNull('deleted_at')
            ->exists();

        if (! $exists) {
            Institution::create([
                'name' => 'Congregação Presbiteriana de Bela Aurora',
                'short_name' => 'Cong. Bela Aurora',
                'type' => 'congregacao',
                'status' => 'ativa',
                'parent_institution_id' => 5,
                'city' => 'Cariacica',
                'state' => 'ES',
                'country' => 'Brasil',
                'share_financials_with_parent' => true,
                'notes' => 'Única congregação vinculada à Igreja Presbiteriana de Campo Verde.',
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('institutions')
            ->whereIn('id', [7, 8])
            ->update([
                'deleted_at' => null,
                'status' => 'ativa',
            ]);

        DB::table('institutions')
            ->where('parent_institution_id', 5)
            ->where('name', 'like', '%Bela Aurora%')
            ->delete();
    }
};
