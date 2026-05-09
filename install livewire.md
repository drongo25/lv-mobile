# Install Livewire

## Установка LARAVEL

- OpenServer выбарть версию PHP и войти в консоль

  ```bash
    D:\OSP>cd home
    D:\OSP\home>composer create-project laravel/laravel <project-name>
    D:\OSP\home>composer create-project laravel/laravel lv-mobile.loc
    D:\OSP\home>composer create-project laravel/laravel .
  ```

## Настрока сайта в Openserver

- создать папку .osp в корне проекта
- создать файл project.ini

```ini
    [lv-mobile.loc]

    base_url     = https://{host_decoded}
    http_engine  = Apache
    php_engine   = PHP-8.5
    project_root = {base_dir}
    web_root     = {base_dir}\public
```

- restart Openserver
- настрока .ENV подключаем БД

```env
    DB_CONNECTION=mysql
    DB_HOST=127.0.0.1
    DB_PORT=3307
    DB_DATABASE=lv_mobile
    DB_USERNAME=root
    DB_PASSWORD=root
```

- запуск миграций

```bash
    D:\OSP>php artisan migrate
```

## Установка Laravel IDE Helper Generator

```bash
    composer require --dev barryvdh/laravel-ide-helper
```

## Установка debugbar

```bash
    composer require --dev barryvdh/laravel-debugbar
```

## Установка dbal
composer require --dev doctrine/dbal
```bash
    composer require --dev doctrine/dbal
```

## Установка laravel/breeze

```bash
    composer require laravel/breeze --dev
```

```bash
    php artisan breeze:install
    npm install
    npm run dev
    php artisan migrate
```

```bash
    php artisan breeze:install vue
    npm install
    npm run dev
    php artisan migrate
```


## Установка Livewire

```bash
    composer require livewire/livewire
```

```bash
    npm install && npm run build
    composer run dev
```




# Публикация файла конфигурации

- Livewire имеет "нулевую конфигурацию", что означает, что вы можете использовать его,
- следуя соглашениям, без какой-либо дополнительной настройки.
- Однако, при необходимости, вы можете опубликовать и настроить файл конфигурации Livewire:

```bash
    php artisan livewire:config
```

- В результате будет создан новый livewire.php файл в каталоге конфигурации вашего приложения Laravel,
- в котором вы можете настроить различные параметры Livewire.

## Создаем livewire component

```bash
    php artisan make:livewire counter-component
```

- livewire counter-component

```php
## \lv-mobile.loc\resources\views\components\⚡counter-component.blade.php
    use Livewire\Component;

    new class extends Component
    {
        public $count = 0;

        public function decrement(){
            $this->count--;
        }
            public function increment(){
            $this->count++;
        }
    };
    ?>

    <div>
    <h1>Hello world !!!</h1>
    <div><button class="btn btn-primary" wire:click="decrement()">-</button></div>
    <div>Count:{{ $count }}</div>
    <div><button class="btn btn-success" wire:click="increment()">+</button></div>
    </div>
```

- welcome.blade

```php
## \lv-mobile.loc\resources\views\welcome.blade.php

    <livewire:counter-component />
    @livewire('counter-component')
    {{-- @livewire('counter-component') --}}
```

# Создаем компонет

```bash
   php artisan make:livewire post.create
```

# Создаем компонет

```bash
   php artisan make:livewire test.hello
```

# Создаем компонет --sfc // (single file component)

```bash
   php artisan make:livewire test.hello --sfc
```

# Создаем компонет --mfc // (multy file component)

```bash
   php artisan make:livewire test.hello --mfc
```

- in folder resources/views/components/post/⚡create/

```bash
resources/views/components/post/⚡create/
├── create.php          # PHP class
├── create.blade.php    # Blade template
├── create.js           # JavaScript (optional)
├── create.css          # Scoped styles (optional)
├── create.global.css   # Global styles (optional)
└── create.test.php     # Pest test (optional, with --test flag)
```

```bash
Command options

# The make:livewire command accepts the following options:
    Option 	Description
    --sfc 	Create a single-file component (default)
    --mfc 	Create a multi-file component
    --class 	Create a class-based component
    --type=sfc|mfc|class 	Set the component type explicitly
    --emoji=true|false 	Override the config emoji setting for this command
    --test 	Include a Pest test file
    --js 	Include a JavaScript file (multi-file components only)
    --css 	Include CSS files (multi-file components only)
```

# Преобразование между форматами

- преобразование компонентов между однофайловыми и многофайловыми форматами.

```bash
php artisan livewire:convert post.create
```

# Однофайловый → Многофайловый (или наоборот)

```bash
php artisan livewire:convert post.create --mfc
```

# Явным образом преобразовать в однофайловый:

```bash
php artisan livewire:convert post.create --sfc

```

- Это объединит все файлы обратно в один файл и удалит каталог.

# Однофайловый class based

```bash
php artisan make:livewire product.product-create --class
```

# Создайте файл макета

```bash
php artisan livewire:layout
```

# Создание компонентов страницы

- При создании компонентов, которые будут использоваться как полноценные страницы,
- используйте пространство имен pages::, чтобы упорядочить их в выделенном каталоге:

```bash
php artisan make:livewire pages::post.create
php artisan make:livewire pages::contact
```

- При этом компонент создается в разделе resources/views/pages/post/⚡create.blade.php.
- Эта организация позволяет четко определить, какие компоненты являются страницами,
- а какие - повторно используемыми компонентами пользовательского интерфейса.

# Когда использовать тот или иной формат

## Однофайловые компоненты (по умолчанию):

- Лучше всего подходят для большинства компонентов
- Объединяют связанный код
- Легко понятны с первого взгляда
- Идеально подходят для небольших и средних компонентов

## Многофайловые компоненты:

- Лучше подходят для больших и сложных компонентов
- Улучшена поддержка IDE и навигация
- Более четкое разделение при значительном использовании JavaScript в компонентах

## Компоненты, основанные на классах:

- Знакомы разработчикам по Livewire v2/v3
- Традиционное разделение задач в Laravel
- Лучше подходит для команд с установленными соглашениями
- Смотрите компоненты, основанные на классах, ниже

# Создаем компонент test-component

```bash
php artisan make:livewire test-component
```

# Создаем компонент post.edit

```bash
php artisan make:livewire post.edit
```















php artisan make:controller UserController --resource
php artisan make:controller RoleController --resource


use App\Http\Controllers\UserController;
use App\Http\Controllers\RoleController;

Route::resource('users', UserController::class);
Route::resource('roles', RoleController::class);
