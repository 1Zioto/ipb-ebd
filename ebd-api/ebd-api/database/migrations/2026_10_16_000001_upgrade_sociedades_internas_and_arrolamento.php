<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // 1. Ampliação da tabela sociedades_internas
        Schema::table('sociedades_internas', function (Blueprint $t) {
            if (!Schema::hasColumn('sociedades_internas', 'target_gender')) {
                $t->string('target_gender', 20)->default('Ambos')->after('lema');
            }
            if (!Schema::hasColumn('sociedades_internas', 'min_age')) {
                $t->integer('min_age')->nullable()->after('target_gender');
            }
            if (!Schema::hasColumn('sociedades_internas', 'max_age')) {
                $t->integer('max_age')->nullable()->after('min_age');
            }
            if (!Schema::hasColumn('sociedades_internas', 'is_active')) {
                $t->boolean('is_active')->default(true)->after('ano_exercicio');
            }
            if (!Schema::hasColumn('sociedades_internas', 'notes')) {
                $t->text('notes')->nullable()->after('is_active');
            }
        });

        // 2. Adição do campo gender na tabela people
        Schema::table('people', function (Blueprint $t) {
            if (!Schema::hasColumn('people', 'gender')) {
                $t->string('gender', 20)->nullable()->after('canonical_status');
                $t->index('gender');
            }
        });

        // 3. Ampliação da tabela sociedade_membros para isolamento e rastreabilidade
        Schema::table('sociedade_membros', function (Blueprint $t) {
            if (!Schema::hasColumn('sociedade_membros', 'institution_id')) {
                $t->foreignId('institution_id')->nullable()->after('id')->constrained('institutions')->nullOnDelete();
                $t->index('institution_id');
            }
            if (!Schema::hasColumn('sociedade_membros', 'created_by')) {
                $t->foreignId('created_by')->nullable()->after('status')->constrained('users')->nullOnDelete();
            }
        });

        // 4. Preencher institution_id em sociedade_membros com base na sociedade
        DB::statement("
            UPDATE sociedade_membros sm
            SET institution_id = si.institution_id
            FROM sociedades_internas si
            WHERE sm.sociedade_id = si.id
            AND sm.institution_id IS NULL
        ");

        // 5. Configurar valores de referência oficiais da IPB para as sociedades existentes
        $sociedadesIPB = [
            'UCP' => ['gender' => 'Ambos', 'min' => 0, 'max' => 11, 'notes' => 'Crianças até 11 anos'],
            'UPA' => ['gender' => 'Ambos', 'min' => 12, 'max' => 17, 'notes' => 'Adolescentes de 12 a 17 anos'],
            'UMP' => ['gender' => 'Ambos', 'min' => 18, 'max' => 32, 'notes' => 'Jovens de 18 a 32 anos (com flexibilidade até 35 anos)'],
            'SAF' => ['gender' => 'Feminino', 'min' => 18, 'max' => null, 'notes' => 'Mulheres a partir de 18 anos'],
            'UPH' => ['gender' => 'Masculino', 'min' => 18, 'max' => null, 'notes' => 'Homens a partir de 18 anos'],
            'UPI' => ['gender' => 'Ambos', 'min' => 60, 'max' => null, 'notes' => 'Membros da melhor idade (60 anos ou mais)'],
        ];

        foreach ($sociedadesIPB as $sigla => $cfg) {
            DB::table('sociedades_internas')
                ->where('sigla', $sigla)
                ->update([
                    'target_gender' => $cfg['gender'],
                    'min_age' => $cfg['min'],
                    'max_age' => $cfg['max'],
                    'is_active' => true,
                    'notes' => $cfg['notes'],
                    'updated_at' => now(),
                ]);
        }

        // 6. Inferência inteligente inicial de gender para os membros existentes em people
        $nomesFemininos = [
            'Ana', 'Maria', 'Laura', 'Helena', 'Alice', 'Beatriz', 'Valentina', 'Manuela',
            'Júlia', 'Sophia', 'Isabela', 'Luiza', 'Mariana', 'Lívia', 'Cecília', 'Emanuelly',
            'Yasmin', 'Lorena', 'Melissa', 'Esther', 'Amanda', 'Letícia', 'Natália', 'Camila',
            'Gabriela', 'Patrícia', 'Fernanda', 'Juliana', 'Renata', 'Cristiane', 'Daniela'
        ];

        foreach ($nomesFemininos as $nome) {
            DB::table('people')
                ->where(function ($q) use ($nome) {
                    $q->where('full_name', 'like', $nome . ' %')
                      ->orWhere('full_name', '=', $nome);
                })
                ->whereNull('gender')
                ->update(['gender' => 'Feminino']);
        }

        // Demais pessoas sem gender definido recebem 'Masculino'
        DB::table('people')->whereNull('gender')->update(['gender' => 'Masculino']);
    }

    public function down(): void
    {
        Schema::table('sociedade_membros', function (Blueprint $t) {
            if (Schema::hasColumn('sociedade_membros', 'created_by')) {
                $t->dropForeign(['created_by']);
                $t->dropColumn('created_by');
            }
            if (Schema::hasColumn('sociedade_membros', 'institution_id')) {
                $t->dropForeign(['institution_id']);
                $t->dropColumn('institution_id');
            }
        });

        Schema::table('people', function (Blueprint $t) {
            if (Schema::hasColumn('people', 'gender')) {
                $t->dropColumn('gender');
            }
        });

        Schema::table('sociedades_internas', function (Blueprint $t) {
            $cols = ['target_gender', 'min_age', 'max_age', 'is_active', 'notes'];
            foreach ($cols as $c) {
                if (Schema::hasColumn('sociedades_internas', $c)) {
                    $t->dropColumn($c);
                }
            }
        });
    }
};
