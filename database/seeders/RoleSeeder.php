<?php


namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        $roles = [
            [
                'code' => 'admin',
                'name' => 'Administrator',
                'description' => 'Полный доступ ко всем функциям системы.',
            ],
            [
                'code' => 'manager',
                'name' => 'Manager',
                'description' => 'Управление задачами и оборудованием.',
            ],
            [
                'code' => 'dispatcher',
                'name' => 'Dispatcher',
                'description' => 'Распределение заявок и мониторинг.',
            ],
            [
                'code' => 'operator',
                'name' => 'Operator',
                'description' => 'Полевой сотрудник, выполнение работ и заправок.',
            ],
        ];

        foreach ($roles as $role) {
            Role::updateOrCreate(['code' => $role['code']], $role);
        }
    }
}
