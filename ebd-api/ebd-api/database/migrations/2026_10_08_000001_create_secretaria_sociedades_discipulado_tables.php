<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // 1. Ampliação canônica de Membros (People)
        Schema::table('people', function (Blueprint $t) {
            $t->string('canonical_status', 40)->default('comungante')->after('is_active');
            $t->string('roll_number', 50)->nullable()->after('canonical_status');
            $t->string('reception_type', 60)->nullable()->after('roll_number');
            $t->date('reception_date')->nullable()->after('reception_type');
            $t->date('baptism_date')->nullable()->after('reception_date');
            $t->date('profession_date')->nullable()->after('baptism_date');
            $t->string('exit_type', 60)->nullable()->after('profession_date');
            $t->date('exit_date')->nullable()->after('exit_type');
            $t->string('marital_status', 30)->nullable()->after('exit_date');
            $t->string('spouse_name', 150)->nullable()->after('marital_status');
            $t->date('marriage_date')->nullable()->after('spouse_name');
            $t->string('phone', 30)->nullable()->after('marriage_date');
            $t->string('email', 100)->nullable()->after('phone');
            $t->string('cpf', 20)->nullable()->after('email');

            $t->index('canonical_status');
            $t->index('roll_number');
        });

        // 2. Livro de Atas do Conselho da Igreja
        Schema::create('atas_conselho', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->string('numero_ata', 50);
            $t->string('tipo', 40)->default('Ordinária');
            $t->date('data_reuniao');
            $t->string('horario', 30)->nullable();
            $t->string('local', 120)->nullable();
            $t->string('pastor_presidente', 120)->nullable();
            $t->string('secretario_conselho', 120)->nullable();
            $t->json('presbiters_presentes')->nullable();
            $t->text('abertura')->nullable();
            $t->text('pauta')->nullable();
            $t->text('deliberacoes')->nullable();
            $t->string('status', 30)->default('Aprovada');
            $t->timestamps();

            $t->index('institution_id');
            $t->index('data_reuniao');
        });

        // 3. Cartas de Transferência (Entrada e Saída)
        Schema::create('cartas_transferencia', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->string('numero_carta', 50);
            $t->string('tipo', 30)->default('Emitida'); // Emitida (saída) ou Recebida (entrada)
            $t->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $t->string('igreja_origem', 150);
            $t->string('igreja_destino', 150);
            $t->string('cidade_uf', 100)->nullable();
            $t->date('data_emissao');
            $t->date('data_validade')->nullable();
            $t->date('data_recebimento')->nullable();
            $t->text('observacoes')->nullable();
            $t->string('status', 30)->default('Ativa'); // Ativa, Concluída, Expirada, Cancelada
            $t->timestamps();

            $t->index('institution_id');
            $t->index('person_id');
            $t->index('status');
        });

        // 4. Sociedades Internas (SAF, UPH, UMP, UPA, UCP)
        Schema::create('sociedades_internas', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->string('sigla', 20); // SAF, UPH, UMP, UPA, UCP
            $t->string('nome', 120);
            $t->string('lema', 255)->nullable();
            $t->string('faixa_etaria', 80)->nullable();
            $t->foreignId('financial_cost_center_id')->nullable()->constrained('financial_cost_centers')->nullOnDelete();
            $t->integer('ano_exercicio')->default(2026);
            $t->timestamps();

            $t->index('institution_id');
            $t->index('sigla');
        });

        // 5. Diretorias das Sociedades
        Schema::create('sociedade_diretoria', function (Blueprint $t) {
            $t->id();
            $t->foreignId('sociedade_id')->constrained('sociedades_internas')->cascadeOnDelete();
            $t->string('cargo', 60); // Presidente, Vice, 1ª Secretária, 2ª Secretária, Tesoureiro, Conselheiro
            $t->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $t->integer('ano')->default(2026);
            $t->timestamps();

            $t->index('sociedade_id');
            $t->index('person_id');
        });

        // 6. Atividades e Reuniões das Sociedades
        Schema::create('sociedade_atividades', function (Blueprint $t) {
            $t->id();
            $t->foreignId('sociedade_id')->constrained('sociedades_internas')->cascadeOnDelete();
            $t->string('titulo', 150);
            $t->date('data');
            $t->string('horario', 30)->nullable();
            $t->string('tipo', 60)->default('Reunião Plenária');
            $t->string('local', 120)->nullable();
            $t->text('descricao')->nullable();
            $t->timestamps();

            $t->index('sociedade_id');
            $t->index('data');
        });

        // 7. Discipulado / Classe de Catecúmenos
        Schema::create('discipulado_catecumenos', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $t->foreignId('mentor_id')->nullable()->constrained('users')->nullOnDelete();
            $t->string('fase', 60)->default('Classe de Catecúmenos');
            $t->date('data_inicio');
            $t->date('data_conclusao')->nullable();
            $t->integer('licoes_concluidas')->default(0);
            $t->integer('total_licoes')->default(10);
            $t->text('observacoes')->nullable();
            $t->timestamps();

            $t->index('institution_id');
            $t->index('person_id');
            $t->index('fase');
        });

        // 8. Biblioteca da Igreja - Livros
        Schema::create('biblioteca_livros', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->string('titulo', 180);
            $t->string('autor', 150);
            $t->string('categoria', 80)->default('Vida Cristã');
            $t->string('editora', 100)->nullable();
            $t->integer('ano')->nullable();
            $t->string('isbn', 40)->nullable();
            $t->integer('quantidade_total')->default(1);
            $t->integer('quantidade_disponivel')->default(1);
            $t->string('localizacao', 100)->nullable();
            $t->timestamps();

            $t->index('institution_id');
            $t->index('categoria');
        });

        // 9. Biblioteca da Igreja - Empréstimos
        Schema::create('biblioteca_emprestimos', function (Blueprint $t) {
            $t->id();
            $t->foreignId('livro_id')->constrained('biblioteca_livros')->cascadeOnDelete();
            $t->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $t->date('data_emprestimo');
            $t->date('data_prevista_devolucao');
            $t->date('data_devolucao')->nullable();
            $t->string('status', 30)->default('Emprestado'); // Emprestado, Devolvido, Atrasado
            $t->text('observacoes')->nullable();
            $t->timestamps();

            $t->index('livro_id');
            $t->index('person_id');
            $t->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('biblioteca_emprestimos');
        Schema::dropIfExists('biblioteca_livros');
        Schema::dropIfExists('discipulado_catecumenos');
        Schema::dropIfExists('sociedade_atividades');
        Schema::dropIfExists('sociedade_diretoria');
        Schema::dropIfExists('sociedades_internas');
        Schema::dropIfExists('cartas_transferencia');
        Schema::dropIfExists('atas_conselho');

        Schema::table('people', function (Blueprint $t) {
            $t->dropColumn([
                'canonical_status',
                'roll_number',
                'reception_type',
                'reception_date',
                'baptism_date',
                'profession_date',
                'exit_type',
                'exit_date',
                'marital_status',
                'spouse_name',
                'marriage_date',
                'phone',
                'email',
                'cpf',
            ]);
        });
    }
};
