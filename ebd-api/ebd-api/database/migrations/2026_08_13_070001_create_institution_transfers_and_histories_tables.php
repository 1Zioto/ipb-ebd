<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('institution_transfers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('institution_id')->constrained('institutions')->cascadeOnDelete();
            $table->foreignId('old_parent_id')->nullable()->constrained('institutions')->nullOnDelete();
            $table->foreignId('new_parent_id')->nullable()->constrained('institutions')->nullOnDelete();
            $table->foreignId('transferred_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->text('reason')->nullable();
            $table->timestamp('transferred_at')->useCurrent();
            $table->timestamps();

            $table->index('institution_id');
        });

        Schema::create('institution_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('institution_id')->constrained('institutions')->cascadeOnDelete();
            $table->string('event_type', 80); // criacao, organizacao, mudanca_nome, mudanca_cnpj, mudanca_endereco, mudanca_superior, inativacao, etc.
            $table->string('title', 200);
            $table->text('description')->nullable();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->json('payload')->nullable();
            $table->timestamps();

            $table->index('institution_id');
            $table->index('event_type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('institution_histories');
        Schema::dropIfExists('institution_transfers');
    }
};
