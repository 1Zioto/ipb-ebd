<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // 1. Processos Disciplinares & Jurisdição Pastoral (Código de Disciplina da IPB)
        Schema::create('processos_disciplinares', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $t->string('numero_processo', 50); // ex: PROC-2026/001
            $t->string('tipo_falta', 60)->default('Abandono de Comunhão'); // Doutrinária, Moral, Abandono de Comunhão, Conduta, Desobediência
            $t->text('descricao_falta');
            $t->string('medida_disciplinar', 60)->default('Em Instrução'); // Em Instrução, Sob Admoestação, Sob Censura, Suspensão dos Sacramentos, Exclusão do Rol, Absolvido, Restaurado
            $t->date('data_abertura');
            $t->date('data_julgamento')->nullable();
            $t->date('data_restauracao')->nullable();
            $t->integer('prazo_meses')->nullable();
            $t->string('relator_presbitero', 120)->nullable();
            $t->foreignId('ata_conselho_id')->nullable()->constrained('atas_conselho')->nullOnDelete();
            $t->string('status', 40)->default('Em Aberto'); // Em Aberto, Julgado, Cumprindo Disciplina, Restaurado, Arquivado
            $t->text('observacoes_pastorais')->nullable();
            $t->timestamps();

            $t->index('institution_id');
            $t->index('person_id');
            $t->index('status');
        });

        // 2. Livro Tombo & Inventário de Bens (Junta Diaconal)
        Schema::create('patrimonio_bens', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->string('numero_tombamento', 50); // ex: TOMBO-001
            $t->string('nome', 150);
            $t->string('categoria', 60); // Som & Áudio, Projeção & Multimídia, Instrumentos Musicais, Mobiliário, Climatização, Eletrodomésticos, Veículos, Imóvel, Outros
            $t->string('localizacao', 120); // Templo Principal, Salas da EBD, Salão Social, Gabinete Pastoral, Cozinha, Pátio/Estacionamento
            $t->date('data_aquisicao')->nullable();
            $t->decimal('valor_aquisicao', 12, 2)->nullable();
            $t->decimal('valor_atual', 12, 2)->nullable();
            $t->string('estado_conservacao', 40)->default('Bom'); // Excelente, Bom, Regular, Danificado
            $t->string('status', 30)->default('Ativo'); // Ativo, Em Manutenção, Baixado/Descartado, Cedido/Emprestado
            $t->string('nota_fiscal', 100)->nullable();
            $t->text('descricao')->nullable();
            $t->string('responsavel_diacono', 120)->nullable();
            $t->timestamps();

            $t->index('institution_id');
            $t->index('categoria');
            $t->index('status');
        });

        // 3. Ordens de Serviço & Zeladoria (Junta Diaconal)
        Schema::create('ordens_servico_diaconia', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->string('numero_os', 50); // ex: OS-2026/001
            $t->string('titulo', 150);
            $t->text('descricao');
            $t->string('tipo_servico', 60); // Elétrica, Hidráulica, Pintura, Som/Multimídia, Climatização, Limpeza/Zeladoria, Marcenaria/Móveis, Outro
            $t->string('localizacao', 120);
            $t->string('prioridade', 30)->default('Média'); // Baixa, Média, Alta, Urgente
            $t->string('status', 30)->default('Pendente'); // Pendente, Em Andamento, Concluída, Cancelada
            $t->string('solicitante', 120);
            $t->string('diacono_responsavel', 120)->nullable();
            $t->date('data_solicitacao');
            $t->date('data_previsao')->nullable();
            $t->date('data_conclusao')->nullable();
            $t->decimal('custo_estimado', 10, 2)->default(0.00);
            $t->decimal('custo_real', 10, 2)->default(0.00);
            $t->text('observacoes')->nullable();
            $t->timestamps();

            $t->index('institution_id');
            $t->index('status');
            $t->index('prioridade');
        });

        // 4. Escala de Diáconos do Culto (Junta Diaconal)
        Schema::create('escalas_diaconos', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->date('data_culto');
            $t->string('periodo', 40)->default('Noite'); // Manhã / EBD, Tarde, Noite, Reunião de Oração, Culto Especial
            $t->string('recepcao_porta', 255)->nullable();
            $t->string('recolhimento_ofertas', 255)->nullable();
            $t->string('apoio_pulpito_ceia', 255)->nullable();
            $t->string('seguranca_patio', 255)->nullable();
            $t->string('diacono_coordenador', 120)->nullable();
            $t->text('observacoes')->nullable();
            $t->timestamps();

            $t->index('institution_id');
            $t->index('data_culto');
        });

        // 5. Cotas Conciliares (Presbitério e Supremo Concílio)
        Schema::create('cotas_conciliares', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->integer('ano');
            $t->integer('mes');
            $t->decimal('base_calculo', 12, 2)->default(0.00);
            $t->decimal('aliquota_presbiterio_pct', 5, 2)->default(5.00);
            $t->decimal('aliquota_supremo_concilio_pct', 5, 2)->default(5.00);
            $t->decimal('valor_presbiterio', 12, 2)->default(0.00);
            $t->decimal('valor_supremo_concilio', 12, 2)->default(0.00);
            $t->string('status_presbiterio', 30)->default('Pendente'); // Pendente, Pago
            $t->string('status_supremo_concilio', 30)->default('Pendente'); // Pendente, Pago
            $t->date('data_pagamento_presbiterio')->nullable();
            $t->date('data_pagamento_sc')->nullable();
            $t->string('comprovante_presbiterio', 255)->nullable();
            $t->string('comprovante_sc', 255)->nullable();
            $t->text('observacoes')->nullable();
            $t->timestamps();

            $t->index('institution_id');
            $t->index(['ano', 'mes']);
        });

        // 6. Linhas do Orçamento Anual Programa (Orçado vs Realizado)
        Schema::create('orcamento_anual_linhas', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->integer('ano');
            $t->string('departamento_ou_sociedade', 100); // EBD, SAF, UPH, UMP, UPA, UCP, Junta Diaconal, Pastoral, Missões, Manutenção e Templo, Música
            $t->foreignId('financial_category_id')->nullable()->constrained('financial_categories')->nullOnDelete();
            $t->foreignId('financial_cost_center_id')->nullable()->constrained('financial_cost_centers')->nullOnDelete();
            $t->string('descricao', 200);
            $t->decimal('valor_previsto_anual', 12, 2)->default(0.00);
            $t->text('observacoes')->nullable();
            $t->timestamps();

            $t->index('institution_id');
            $t->index(['ano', 'departamento_ou_sociedade']);
        });

        // 7. Pareceres da Comissão de Exame de Contas
        Schema::create('pareceres_exame_contas', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $t->string('numero_parecer', 50); // ex: PAR-2026/001
            $t->integer('ano_exercicio');
            $t->string('periodo', 60)->default('1º Trimestre'); // 1º Trimestre, 2º Trimestre, 3º Trimestre, 4º Trimestre, Exercício Anual
            $t->date('data_emissao');
            $t->string('relator', 120);
            $t->json('membros_comissao')->nullable();
            $t->string('resultado', 50)->default('Favorável sem ressalvas'); // Favorável sem ressalvas, Favorável com ressalvas, Desfavorável
            $t->decimal('total_receitas_auditado', 12, 2)->default(0.00);
            $t->decimal('total_despesas_auditado', 12, 2)->default(0.00);
            $t->decimal('saldo_apurado', 12, 2)->default(0.00);
            $t->boolean('conformidade_livro_caixa')->default(true);
            $t->boolean('conformidade_extratos_bancarios')->default(true);
            $t->boolean('conformidade_comprovantes_fiscais')->default(true);
            $t->boolean('conformidade_cotas_conciliares')->default(true);
            $t->text('ressalvas_e_recomendacoes')->nullable();
            $t->text('texto_conclusao');
            $t->string('status', 40)->default('Concluído'); // Rascunho, Concluído, Apresentado em Assembleia
            $t->timestamps();

            $t->index('institution_id');
            $t->index('ano_exercicio');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pareceres_exame_contas');
        Schema::dropIfExists('orcamento_anual_linhas');
        Schema::dropIfExists('cotas_conciliares');
        Schema::dropIfExists('escalas_diaconos');
        Schema::dropIfExists('ordens_servico_diaconia');
        Schema::dropIfExists('patrimonio_bens');
        Schema::dropIfExists('processos_disciplinares');
    }
};
