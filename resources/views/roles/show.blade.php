@extends('layouts.app')

@section('content')
    <div class="container mx-auto p-6">
        <div class="bg-white rounded-lg shadow-md p-6 mb-6">
            <h1 class="text-3xl font-bold text-gray-800 mb-2">{{ $role->name }}</h1>
            <p class="text-gray-500 font-mono mb-4 text-sm uppercase">Технический код: {{ $role->code }}</p>
            <p class="text-gray-700 bg-gray-50 p-4 border-l-4 border-indigo-500 italic">
                {{ $role->description ?? 'Описание отсутствует' }}
            </p>
        </div>

        <h2 class="text-xl font-bold mb-4">Пользователи с этой ролью ({{ $role->users->count() }})</h2>

        <div class="bg-white shadow rounded-lg overflow-hidden">
            <table class="min-w-full">
                <thead class="bg-gray-100">
                <tr>
                    <th class="py-3 px-6 text-left text-xs font-medium text-gray-500 uppercase">ФИО</th>
                    <th class="py-3 px-6 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
                    <th class="py-3 px-6 text-center text-xs font-medium text-gray-500 uppercase">Статус</th>
                </tr>
                </thead>
                <tbody>
                @forelse($role->users as $user)
                    <tr class="border-b">
                        <td class="py-3 px-6"><a href="{{ route('users.show', $user) }}" class="text-blue-600 hover:underline">{{ $user->name }}</a></td>
                        <td class="py-3 px-6 text-gray-600">{{ $user->email }}</td>
                        <td class="py-3 px-6 text-center">
                        <span class="px-2 py-1 text-xs rounded-full {{ $user->status == 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800' }}">
                            {{ $user->status }}
                        </span>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="3" class="py-6 text-center text-gray-500">Нет пользователей с данной ролью.</td>
                    </tr>
                @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection
