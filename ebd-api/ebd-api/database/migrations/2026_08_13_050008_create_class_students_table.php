<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('class_students', function (Blueprint $t) {
            $t->id();
            $t->foreignId('class_id')->constrained('classes');
            $t->foreignId('person_id')->constrained('people');
            $t->date('enrolled_at')->default(now());
            $t->date('unenrolled_at')->nullable();
            $t->boolean('is_active')->default(true);
            $t->timestamps();
            $t->index('class_id');
            $t->index('person_id');
        });
        // no máximo uma matrícula ATIVA por pessoa+classe (preserva histórico)
        DB::statement('CREATE UNIQUE INDEX uq_class_student_active ON class_students (class_id, person_id) WHERE is_active');
    }
    public function down(): void { Schema::dropIfExists('class_students'); }
};
