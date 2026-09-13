<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('classes', function (Blueprint $t) {
            $t->id();
            $t->string('name', 120);
            $t->string('description', 255)->nullable();
            $t->string('age_range', 60)->nullable();
            $t->integer('display_order')->default(0);
            $t->boolean('is_active')->default(true);
            $t->timestamps();
            $t->softDeletes();
            $t->index('display_order');
        });
    }
    public function down(): void { Schema::dropIfExists('classes'); }
};
