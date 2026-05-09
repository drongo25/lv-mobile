<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'ERP System') }}</title>

<!-- Fonts -->
<link rel="preconnect" href="https://fonts.bunny.net">
<link href="https://fonts.bunny.net/css?family=inter:400,500,600&display=swap" rel="stylesheet" />

<!-- Scripts & Styles (Vite) -->
@vite(['resources/css/app.css', 'resources/js/app.js'])

<!-- CDN fallback (если Vite не настроен) -->
<script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="font-sans antialiased bg-gray-100 text-gray-900">
<div class="min-h-screen">

    <!-- Navigation -->
    <nav class="bg-white border-b border-gray-100 shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between h-16">
                <div class="flex">
                    <!-- Logo -->
                    <div class="shrink-0 flex items-center">
                        <a href="/" class="font-bold text-xl text-indigo-600">
                            CRM_SYSTEM
                        </a>
                    </div>

                    <!-- Navigation Links -->
                    <div class="hidden space-x-8 sm:-my-px sm:ml-10 sm:flex">
                        <a href="{{ route('users.index') }}"
                           class="inline-flex items-center px-1 pt-1 border-b-2 {{ request()->routeIs('users.*') ? 'border-indigo-500 text-gray-900' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300' }} text-sm font-medium leading-5 transition duration-150 ease-in-out">
                            Пользователи
                        </a>
                        <a href="{{ route('roles.index') }}"
                           class="inline-flex items-center px-1 pt-1 border-b-2 {{ request()->routeIs('roles.*') ? 'border-indigo-500 text-gray-900' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300' }} text-sm font-medium leading-5 transition duration-150 ease-in-out">
                            Роли
                        </a>
                    </div>
                </div>

                <!-- User Dropdown (Simplified) -->
                <div class="hidden sm:flex sm:items-center sm:ml-6">
                    <div class="text-sm font-medium text-gray-500">
                        {{ Auth::user()->name ?? 'Guest' }}
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <!-- Page Heading -->
    @if (isset($header))
        <header class="bg-white shadow">
            <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
                {{ $header }}
            </div>
        </header>
    @endif

    <!-- Page Content -->
    <main class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">

            <!-- Flash Messages (Уведомления) -->
            @if(session('success'))
                <div class="mb-6 p-4 bg-green-100 border-l-4 border-green-500 text-green-700 shadow-sm rounded-r" role="alert">
                    <p class="font-bold">Успех!</p>
                    <p>{{ session('success') }}</p>
                </div>
            @endif

            @if(session('error'))
                <div class="mb-6 p-4 bg-red-100 border-l-4 border-red-500 text-red-700 shadow-sm rounded-r" role="alert">
                    <p class="font-bold">Ошибка!</p>
                    <p>{{ session('error') }}</p>
                </div>
            @endif

            @if ($errors->any())
                <div class="mb-6 p-4 bg-orange-100 border-l-4 border-orange-500 text-orange-700 shadow-sm rounded-r">
                    <ul class="list-disc list-inside">
                        @foreach ($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <!-- Основной контент страницы -->
            @yield('content')

        </div>
    </main>
</div>
</body>
</html>
