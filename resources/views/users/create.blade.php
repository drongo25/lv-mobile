@extends('layouts.app')

@section('content')
    <div class="max-w-lg mx-auto bg-white p-8 rounded shadow">
        <h2 class="text-xl font-bold mb-4">Новый пользователь</h2>

        <form action="{{ route('users.store') }}" method="POST">
            @csrf
            <div class="mb-4">
                <label class="block mb-1">Имя</label>
                <input type="text" name="first_name" class="w-full border p-2" required>
            </div>
            <div class="mb-4">
                <label class="block mb-1">Фамилия</label>
                <input type="text" name="last_name" class="w-full border p-2">
            </div>
            <div class="mb-4">
                <label class="block mb-1">Email</label>
                <input type="email" name="email" class="w-full border p-2" required>
            </div>
            <div class="mb-4">
                <label class="block mb-1">Роль</label>
                <select name="role_id" class="w-full border p-2">
                    @foreach($roles as $role)
                        <option value="{{ $role->id }}">{{ $role->name }}</option>
                    @endforeach
                </select>
            </div>
            <div class="mb-4">
                <label for="role_id" class="block text-gray-700 text-sm font-bold mb-2">Назначить роль</label>
                <select name="role_id" id="role_id" class="w-full border rounded-lg p-2.5 focus:ring-blue-500 focus:border-blue-500">
                    <option value="">-- Выберите роль --</option>
                    @foreach($roles as $role)
                        <option value="{{ $role->id }}"
                            {{ (isset($user) && $user->role_id == $role->id) || old('role_id') == $role->id ? 'selected' : '' }}>
                            {{ $role->name }} ({{ $role->code }})
                        </option>
                    @endforeach
                </select>
                @error('role_id') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
            <div class="mb-4">
                <label class="block mb-1">Пароль</label>
                <input type="password" name="password" class="w-full border p-2" required>
            </div>
            <div class="mb-4">
                <label class="block mb-1">Подтверждение пароля</label>
                <input type="password" name="password_confirmation" class="w-full border p-2" required>
            </div>
            <button type="submit" class="w-full bg-green-500 text-white p-2 rounded">Создать</button>
        </form>
    </div>
@endsection
