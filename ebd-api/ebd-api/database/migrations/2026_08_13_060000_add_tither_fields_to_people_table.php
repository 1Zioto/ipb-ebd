<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('people', function (Blueprint $t) {
            $t->boolean('is_tither')->default(false)->after('can_superintend');
            $t->date('tither_since')->nullable()->after('is_tither');
            $t->string('envelope_number', 50)->nullable()->after('tither_since');

            $t->index('is_tither');
            $t->index('envelope_number');
        });
    }

    public function down(): void {
        Schema::table('people', function (Blueprint $t) {
            $t->dropIndex(['is_tither']);
            $t->dropIndex(['envelope_number']);
            $t->dropColumn(['is_tither', 'tither_since', 'envelope_number']);
        });
    }
};
