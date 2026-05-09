<?php

namespace Database\Factories;

use App\Models\User;
use App\Models\Role;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\User>
 */
class UserFactory extends Factory
{
    /**
     * Имя соответствующей модели.
     *
     * @var string
     */
    protected $model = User::class;

    /**
     * Определение состояния модели по умолчанию.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $firstName = $this->faker->firstName();
        $lastName = $this->faker->lastName();

        return [
            // Системные идентификаторы
            'uuid' => (string) Str::uuid(),
            'telegram_id' => $this->faker->unique()->numberBetween(100000, 999999999),
            'phone' => $this->faker->unique()->numerify('998#########'),

            // Имена (синхронизируем name с составными частями)
            'first_name' => $firstName,
            'last_name' => $lastName,
            'name' => "{$firstName} {$lastName}",

            // Почта и статус
            'email' => $this->faker->unique()->safeEmail(),
            'email_verified_at' => now(),

            // Внешние ключи (предполагаем, что роли уже существуют или создаем новую)
            'role_id' => Role::exists() ? Role::inRandomOrder()->first()->id : 1,

            // Перечисления (Enum) из миграции
            'status' => $this->faker->randomElement(['active', 'blocked', 'dismissed']),

            // Безопасность
            'password' => Hash::make('123456789'), // Стандартный пароль для тестов 123456789
            'remember_token' => Str::random(10),

            // Даты
            'hired_at' => $this->faker->dateTimeBetween('-2 years', 'now'),
            'dismissed_at' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }

    /**
     * Состояние для заблокированных пользователей.
     */
    public function blocked(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'blocked',
        ]);
    }

    /**
     * Состояние для уволенных пользователей.
     */
    public function dismissed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'dismissed',
            'dismissed_at' => now(),
        ]);
    }
}
