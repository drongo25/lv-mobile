<?php

namespace App\Http\Controllers;

use App\Models\Role;
use Illuminate\Http\Request;

class RoleController extends Controller
{
    /**
     * Список доступных кодов ролей.
     * Вынесено в отдельный массив для удобства поддержки.
     */
    private array $availableCodes = ['admin', 'operator', 'manager', 'dispatcher', 'viewer'];

    public function index()
    {
        $roles = Role::withCount('users')->get();
        return view('roles.index', compact('roles'));
    }

    public function create()
    {
        // В методе create нам не нужен список всех ролей,
        // только массив доступных кодов для выпадающего списка.
        $availableCodes = $this->availableCodes;
        return view('roles.create', compact('availableCodes'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            // В store у нас еще нет объекта $role->id, поэтому валидация уникальности проще
            'code' => 'required|in:' . implode(',', $this->availableCodes) . '|unique:roles,code',
            'name' => 'required|string|max:100',
            'description' => 'nullable|string',
        ]);

        Role::create($validated);

        return redirect()->route('roles.index')->with('success', 'Роль успешно создана.');
    }

    public function show(Role $role)
    {
        $role->load('users');
        return view('roles.show', compact('role'));
    }

    public function edit(Role $role)
    {
        $availableCodes = $this->availableCodes;
        return view('roles.edit', compact('role', 'availableCodes'));
    }

    public function update(Request $request, Role $role)
    {
        $validated = $request->validate([
            // Здесь используем $role->id, чтобы валидатор игнорировал текущую запись при проверке уникальности
            'code' => 'required|in:' . implode(',', $this->availableCodes) . '|unique:roles,code,' . $role->id,
            'name' => 'required|string|max:100',
            'description' => 'nullable|string',
        ]);

        $role->update($validated);

        return redirect()->route('roles.index')->with('success', 'Данные роли обновлены.');
    }

    public function destroy(Role $role)
    {
        if ($role->users()->count() > 0) {
            return redirect()->back()->with('error', 'Нельзя удалить роль, к которой привязаны пользователи.');
        }

        $role->delete();
        return redirect()->route('roles.index')->with('success', 'Роль удалена.');
    }
}
