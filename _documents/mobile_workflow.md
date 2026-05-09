# Алгоритм заполнения данных в БД FMS

Ниже — как система должна работать в реальном времени и какие таблицы заполняются на каждом этапе.

---

# 1. Инициализация системы

Это начальная загрузка данных.

---

# Этап 1 — создание ролей

Заполняется:

```text id="u8tm6r"
roles
```

Примеры:

| code       | name          |
| ---------- | ------------- |
| admin      | Administrator |
| manager    | Manager       |
| dispatcher | Dispatcher    |
| operator   | Operator      |

---

# Этап 2 — создание пользователей

Руководитель создает сотрудников.

Заполняется:

```text id="l52g4r"
users
```

---

## Что происходит

Сотруднику:

* выдается Telegram Bot access
* присваивается роль
* создается профиль

---

## Пример

```text id="g7fcb9"
dispatcher создает оператора
↓
INSERT INTO users
↓
создается device_sessions
↓
логируется в audit_logs
```

---

# Этап 3 — создание локаций

Создаются объекты обслуживания.

Заполняется:

```text id="w2k0s4"
locations
```

---

## Пример

```sql id="0uhxez"
INSERT INTO locations (
    region,
    city,
    address,
    latitude,
    longitude,
    geom
)
VALUES (
    'Tashkent Region',
    'Chirchiq',
    'Industrial Zone 12',
    41.4682,
    69.5822,
    ST_SetSRID(ST_MakePoint(69.5822, 41.4682), 4326)
);
```

---

# Этап 4 — создание оборудования

Заполняется:

```text id="x1gkgh"
equipment_types
equipment
geofences
```

---

## Что происходит

Указываются:

* тип двигателя
* объем бака
* расход топлива
* интервалы ТО
* GPS
* QR-код

---

# 2. Основной ежедневный workflow

Теперь начинается работа операторов.

---

# Сценарий №1 — Создание задачи

---

## Шаг 1 — диспетчер создает задачу

Заполняется:

```text id="b0yzsx"
tasks
```

---

## Пример

```sql id="9ovqjl"
INSERT INTO tasks (
    equipment_id,
    created_by,
    task_type,
    priority,
    title,
    planned_at,
    deadline_at
)
VALUES (
    15,
    3,
    'refuel',
    'critical',
    'Emergency refuel',
    NOW(),
    NOW() + INTERVAL '2 hours'
);
```

---

# Что делает система

Система:

1. создает задачу
2. рассчитывает SLA
3. проверяет остаток топлива
4. ставит приоритет

---

# Далее

Создается лог:

```text id="1gw1xy"
audit_logs
```

---

# Сценарий №2 — Назначение оператора

---

## Шаг 2 — назначение задачи

Заполняется:

```text id="f0ubvt"
task_assignments
```

---

## Что происходит

```text id="kpik0z"
dispatcher
↓
назначает operator
↓
оператор получает уведомление в Telegram
↓
создается notification
↓
лог в audit_logs
```

---

# Заполняются таблицы

```text id="cpx8n9"
task_assignments
notifications
audit_logs
```

---

# Сценарий №3 — Оператор принимает задачу

---

## Оператор нажимает

```text id="p8v9tm"
[Принять задачу]
```

---

# Обновляются таблицы

```text id="k6c7m9"
task_assignments.accepted_at
tasks.status = in_progress
```

---

# Логируется

```text id="3g25j1"
audit_logs
```

---

# Сценарий №4 — Оператор едет на объект

---

# GPS tracking

Мобильный клиент отправляет координаты каждые N секунд.

Заполняется:

```text id="6l1b1h"
routes
route_points
```

---

# Как это работает

---

## При старте смены

Создается:

```sql id="yrf2kq"
INSERT INTO routes (
    operator_id,
    started_at
)
VALUES (
    22,
    NOW()
);
```

---

## Каждая GPS точка

```sql id="z5x4v0"
INSERT INTO route_points (
    route_id,
    location,
    speed
)
VALUES (
    101,
    ST_SetSRID(ST_MakePoint(69.24, 41.31), 4326),
    54
);
```

---

# Система анализирует

* скорость
* маршрут
* отклонения
* невозможные перемещения

---

# Сценарий №5 — Прибытие на объект

---

# Оператор нажимает

```text id="61nqfm"
[Прибыл]
```

---

# Что делает система

---

## Проверка GPS

Система сравнивает:

```text id="0g4gnh"
GPS оператора
VS
geofence объекта
```

---

# SQL проверка

```sql id="p8h7lg"
ST_DWithin(
    operator_location,
    geofence.center,
    geofence.radius_meters
)
```

---

# Если оператор далеко

Система:

* запрещает закрыть задачу
* создает alert
* пишет в audit_logs

---

# Сценарий №6 — Фотофиксация

---

# Оператор отправляет:

* фото оборудования
* фото фильтров
* фото счетчика

---

# Заполняется

```text id="2v32rp"
files
photos
```

---

# Как работает

---

## Шаг 1 — файл сохраняется

В:

```text id="zq9w5z"
MinIO / S3
```

---

## Шаг 2 — ссылка пишется в БД

```sql id="a7s79m"
INSERT INTO files (
    original_name,
    storage_path,
    mime_type
)
VALUES (...);
```

