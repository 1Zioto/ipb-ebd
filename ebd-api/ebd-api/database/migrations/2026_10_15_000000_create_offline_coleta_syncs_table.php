<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('offline_coleta_syncs', function (Blueprint $table) {
            $table->id();
            $table->uuid('client_operation_id')->unique();
            // Keep audit evidence intact: neither the institution nor the
            // submitter may be hard-deleted while an offline lot exists.
            $table->foreignId('institution_id')->constrained('institutions')->restrictOnDelete();
            $table->foreignId('submitted_by')->constrained('users')->restrictOnDelete();
            $table->string('device_id', 128);
            $table->timestampTz('captured_at');
            $table->json('payload');
            $table->char('payload_hash', 64);
            $table->string('status', 32)->default('pending_review');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('reviewed_at')->nullable();
            $table->text('review_notes')->nullable();
            $table->foreignId('coleta_id')->nullable()->constrained('coletas_dizimos')->nullOnDelete();
            $table->timestampsTz();

            $table->index(['institution_id', 'status']);
            $table->index(['submitted_by', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('offline_coleta_syncs');
    }
};
