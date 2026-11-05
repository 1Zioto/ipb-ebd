<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('church_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('institution_id')->default(5)->constrained('institutions')->cascadeOnDelete();
            $table->foreignId('created_by_user_id')->nullable()->constrained('users')->nullOnDelete();

            $table->string('title', 150);
            $table->string('slug', 160)->unique();
            $table->string('theme', 200)->nullable();
            $table->text('description')->nullable();

            $table->string('event_type', 60)->default('Retiro / Acampamento');
            $table->string('target_audience', 60)->default('Geral');

            // Local & Ponto de Saída
            $table->string('location_name', 150)->nullable();
            $table->string('location_address', 250)->nullable();
            $table->text('location_maps_url')->nullable();
            $table->string('departure_meeting_point', 150)->nullable();
            $table->string('departure_time', 50)->nullable();

            // Datas e Horários
            $table->dateTime('starts_at');
            $table->dateTime('ends_at')->nullable();
            $table->dateTime('registration_starts_at')->nullable();
            $table->dateTime('registration_ends_at')->nullable();

            // Capacidade & Vagas
            $table->integer('max_capacity')->nullable();

            // Valores & Pix
            $table->boolean('is_paid')->default(false);
            $table->decimal('price', 10, 2)->default(0.00);
            $table->string('pix_key', 150)->nullable();
            $table->string('pix_key_type', 40)->nullable(); // CNPJ, Celular, E-mail, Chave Aleatória
            $table->string('pix_receiver_name', 150)->nullable();

            // Orientações & Contato
            $table->text('instructions')->nullable(); // O que levar, regras do local, etc.
            $table->string('contact_phone', 40)->nullable();
            $table->string('contact_email', 100)->nullable();

            // Configurações e Status
            $table->boolean('require_medical_info')->default(true);
            $table->boolean('allow_non_members')->default(true);
            $table->string('status', 30)->default('published'); // draft, published, closed, cancelled

            $table->timestamps();

            $table->index('institution_id');
            $table->index('slug');
            $table->index('starts_at');
            $table->index('status');
        });

        Schema::create('church_event_registrations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('church_event_id')->constrained('church_events')->cascadeOnDelete();
            $table->foreignId('person_id')->nullable()->constrained('people')->nullOnDelete();

            $table->string('registration_code', 30)->unique();
            $table->string('full_name', 150);
            $table->string('phone', 30);
            $table->string('email', 100)->nullable();
            $table->string('cpf', 20)->nullable();
            $table->date('birth_date')->nullable();
            $table->string('gender', 20)->nullable();

            // Vínculo
            $table->boolean('is_member')->default(true);
            $table->string('church_name', 150)->nullable();

            // Menores de idade
            $table->boolean('is_minor')->default(false);
            $table->string('guardian_name', 150)->nullable();
            $table->string('guardian_phone', 30)->nullable();

            // Saúde & Ficha Médica
            $table->string('dietary_restrictions', 255)->nullable();
            $table->text('medical_notes')->nullable();
            $table->string('emergency_contact_name', 150)->nullable();
            $table->string('emergency_contact_phone', 30)->nullable();

            // Pagamento
            $table->string('payment_status', 30)->default('free'); // free, pending, confirmed, rejected
            $table->decimal('payment_amount', 10, 2)->default(0.00);
            $table->string('payment_proof_path', 500)->nullable();
            $table->text('payment_notes')->nullable();

            // Presença / Check-in
            $table->boolean('checked_in')->default(false);
            $table->dateTime('checked_in_at')->nullable();

            $table->string('status', 30)->default('confirmed'); // confirmed, cancelled, waitlist
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index('church_event_id');
            $table->index('registration_code');
            $table->index('payment_status');
            $table->index('status');
            $table->index('checked_in');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('church_event_registrations');
        Schema::dropIfExists('church_events');
    }
};

