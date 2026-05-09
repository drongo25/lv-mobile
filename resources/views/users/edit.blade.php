@extends('layouts.app')

@section('content')
    <div class="max-w-2xl mx-auto mt-10">
        <div class="bg-white p-8 rounded-lg shadow-lg">
            <div class="flex justify-between items-center mb-6">
                <h2 class="text-2xl font-bold text-gray-800">Редактирование: {{ $user->first_name }}</h2>
                <span class="text-sm text-gray-500 font-mono">UUID: {{ $user->uuid }}</span>
            </div>

            <form action="{{ route('users.update', $user) }}" method="POST">
                @csrf
                @method('PUT')

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div>
                        <label class="block text-gray-700 text-sm font-bold mb-2">Имя</label>
                        <input type="text" name="first_name" value="{{ old('first_name', $user->first_name) }}"
                               class="w-full border rounded-lg p-2.5 @error('first_name') border-red-500 @enderror">
                    </div>
                    <div>
                        <label class="block text-gray-700 text-sm font-bold mb-2">Фамилия</label>
                        <input type="text" name="last_name" value="{{ old('last_name', $user->last_name) }}"
                               class="w-full border rounded-lg p-2.5">
                    </div>
                </div>

                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2">Email</label>
                    <input type="email" name="email" value="{{ old('email', $user->email) }}"
                           class="w-full border rounded-lg p-2.5 @error('email') border-red-500 @enderror">
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <div>
                        <label class="block text-gray-700 text-sm font-bold mb-2">Роль</label>
                        <select name="role_id" class="w-full border rounded-lg p-2.5">
                            @foreach($roles as $role)
                                <option value="{{ $role->id }}" {{ $user->role_id == $role->id ? 'selected' : '' }}>
                                    {{ $role->name }}
                                </option>
                            @endforeach
                        </select>
                    </div>
                    <div>
                        <label class="block text-gray-700 text-sm font-bold mb-2">Статус</label>
                        <select name="status" class="w-full border rounded-lg p-2.5">
                            <option value="active" {{ $user->status == 'active' ? 'selected' : '' }}>Active</option>
                            <option value="blocked" {{ $user->status == 'blocked' ? 'selected' : '' }}>Blocked</option>
                            <option value="dismissed" {{ $user->status == 'dismissed' ? 'selected' : '' }}>Dismissed</option>
                        </select>
                    </div>
                </div>

                <div class="bg-gray-50 p-4 rounded-lg mb-6">
                    <p class="text-sm text-gray-600 mb-2 font-semibold">Смена пароля (оставьте пустым, если не меняете)</p>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <input type="password" name="password" placeholder="Новый пароль" class="border rounded-lg p-2.5">
                        <input type="password" name="password_confirmation" placeholder="Повторите пароль" class="border rounded-lg p-2.5">
                    </div>
                </div>

                <div class="flex items-center justify-between">
                    <a href="{{ route('users.index') }}" class="text-gray-600 hover:underline">Отмена</a>
                    <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded-lg font-bold hover:bg-blue-700">
                        Обновить данные
                    </button>
                </div>
            </form>
        </div>
    </div>
@endsection
