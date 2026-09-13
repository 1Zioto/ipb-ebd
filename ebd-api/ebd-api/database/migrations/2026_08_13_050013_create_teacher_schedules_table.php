<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('teacher_schedules', function (Blueprint $t) {
            $t->id();
            $t->foreignId('ebd_event_id')->constrained('ebd_events')->cascadeOnDelete();
            $t->foreignId('class_id')->constrained('classes');
            $t->foreignId('scheduled_person_id')->constrained('people');
            $t->string('notes', 255)->nullable();
            $t->timestamps();
            $t->unique(['ebd_event_id', 'class_id']);
        });
    }
    public function down(): void { Schema::dropIfExists('teacher_schedules'); }
};
