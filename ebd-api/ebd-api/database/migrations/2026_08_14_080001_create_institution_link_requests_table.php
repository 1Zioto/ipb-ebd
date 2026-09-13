<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('institution_link_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('requester_institution_id')->constrained('institutions')->cascadeOnDelete();
            $table->foreignId('target_institution_id')->constrained('institutions')->cascadeOnDelete();
            $table->string('type', 30); // vinculo_superior, vinculo_inferior, desvinculo
            $table->string('status', 30)->default('pendente'); // pendente, aceita, recusada, cancelada
            $table->foreignId('requested_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('actioned_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->text('reason')->nullable();
            $table->text('action_notes')->nullable();
            $table->timestamp('actioned_at')->nullable();
            $table->timestamps();

            $table->index('requester_institution_id');
            $table->index('target_institution_id');
            $table->index('status');
            $table->index('type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('institution_link_requests');
    }
};
