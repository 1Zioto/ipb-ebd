<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('announcements', function (Blueprint $t) {
            $t->id();
            $t->string('title', 180);
            $t->text('body')->nullable();
            $t->date('starts_at')->nullable();
            $t->date('ends_at')->nullable();
            $t->boolean('is_active')->default(true);
            $t->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('announcements'); }
};
