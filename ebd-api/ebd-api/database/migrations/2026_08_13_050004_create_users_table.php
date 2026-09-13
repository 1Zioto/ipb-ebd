<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('users', function (Blueprint $t) {
            $t->id();
            $t->foreignId('person_id')->nullable()->constrained('people')->nullOnDelete();
            $t->string('name', 180);
            $t->string('username', 80)->unique();
            $t->string('email', 180)->nullable()->unique();
            $t->string('password', 255);
            $t->boolean('is_active')->default(true);
            $t->timestamp('last_login_at')->nullable();
            $t->rememberToken();
            $t->timestamps();
            $t->softDeletes();
        });
    }
    public function down(): void { Schema::dropIfExists('users'); }
};
