<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('people', function (Blueprint $t) {
            $t->id();
            $t->string('full_name', 180);
            $t->date('birth_date')->nullable();
            $t->boolean('is_active')->default(true);
            $t->boolean('can_teach')->default(false);
            $t->boolean('can_superintend')->default(false);
            $t->text('notes')->nullable();
            $t->timestamps();
            $t->softDeletes();
            $t->index('is_active');
            $t->index('can_teach');
        });
    }
    public function down(): void { Schema::dropIfExists('people'); }
};
