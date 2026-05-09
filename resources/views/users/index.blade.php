@extends('layouts.app')

@section('content')
    <div class="container mx-auto p-6">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold">Пользователи</h1>
            <a href="{{ route('users.create') }}" class="bg-blue-500 text-white px-4 py-2 rounded">Добавить</a>
        </div>

        <table class="min-w-full bg-white border">
            <thead>
            <tr>
                <th class="py-2 px-4 border-b">Имя</th>
                <th class="py-2 px-4 border-b">Email</th>
                <th class="py-2 px-4 border-b">Роль</th>
                <th class="py-2 px-4 border-b">Статус</th>
                <th class="py-2 px-4 border-b">Действия</th>
            </tr>
            </thead>
            <tbody>
            @foreach($users as $user)
                <tr>
                    <td class="py-2 px-4 border-b">{{ $user->name }}</td>
                    <td class="py-2 px-4 border-b">{{ $user->email }}</td>
                    <td class="py-2 px-4 border-b">{{ $user->role->name }}</td>
                    <td class="py-2 px-4 border-b">
                    <span class="px-2 py-1 rounded text-xs {{ $user->status === 'active' ? 'bg-green-200' : 'bg-red-200' }}">
                        {{ $user->status }}
                    </span>
                    </td>
                    <td class="py-2 px-4 border-b flex gap-2">
                        <a href="{{ route('users.edit', $user) }}" class="text-yellow-600">Edit</a>
                        <form action="{{ route('users.destroy', $user) }}" method="POST" onsubmit="return confirm('Удалить?')">
                            @csrf @method('DELETE')
                            <button type="submit" class="text-red-600">Delete</button>
                        </form>
                    </td>
                </tr>
            @endforeach
            </tbody>
        </table>
        {{ $users->links() }}
    </div>
@endsection
