@extends('layouts.app')

@section('content')
    <div class="container mx-auto p-6">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-gray-800">Справочник ролей</h1>
            <a href="{{ route('roles.create') }}" class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition">
                + Создать роль
            </a>
        </div>

        @if(session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
                {{ session('success') }}
            </div>
        @endif

        <div class="bg-white shadow-md rounded-lg overflow-hidden">
            <table class="min-w-full leading-normal">
                <thead>
                <tr class="bg-gray-100 text-gray-600 uppercase text-sm">
                    <th class="py-3 px-6 text-left">Код (Slug)</th>
                    <th class="py-3 px-6 text-left">Название</th>
                    <th class="py-3 px-6 text-center">Пользователей</th>
                    <th class="py-3 px-6 text-center">Действия</th>
                </tr>
                </thead>
                <tbody class="text-gray-700">
                @foreach($roles as $role)
                    <tr class="border-b hover:bg-gray-50">
                        <td class="py-4 px-6 font-mono text-sm">{{ $role->code }}</td>
                        <td class="py-4 px-6 font-semibold">{{ $role->name }}</td>
                        <td class="py-4 px-6 text-center">
                        <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded">
                            {{ $role->users_count }}
                        </span>
                        </td>
                        <td class="py-4 px-6 text-center flex justify-center gap-3">
                            <a href="{{ route('roles.show', $role) }}" class="text-blue-500 hover:underline">Инфо</a>
                            <a href="{{ route('roles.edit', $role) }}" class="text-yellow-600 hover:underline">Редактировать</a>
                            <form action="{{ route('roles.destroy', $role) }}" method="POST" onsubmit="return confirm('Удалить роль?')">
                                @csrf @method('DELETE')
                                <button type="submit" class="text-red-500 hover:underline">Удалить</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>
    </div>
@endsection
