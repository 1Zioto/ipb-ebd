<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        // Contas Bancárias e Caixas
        Schema::create('financial_accounts', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->nullable()->constrained('institutions')->nullOnDelete();
            $t->string('name', 120);
            $t->string('account_type', 40)->default('corrente'); // caixa, corrente, poupanca, aplicacao
            $t->string('bank_name', 80)->nullable();
            $t->string('agency', 30)->nullable();
            $t->string('account_number', 40)->nullable();
            $t->decimal('initial_balance', 12, 2)->default(0.00);
            $t->decimal('current_balance', 12, 2)->default(0.00);
            $t->boolean('is_active')->default(true);
            $t->text('notes')->nullable();
            $t->timestamps();
            $t->softDeletes();

            $t->index('institution_id');
            $t->index('account_type');
            $t->index('is_active');
        });

        // Centros de Custo (Ministérios, Departamentos, EBD, etc.)
        Schema::create('financial_cost_centers', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->nullable()->constrained('institutions')->nullOnDelete();
            $t->string('code', 30)->nullable();
            $t->string('name', 120);
            $t->string('description', 255)->nullable();
            $t->decimal('budget_limit', 12, 2)->nullable();
            $t->boolean('is_active')->default(true);
            $t->timestamps();
            $t->softDeletes();

            $t->index('institution_id');
            $t->index('is_active');
        });

        // Categorias Contábeis / Plano de Contas
        Schema::create('financial_categories', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->nullable()->constrained('institutions')->nullOnDelete();
            $t->foreignId('parent_id')->nullable()->constrained('financial_categories')->nullOnDelete();
            $t->string('code', 30)->nullable(); // Ex: 1.01, 2.01.01
            $t->string('name', 120);
            $t->string('type', 20)->default('despesa'); // receita, despesa
            $t->string('description', 255)->nullable();
            $t->boolean('is_active')->default(true);
            $t->timestamps();
            $t->softDeletes();

            $t->index('institution_id');
            $t->index('type');
            $t->index('parent_id');
            $t->index('is_active');
        });

        // Lançamentos / Movimentações Financeiras / Livro Caixa
        Schema::create('financial_transactions', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->nullable()->constrained('institutions')->nullOnDelete();
            $t->foreignId('financial_account_id')->constrained('financial_accounts');
            $t->foreignId('financial_category_id')->nullable()->constrained('financial_categories')->nullOnDelete();
            $t->foreignId('financial_cost_center_id')->nullable()->constrained('financial_cost_centers')->nullOnDelete();
            $t->string('type', 20)->default('despesa'); // receita, despesa, transferencia
            $t->date('date');
            $t->date('competency_date')->nullable();
            $t->decimal('amount', 12, 2);
            $t->string('description', 255);
            $t->string('entity_name', 180)->nullable(); // Fornecedor, Membro, Prestador, etc.
            $t->string('document_number', 80)->nullable(); // NF, Recibo, Comprovante, Pix E2E
            $t->string('payment_method', 40)->default('pix'); // pix, ted_doc, dinheiro, boleto, cartao_debito, cartao_credito, cheque, outro
            $t->string('status', 30)->default('pago'); // pago, pendente, cancelado
            $t->timestamp('paid_at')->nullable();
            $t->foreignId('coleta_id')->nullable()->constrained('coletas_dizimos')->nullOnDelete();
            $t->foreignId('destination_account_id')->nullable()->constrained('financial_accounts')->nullOnDelete();
            $t->string('attachment_url', 255)->nullable();
            $t->text('notes')->nullable();
            $t->foreignId('created_by')->constrained('users');
            $t->foreignId('updated_by')->nullable()->constrained('users');
            $t->timestamps();
            $t->softDeletes();

            $t->index('institution_id');
            $t->index('date');
            $t->index('competency_date');
            $t->index('type');
            $t->index('status');
            $t->index('coleta_id');
        });

        // Fechamentos Mensais Contábeis
        Schema::create('financial_month_closings', function (Blueprint $t) {
            $t->id();
            $t->foreignId('institution_id')->nullable()->constrained('institutions')->nullOnDelete();
            $t->integer('year');
            $t->integer('month');
            $t->string('status', 30)->default('aberto'); // aberto, em_conferencia, fechado
            $t->decimal('opening_balance', 12, 2)->default(0.00);
            $t->decimal('total_income', 12, 2)->default(0.00);
            $t->decimal('total_expense', 12, 2)->default(0.00);
            $t->decimal('closing_balance', 12, 2)->default(0.00);
            $t->foreignId('closed_by')->nullable()->constrained('users')->nullOnDelete();
            $t->timestamp('closed_at')->nullable();
            $t->text('accounting_notes')->nullable();
            $t->timestamps();

            $t->unique(['institution_id', 'year', 'month']);
            $t->index(['year', 'month']);
            $t->index('status');
        });
    }

    public function down(): void {
        Schema::dropIfExists('financial_month_closings');
        Schema::dropIfExists('financial_transactions');
        Schema::dropIfExists('financial_categories');
        Schema::dropIfExists('financial_cost_centers');
        Schema::dropIfExists('financial_accounts');
    }
};
