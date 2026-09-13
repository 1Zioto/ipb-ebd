<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('coletas_dizimos', function (Blueprint $t) {
            $t->id();
            $t->date('date');
            $t->string('description', 255)->nullable();
            $t->string('service_meeting', 100)->nullable();
            $t->string('status', 40)->default('Aberta');
            $t->foreignId('created_by')->constrained('users');
            $t->timestamp('opened_at');
            $t->foreignId('closed_by')->nullable()->constrained('users');
            $t->timestamp('closed_at')->nullable();
            $t->foreignId('verified_by')->nullable()->constrained('users');
            $t->timestamp('verified_at')->nullable();
            $t->integer('entry_count')->default(0);
            $t->decimal('total_amount', 12, 2)->default(0.00);
            $t->integer('unidentified_count')->default(0);
            $t->text('notes')->nullable();
            $t->timestamps();
            $t->softDeletes();

            $t->index('date');
            $t->index('status');
        });

        Schema::create('lancamentos_dizimos', function (Blueprint $t) {
            $t->id();
            $t->foreignId('coleta_id')->constrained('coletas_dizimos')->cascadeOnDelete();
            $t->foreignId('person_id')->nullable()->constrained('people')->nullOnDelete();
            $t->decimal('amount', 12, 2);
            $t->string('contribution_type', 50)->default('envelope');
            $t->boolean('is_unidentified')->default(false);
            $t->text('notes')->nullable();
            $t->foreignId('created_by')->constrained('users');
            $t->foreignId('updated_by')->nullable()->constrained('users');
            $t->timestamps();

            $t->index('coleta_id');
            $t->index('person_id');
            $t->index('is_unidentified');
        });

        Schema::create('consolidacao_dizimos_mensal', function (Blueprint $t) {
            $t->id();
            $t->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $t->integer('year');
            $t->integer('month');
            $t->decimal('total_amount', 12, 2)->default(0.00);
            $t->integer('contribution_count')->default(0);
            $t->timestamps();

            $t->unique(['person_id', 'year', 'month']);
            $t->index(['year', 'month']);
        });

        Schema::create('alertas_dizimos', function (Blueprint $t) {
            $t->id();
            $t->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $t->string('alert_type', 60);
            $t->date('start_date')->nullable();
            $t->date('detection_date');
            $t->decimal('variation_percentage', 5, 2)->nullable();
            $t->json('reference_calculation')->nullable();
            $t->string('status', 40)->default('Novo');
            $t->foreignId('pastor_id')->nullable()->constrained('users');
            $t->text('notes')->nullable();
            $t->timestamp('resolved_at')->nullable();
            $t->timestamps();

            $t->index('person_id');
            $t->index('status');
        });

        Schema::create('acompanhamento_dizimos', function (Blueprint $t) {
            $t->id();
            $t->foreignId('alerta_id')->nullable()->constrained('alertas_dizimos')->nullOnDelete();
            $t->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $t->foreignId('responsible_id')->constrained('users');
            $t->date('date');
            $t->string('type', 50)->default('pastoral');
            $t->text('notes')->nullable();
            $t->text('next_action')->nullable();
            $t->date('review_date')->nullable();
            $t->string('status', 40)->default('Em andamento');
            $t->string('conclusion', 100)->nullable();
            $t->timestamps();

            $t->index('person_id');
            $t->index('alerta_id');
        });

        Schema::create('solicitacoes_diaconato', function (Blueprint $t) {
            $t->id();
            $t->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $t->foreignId('pastor_id')->constrained('users');
            $t->foreignId('diacono_id')->nullable()->constrained('users');
            $t->text('pastor_notes');
            $t->string('status', 40)->default('Pendente');
            $t->timestamps();

            $t->index('person_id');
            $t->index('status');
        });

        Schema::create('auditoria_dizimos', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $t->string('action', 100);
            $t->string('entity', 80);
            $t->unsignedBigInteger('entity_id')->nullable();
            $t->json('details')->nullable();
            $t->string('ip_address', 45)->nullable();
            $t->string('user_agent', 255)->nullable();
            $t->timestamp('created_at')->useCurrent();

            $t->index('user_id');
            $t->index(['entity', 'entity_id']);
        });
    }

    public function down(): void {
        Schema::dropIfExists('auditoria_dizimos');
        Schema::dropIfExists('solicitacoes_diaconato');
        Schema::dropIfExists('acompanhamento_dizimos');
        Schema::dropIfExists('alertas_dizimos');
        Schema::dropIfExists('consolidacao_dizimos_mensal');
        Schema::dropIfExists('lancamentos_dizimos');
        Schema::dropIfExists('coletas_dizimos');
    }
};
