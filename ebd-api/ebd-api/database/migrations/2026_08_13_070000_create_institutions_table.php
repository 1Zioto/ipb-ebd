<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('institutions', function (Blueprint $table) {
            $table->id();
            
            // Identificação
            $table->string('name', 200);
            $table->string('short_name', 100);
            $table->string('type', 50)->default('igreja'); // supremo_concilio, sinodo, presbiterio, igreja, congregacao, outro
            $table->string('cnpj', 20)->nullable();
            $table->date('foundation_date')->nullable();
            $table->date('organization_date')->nullable();
            $table->string('status', 30)->default('ativa'); // ativa, inativa, em_organizacao, congregacao, outro

            // Vínculo hierárquico
            $table->foreignId('parent_institution_id')
                ->nullable()
                ->constrained('institutions')
                ->nullOnDelete();

            // Endereço e Contato
            $table->string('zipcode', 20)->nullable();
            $table->string('street', 200)->nullable();
            $table->string('number', 20)->nullable();
            $table->string('complement', 100)->nullable();
            $table->string('district', 100)->nullable();
            $table->string('city', 100)->nullable();
            $table->string('state', 50)->nullable();
            $table->string('country', 50)->default('Brasil');
            $table->string('phone', 30)->nullable();
            $table->string('whatsapp', 30)->nullable();
            $table->string('email', 180)->nullable();
            $table->string('website', 255)->nullable();
            $table->json('social_media')->nullable();

            // Identidade Institucional
            $table->string('logo', 255)->nullable();
            $table->string('photo', 255)->nullable();
            $table->string('fantasy_name', 200)->nullable();
            $table->string('internal_code', 50)->nullable();
            $table->string('denominational_code', 50)->nullable();
            $table->text('notes')->nullable();

            $table->timestamps();
            $table->softDeletes();

            // Índices para otimização de busca e travessia da árvore
            $table->index('parent_institution_id');
            $table->index('type');
            $table->index('cnpj');
            $table->index('status');
            $table->index('city');
            $table->index('state');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('institutions');
    }
};
