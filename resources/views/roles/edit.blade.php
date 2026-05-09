@extends('layouts.app')

@section('content')
    <div class="max-w-2xl mx-auto mt-10">
        <div class="bg-white p-8 rounded-lg shadow-lg">
            <h2 class="text-2xl font-bold mb-6 text-gray-800">Редактирование роли</h2>

            <form action="{{ route('roles.update', $role) }}" method="POST">
                @csrf
                @method('PUT')

                <div class="mb-4">
                    <label for="code">Код роли</label>
                    <select name="code" id="code" class="w-full border rounded-lg p-2.5">
                        @foreach($availableCodes as $code)
                            <option value="{{ $code }}"
                                {{ (isset($role) && $role->code == $code) || old('code') == $code ? 'selected' : '' }}>
                                {{ ucfirst($code) }}
                            </option>
                        @endforeach
                    </select>
                    @error('code')
                    <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                    @enderror
                    <p class="text-xs text-gray-400 mt-1">Код роли обычно не меняется, так как завязан на логике кода.</p>
                </div>

                <div class="mb-4">
                    <label class="block text-gray-700 text-sm font-bold mb-2">Название роли</label>
                    <input type="text" name="name" value="{{ old('name', $role->name) }}"
                           class="w-full border rounded-lg p-2.5 @error('name') border-red-500 @enderror">
                </div>

                <div class="mb-6">
                    <label class="block text-gray-700 text-sm font-bold mb-2">Описание</label>
                    <textarea name="description" rows="4" class="w-full border rounded-lg p-2.5">{{ old('description', $role->description) }}</textarea>
                </div>

                <div class="flex items-center justify-between">
                    <a href="{{ route('roles.index') }}" class="text-gray-600 hover:underline">Назад к списку</a>
                    <button type="submit" class="bg-indigo-600 text-white px-6 py-2 rounded-lg font-bold hover:bg-indigo-700">
                        Сохранить изменения
                    </button>
                </div>
            </form>
        </div>
    </div>
@endsection
