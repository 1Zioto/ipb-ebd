<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('audit_logs', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->nullable()->constrained('users');
            $t->string('action', 80);
            $t->string('entity_type', 80)->nullable();
            $t->unsignedBigInteger('entity_id')->nullable();
            $t->jsonb('old_values')->nullable();
            $t->jsonb('new_values')->nullable();
            $t->string('ip', 64)->nullable();
            $t->string('user_agent', 255)->nullable();
            $t->timestamp('created_at')->useCurrent();
            $t->index(['entity_type', 'entity_id']);
            $t->index('user_id');
            $t->index('created_at');
        });
    }
    public function down(): void { Schema::dropIfExists('audit_logs'); }
};
