<?php


namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class RoleFactory extends Factory
{
    public function definition(): array
    {
        return [
            'code' => $this->faker->unique()->slug(1),
            'name' => $this->faker->jobTitle(),
            'description' => $this->faker->sentence(),
        ];
    }
}
