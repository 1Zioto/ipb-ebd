<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Tabela de Dispositivos Conectados (Meus Dispositivos / Sessões)
        Schema::create('user_devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('token_id')->nullable();
            $table->string('device_name', 120);
            $table->string('platform', 50)->default('android'); // android, ios, web, desktop
            $table->string('client_version', 30)->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamp('last_active_at')->useCurrent();
            $table->boolean('is_revoked')->default(false);
            $table->timestamps();

            $table->index('user_id');
            $table->index('token_id');
            $table->index(['user_id', 'is_revoked']);
        });

        // 2. Tokens Seguros para Primeiro Acesso e Ativação do Membro
        Schema::create('member_activation_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('person_id')->constrained('people')->cascadeOnDelete();
            $table->foreignId('institution_id')->constrained('institutions')->cascadeOnDelete();
            $table->string('token', 64)->unique();
            $table->string('code', 10)->nullable();
            $table->timestamp('expires_at');
            $table->timestamp('used_at')->nullable();
            $table->timestamps();

            $table->index(['person_id', 'institution_id']);
            $table->index('token');
        });

        // 3. Cores e Identidade Visual Customizável por Igreja
        Schema::table('institutions', function (Blueprint $table) {
            $table->string('primary_color', 20)->default('#047857')->nullable();
            $table->string('secondary_color', 20)->default('#065F46')->nullable();
            $table->string('accent_color', 20)->default('#10B981')->nullable();
            $table->string('cover_image', 255)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('institutions', function (Blueprint $table) {
            $table->dropColumn(['primary_color', 'secondary_color', 'accent_color', 'cover_image']);
        });

        Schema::dropIfExists('member_activation_tokens');
        Schema::dropIfExists('user_devices');
    }
};

