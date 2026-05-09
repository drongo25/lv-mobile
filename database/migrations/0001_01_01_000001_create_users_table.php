<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Таблица Пользователей
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('uuid', 36)->unique();
            $table->bigInteger('telegram_id')->unsigned()->nullable()->unique();
            $table->string('phone', 30)->nullable()->unique();

            // Laravel стандарт + ваши поля
            $table->string('name'); // Общее имя
            $table->string('first_name', 100);
            $table->string('last_name', 100)->nullable();
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();

            $table->foreignId('role_id')->constrained('roles');
            $table->enum('status', ['active', 'blocked', 'dismissed'])->default('active');

            $table->string('password'); // Вместо password_hash для совместимости с Auth
            $table->rememberToken();

            $table->timestamp('hired_at')->nullable();
            $table->timestamp('dismissed_at')->nullable();

            $table->timestamps(); // Создает created_at и updated_at
            $table->softDeletes(); // Создает deleted_at
        });

        // 2. Токены сброса пароля
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        // 3. Сессии
        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');
    }
};
