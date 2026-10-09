<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Rol de Sócios / Membros Inscritos de cada Sociedade Interna (SAF, UPH, UMP, UPA, UCP)
        Schema::create('sociedade_membros', function (Blueprint $t) {
            $t->id();
            $t->foreignId('sociedade_id')->constrained('sociedades_internas')->cascadeOnDelete();
            $t->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $t->string('tipo_socio', 30)->default('efetivo'); // 'efetivo', 'cooperador'
            $t->date('data_admissao')->nullable();
            $t->string('status', 30)->default('ativo'); // 'ativo', 'inativo', 'licenciado'
            $t->string('cargo_atual', 60)->nullable(); // Cargo caso ocupe (ex: 'Presidente', 'Secretária', 'Conselheiro')
            $t->text('observacoes')->nullable();
            $t->timestamps();

            $t->unique(['sociedade_id', 'person_id'], 'soc_membro_unique');
            $t->index('sociedade_id');
            $t->index('person_id');
            $t->index('status');
        });

        // 2. Livro de Atas Próprio de cada Sociedade Interna
        Schema::create('sociedade_atas', function (Blueprint $t) {
            $t->id();
            $t->foreignId('sociedade_id')->constrained('sociedades_internas')->cascadeOnDelete();
            $t->string('numero_ata', 30); // ex: "Ata nº 01/2026"
            $t->string('titulo', 160); // ex: "Reunião Plenária de Abertura do Exercício"
            $t->string('tipo_reuniao', 60)->default('Plenária Ordinária'); // 'Plenária Ordinária', 'Plenária Extraordinária', 'Reunião de Diretoria', 'Assembleia Geral Eletiva'
            $t->date('data_reuniao');
            $t->string('horario', 30)->nullable();
            $t->string('local', 120)->nullable();
            $t->foreignId('presidente_id')->nullable()->constrained('people')->nullOnDelete();
            $t->foreignId('secretario_id')->nullable()->constrained('people')->nullOnDelete();
            $t->text('pauta')->nullable();
            $t->longText('conteudo');
            $t->integer('presentes_count')->default(0);
            $t->string('status', 30)->default('Aprovada'); // 'Rascunho', 'Aprovada', 'Assinada'
            $t->date('visto_conselho_data')->nullable(); // Data em que o Conselho da Igreja examinou e visou a ata
            $t->string('visto_conselho_relator', 120)->nullable(); // Presbítero ou Pastor que visou
            $t->timestamps();

            $t->index('sociedade_id');
            $t->index('data_reuniao');
            $t->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sociedade_atas');
        Schema::dropIfExists('sociedade_membros');
    }
};
