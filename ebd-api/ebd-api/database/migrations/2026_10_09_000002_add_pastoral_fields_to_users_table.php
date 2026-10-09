<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', function (Blueprint $t) {
            if (!Schema::hasColumn('users', 'is_pastor')) {
                $t->boolean('is_pastor')->default(false)->after('is_active');
            }
            if (!Schema::hasColumn('users', 'titulo_pastoral')) {
                $t->string('titulo_pastoral', 150)->nullable()->after('is_pastor');
            }
            if (!Schema::hasColumn('users', 'cargo_pastoral')) {
                $t->string('cargo_pastoral', 120)->nullable()->after('titulo_pastoral');
            }
            if (!Schema::hasColumn('users', 'is_pastor_titular')) {
                $t->boolean('is_pastor_titular')->default(false)->after('cargo_pastoral');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $t) {
            $t->dropColumn(['is_pastor', 'titulo_pastoral', 'cargo_pastoral', 'is_pastor_titular']);
        });
    }
};
