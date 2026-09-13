<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('attendance_records', function (Blueprint $t) {
            $t->id();
            $t->foreignId('attendance_session_id')->constrained('attendance_sessions')->cascadeOnDelete();
            $t->foreignId('person_id')->constrained('people');
            $t->string('person_name_snapshot', 180);
            $t->boolean('present')->default(false);
            $t->boolean('brought_bible')->nullable();
            $t->boolean('brought_magazine')->nullable();
            $t->timestamps();
            $t->unique(['attendance_session_id', 'person_id']);
            $t->index('person_id');
        });
    }
    public function down(): void { Schema::dropIfExists('attendance_records'); }
};
