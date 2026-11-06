<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Solictações de Cadastro de Membros via Link Público (Aprovação pela Secretaria)
        if (!Schema::hasTable('church_member_applications')) {
            Schema::create('church_member_applications', function (Blueprint $table) {
                $table->id();
                $table->foreignId('institution_id')->constrained('institutions')->cascadeOnDelete();
                $table->string('full_name');
                $table->date('birth_date');
                $table->string('gender', 10)->nullable();
                $table->string('marital_status', 30)->nullable();
                $table->string('cpf', 20)->nullable()->index();
                $table->string('rg', 20)->nullable();
                $table->string('email')->nullable()->index();
                $table->string('phone', 30)->index();
                $table->string('address')->nullable();
                $table->string('address_number', 20)->nullable();
                $table->string('address_complement')->nullable();
                $table->string('neighborhood')->nullable();
                $table->string('city')->nullable();
                $table->string('state', 10)->nullable();
                $table->string('postal_code', 20)->nullable();
                $table->string('profession')->nullable();
                $table->string('education')->nullable();
                $table->string('father_name')->nullable();
                $table->string('mother_name')->nullable();
                $table->string('spouse_name')->nullable();
                $table->boolean('is_communicant')->default(true);
                $table->string('ecclesiastical_condition', 50)->default('comungante');
                $table->string('origin_church')->nullable();
                $table->string('reception_mode', 50)->nullable();
                $table->date('baptism_date')->nullable();
                $table->string('baptism_church')->nullable();
                $table->date('profession_of_faith_date')->nullable();
                $table->string('status', 30)->default('pendente')->index(); // pendente, aprovado, rejeitado
                $table->text('notes')->nullable();
                $table->foreignId('reviewed_by_user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->timestamp('reviewed_at')->nullable();
                $table->text('rejection_reason')->nullable();
                $table->foreignId('approved_person_id')->nullable()->constrained('people')->nullOnDelete();
                $table->timestamps();
            });
        }

        // 2. Fechamento de Exercício Financeiro e Prestação de Contas Anual Imutável
        if (!Schema::hasTable('financial_annual_closings')) {
            Schema::create('financial_annual_closings', function (Blueprint $table) {
                $table->id();
                $table->foreignId('institution_id')->constrained('institutions')->cascadeOnDelete();
                $table->integer('year')->index();
                $table->date('closing_date');
                $table->decimal('initial_balance', 15, 2)->default(0);
                $table->decimal('total_revenues', 15, 2)->default(0);
                $table->decimal('total_expenses', 15, 2)->default(0);
                $table->decimal('final_balance', 15, 2)->default(0);
                $table->decimal('surplus_deficit', 15, 2)->default(0);
                $table->json('summary_snapshot');
                $table->string('status', 30)->default('em_analise')->index(); // em_analise, aprovado_conselho, publicado_membros
                $table->text('conselho_parecer')->nullable();
                $table->foreignId('closed_by_user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->foreignId('approved_by_user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->timestamp('published_at')->nullable();
                $table->timestamps();

                $table->unique(['institution_id', 'year']);
            });
        }

        // 3. Controle Dinâmico por Igreja do Aplicativo do Membro
        if (!Schema::hasTable('church_app_configs')) {
            Schema::create('church_app_configs', function (Blueprint $table) {
                $table->id();
                $table->foreignId('institution_id')->unique()->constrained('institutions')->cascadeOnDelete();
                $table->json('modules_config');
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('church_app_configs');
        Schema::dropIfExists('financial_annual_closings');
        Schema::dropIfExists('church_member_applications');
    }
};

