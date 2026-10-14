<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('coletas_dizimos', function (Blueprint $table) {
            if (!Schema::hasColumn('coletas_dizimos', 'code')) {
                $table->string('code', 50)->nullable()->after('id');
            }
            if (!Schema::hasColumn('coletas_dizimos', 'total_dizimos')) {
                $table->decimal('total_dizimos', 12, 2)->default(0.00);
            }
            if (!Schema::hasColumn('coletas_dizimos', 'oferta_dinheiro')) {
                $table->decimal('oferta_dinheiro', 12, 2)->default(0.00);
            }
            if (!Schema::hasColumn('coletas_dizimos', 'oferta_pix')) {
                $table->decimal('oferta_pix', 12, 2)->default(0.00);
            }
            if (!Schema::hasColumn('coletas_dizimos', 'oferta_transferencia')) {
                $table->decimal('oferta_transferencia', 12, 2)->default(0.00);
            }
            if (!Schema::hasColumn('coletas_dizimos', 'total_ofertas')) {
                $table->decimal('total_ofertas', 12, 2)->default(0.00);
            }
            if (!Schema::hasColumn('coletas_dizimos', 'total_geral')) {
                $table->decimal('total_geral', 12, 2)->default(0.00);
            }
        });

        Schema::table('lancamentos_dizimos', function (Blueprint $table) {
            if (!Schema::hasColumn('lancamentos_dizimos', 'payment_method')) {
                $table->string('payment_method', 30)->default('dinheiro');
            }
            if (!Schema::hasColumn('lancamentos_dizimos', 'envelope_number')) {
                $table->string('envelope_number', 50)->nullable();
            }
            if (!Schema::hasColumn('lancamentos_dizimos', 'contribuinte_nome')) {
                $table->string('contribuinte_nome', 255)->nullable();
            }
        });

        if (!Schema::hasTable('conferencia_impressoes')) {
            Schema::create('conferencia_impressoes', function (Blueprint $table) {
                $table->id();
                $table->foreignId('coleta_id')->constrained('coletas_dizimos')->cascadeOnDelete();
                $table->string('via', 50);
                $table->string('tipo', 30)->default('original');
                $table->string('status', 30)->default('sucesso');
                $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->string('device_info', 255)->nullable();
                $table->timestamp('created_at')->useCurrent();

                $table->index('coleta_id');
            });
        }
    }

    public function down(): void {
        Schema::dropIfExists('conferencia_impressoes');
    }
};
