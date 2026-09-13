<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('attendance_sessions', function (Blueprint $t) {
            $t->id();
            $t->foreignId('ebd_event_id')->constrained('ebd_events')->cascadeOnDelete();
            $t->foreignId('class_id')->constrained('classes');
            $t->string('status', 20)->default('pendente');
            $t->string('status_reason', 255)->nullable();
            $t->foreignId('teacher_person_id')->nullable()->constrained('people');
            $t->string('teacher_name_snapshot', 180)->nullable();
            $t->string('class_name_snapshot', 120)->nullable();
            $t->string('material_mode', 12)->default('individual');
            $t->integer('bibles_total')->nullable();
            $t->integer('magazines_total')->nullable();
            $t->foreignId('merged_into_class_id')->nullable()->constrained('classes');
            $t->foreignId('created_by')->nullable()->constrained('users');
            $t->foreignId('finalized_by')->nullable()->constrained('users');
            $t->timestamp('finalized_at')->nullable();
            $t->foreignId('updated_by')->nullable()->constrained('users');
            $t->timestamps();
            $t->unique(['ebd_event_id', 'class_id']);
            $t->index('class_id');
        });
        if (DB::getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE attendance_sessions ADD CONSTRAINT chk_session_status CHECK (status IN ('pendente','em_andamento','finalizada','cancelada','classe_unificada','nao_realizada','evento_especial'))");
            DB::statement("ALTER TABLE attendance_sessions ADD CONSTRAINT chk_material_mode CHECK (material_mode IN ('individual','agregado'))");
            DB::statement("ALTER TABLE attendance_sessions ADD CONSTRAINT chk_bibles_nonneg CHECK (bibles_total IS NULL OR bibles_total >= 0)");
            DB::statement("ALTER TABLE attendance_sessions ADD CONSTRAINT chk_mags_nonneg CHECK (magazines_total IS NULL OR magazines_total >= 0)");
        }
    }
    public function down(): void { Schema::dropIfExists('attendance_sessions'); }
};
