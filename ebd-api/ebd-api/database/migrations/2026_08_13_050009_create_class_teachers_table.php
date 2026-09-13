<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('class_teachers', function (Blueprint $t) {
            $t->id();
            $t->foreignId('class_id')->constrained('classes');
            $t->foreignId('person_id')->constrained('people');
            $t->boolean('is_active')->default(true);
            $t->timestamps();
            $t->unique(['class_id', 'person_id']);
        });
    }
    public function down(): void { Schema::dropIfExists('class_teachers'); }
};
