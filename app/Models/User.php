<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable, SoftDeletes;

    /**
     * Атрибуты, для которых разрешено массовое присвоение.
     * Объединяем ваши системные поля и стандартные поля Laravel.
     */
    protected $fillable = [
        'uuid',
        'telegram_id',
        'phone',
        'name',
        'first_name',
        'last_name',
        'email',
        'role_id',
        'status',
        'password',
        'hired_at',
        'dismissed_at',
    ];

    /**
     * Атрибуты, которые должны быть скрыты от массивов (например, при ответе API).
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Преобразование типов данных (Casting).
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed', // Автоматическое хеширование при сохранении
            'hired_at' => 'datetime',
            'dismissed_at' => 'datetime',
            'status' => 'string',
        ];
    }

    /**
     * Boot-метод модели.
     * Автоматически генерируем UUID при создании нового пользователя.
     */
    protected static function booted(): void
    {
        static::creating(function (User $user) {
            if (empty($user->uuid)) {
                $user->uuid = (string) Str::uuid();
            }
        });
    }

    /**
     * Связь с таблицей ролей.
     */
    public function role(): BelongsTo
    {
        return $this->belongsTo(Role::class);
    }
}
