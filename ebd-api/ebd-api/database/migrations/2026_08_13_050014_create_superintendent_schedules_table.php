<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('superintendent_schedules', function (Blueprint $t) {
            $t->id();
            $t->foreignId('ebd_event_id')->unique()->constrained('ebd_events')->cascadeOnDelete();
            $t->foreignId('scheduled_person_id')->constrained('people');
            $t->string('notes', 255)->nullable();
            $t->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('superintendent_schedules'); }
};
