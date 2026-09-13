<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('ebd_events', function (Blueprint $t) {
            $t->id();
            $t->date('event_date');
            $t->string('type', 20)->default('regular');
            $t->string('status', 20)->default('pendente');
            $t->boolean('is_auto_generated')->default(false);
            $t->foreignId('superintendent_person_id')->nullable()->constrained('people');
            $t->string('superintendent_name_snapshot', 180)->nullable();
            $t->text('notes')->nullable();
            $t->foreignId('created_by')->nullable()->constrained('users');
            $t->timestamps();
            $t->unique(['event_date', 'type']);
            $t->index('event_date');
        });
        if (DB::getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE ebd_events ADD CONSTRAINT chk_event_type CHECK (type IN ('regular','especial','evento','outro'))");
            DB::statement("ALTER TABLE ebd_events ADD CONSTRAINT chk_event_status CHECK (status IN ('pendente','em_andamento','finalizada','cancelada'))");
        }
    }
    public function down(): void { Schema::dropIfExists('ebd_events'); }
};