---

## Шаг 3 — создается photo record

```sql id="h5u7c9"
INSERT INTO photos (
    entity_type,
    entity_id,
    uploaded_by,
    file_url,
    photo_type
)
VALUES (...);
```

---

# Сценарий №7 — Заправка топлива

---

# Оператор вводит:

* сколько литров
* тип топлива
* моточасы

---

# Заполняется

```text id="6js7dy"
fuel_operations
hour_meter_readings
```

---

# Что делает система

---

## Шаг 1 — пишет операцию

```sql id="ut13ez"
INSERT INTO fuel_operations (
    equipment_id,
    operator_id,
    liters,
    fuel_before,
    fuel_after,
    hour_meter
)
VALUES (...);
```

---

## Шаг 2 — обновляет оборудование

```sql id="yphsmj"
UPDATE equipment
SET
    current_fuel_level = ...,
    current_hour_meter = ...
WHERE id = ...;
```

---

# Шаг 3 — пишет моточасы

```sql id="t86kzj"
INSERT INTO hour_meter_readings (...);
```

---

# Шаг 4 — считает аномалии

Система рассчитывает:

```text id="i5fj7e"
expected_consumption
VS
actual_consumption
```

---

# Если отклонение большое

Создается:

```text id="g13mnf"
anomalies
alerts
```

---

# Сценарий №8 — ТО

---

# Заполняется

```text id="2c6ffw"
maintenance_operations
equipment_consumable_history
```

---

# Что делает система

---

## Проверяет интервалы ТО

Например:

```text id="r5rt3x"
каждые 250 часов
```

---

# Если нужен сервис

Создает автоматически:

```text id="j2y9me"
tasks
notifications
```

---

# Сценарий №9 — Закрытие задачи

---

# Оператор нажимает

```text id="ym1p8y"
[Завершить]
```

---

# Что проверяет система

---

## Проверка обязательных условий

Есть ли:

* GPS
* фото
* чеклист
* моточасы
* топливо

---

# Если все хорошо

Обновляется:

```text id="t4vj2v"
tasks.status = completed
task_assignments.completed_at
```

---

# Далее

```text id="m9uhhh"
tasks.is_locked = true
```

---

# После этого

Редактирование запрещено.

---

# Сценарий №10 — Audit Logging

---

# Логируется ВСЕ

Каждое действие:

```text id="u1n90f"
CREATE
UPDATE
DELETE
LOGIN
TRANSFER
COMPLETE
BLOCK
```

---

# Пример

```sql id="qv0e9k"
INSERT INTO audit_logs (
    user_id,
    entity_type,
    entity_id,
    action,
    old_data,
    new_data
)
VALUES (...);
```

---

# Сценарий №11 — Прогноз топлива

---

# Источник данных

Берутся:

```text id="5z4b5k"
fuel_operations
hour_meter_readings
telemetry
```

---

# Система рассчитывает

---

## Средний расход

```text id="mxz9mf"
литры / моточасы
```

---

## Остаток времени

```text id="i8z9vb"
current_fuel_level
/
avg_consumption_per_hour
```

---

# Результат

Обновляется:

```text id="7gjrhm"
mv_equipment_status
fuel_statistics_daily
```

---

# Сценарий №12 — Телеметрия IoT

---

# Контроллер отправляет данные

API принимает:

```json id="lddr9r"
{
  "fuel_level": 44,
  "temperature": 88,
  "engine_hours": 1820
}
```

---

# Записывается

```text id="5l1h8s"
telemetry
```

---

# Далее

Система:

* сравнивает с нормами
* выявляет аномалии
* генерирует alerts

---

# Сценарий №13 — Увольнение сотрудника

---

# Руководитель блокирует сотрудника

Обновляется:

```text id="nchln7"
users.status = dismissed
```

---

# Далее

Система:

* закрывает device_sessions
* запрещает вход
* снимает активные задачи
* пишет audit_logs

---

# Важная архитектурная идея

Система работает как:

```text id="ovw57r"
Event Driven System
```

---

# Любое действие = событие

Например:

```text id="9g6mrl"
TaskCreated
TaskAssigned
OperatorArrived
FuelRefilled
PhotoUploaded
TaskCompleted
```

---

# И каждое событие:

1. пишет данные в БД
2. создает audit log
3. может генерировать alert
4. может запускать аналитику
5. может отправлять notification

---

# Идеальный поток данных

```text id="0qn4d3"
Telegram Bot
    ↓
API Gateway
    ↓
Business Logic
    ↓
PostgreSQL
    ↓
Events / Queue
    ↓
Analytics / Alerts / Notifications
```

---

# Что особенно важно

---

# 1. Никогда не удалять историю

Только:

```text id="4yyks5"
deleted_at
```

---

# 2. Все изменения должны быть трассируемы

Через:

```text id="9md9h9"
audit_logs
```

---

# 3. Любая задача должна быть воспроизводима

Нужно видеть:

* кто создал
* кто взял
* кто выполнил
* где был
* что загрузил
* когда завершил

---

# 4. Любая цифра должна быть проверяема

Например:

```text id="ngn3s7"
литры топлива
↔
моточасы
↔
расход
↔
GPS
↔
фото
```
