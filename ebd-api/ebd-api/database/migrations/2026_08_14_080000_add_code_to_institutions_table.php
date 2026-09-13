<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('institutions', function (Blueprint $table) {
            $table->string('code', 30)->nullable()->after('type');
        });

        // Preencher instituições existentes com códigos únicos
        $institutions = DB::table('institutions')->whereNull('code')->get();
        foreach ($institutions as $inst) {
            $code = 'INST-' . strtoupper(Str::random(6));
            while (DB::table('institutions')->where('code', $code)->exists()) {
                $code = 'INST-' . strtoupper(Str::random(6));
            }
            DB::table('institutions')->where('id', $inst->id)->update(['code' => $code]);
        }

        Schema::table('institutions', function (Blueprint $table) {
            $table->unique('code');
        });
    }

    public function down(): void
    {
        Schema::table('institutions', function (Blueprint $table) {
            $table->dropUnique(['code']);
            $table->dropColumn('code');
        });
    }
};
