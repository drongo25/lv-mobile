Архитектура БД для системы обслуживания оборудования
Для такой системы лучше всего подойдет:


PostgreSQL




PostGIS для геолокации




Потому что:


геоданные


маршруты


аналитика


журналирование


сложные отчеты


прогнозирование



Основные принципы проектирования
Система должна поддерживать:


аудит всех действий


историю изменений


телеметрию


масштабирование


оффлайн работу операторов


прогнозирование


фотоархив


геоаналитику



Основные сущности
UsersRolesEquipmentEquipmentTypesLocationsTasksTaskAssignmentsFuelOperationsMaintenanceOperationsHourMeterReadingsPhotosTelemetryNotificationsAuditLogsRoutesRoutePointsConsumablesInventoryEquipmentConsumableHistory

1. Пользователи
users
CREATE TABLE users (    id BIGSERIAL PRIMARY KEY,    telegram_id BIGINT UNIQUE,    phone VARCHAR(30),    first_name VARCHAR(100),    last_name VARCHAR(100),    role_id BIGINT NOT NULL,    status VARCHAR(30) NOT NULL DEFAULT 'active',    -- active    -- blocked    -- dismissed    hired_at TIMESTAMP,    dismissed_at TIMESTAMP,    password_hash TEXT,    created_at TIMESTAMP NOT NULL DEFAULT NOW(),    updated_at TIMESTAMP NOT NULL DEFAULT NOW());

2. Роли
roles
CREATE TABLE roles (    id BIGSERIAL PRIMARY KEY,    code VARCHAR(50) UNIQUE NOT NULL,    name VARCHAR(100) NOT NULL);
Примеры:


operator


senior_operator


dispatcher


manager


admin



3. Геолокации объектов
locations
CREATE TABLE locations (    id BIGSERIAL PRIMARY KEY,    region VARCHAR(100),    city VARCHAR(100),    address TEXT,    latitude NUMERIC(10,7),    longitude NUMERIC(10,7),    geom GEOGRAPHY(POINT, 4326),    created_at TIMESTAMP DEFAULT NOW());

4. Типы оборудования
equipment_types
CREATE TABLE equipment_types (    id BIGSERIAL PRIMARY KEY,    name VARCHAR(100) NOT NULL,    fuel_type VARCHAR(30),    -- diesel    -- petrol    fuel_tank_capacity NUMERIC(10,2),    avg_fuel_consumption_per_hour NUMERIC(10,2),    oil_check_interval_hours INTEGER,    filter_replace_interval_hours INTEGER);

5. Оборудование
equipment
CREATE TABLE equipment (    id BIGSERIAL PRIMARY KEY,    inventory_number VARCHAR(100) UNIQUE,    equipment_type_id BIGINT NOT NULL        REFERENCES equipment_types(id),    location_id BIGINT NOT NULL        REFERENCES locations(id),    serial_number VARCHAR(255),    name VARCHAR(255),    status VARCHAR(50) DEFAULT 'active',    -- active    -- maintenance    -- broken    -- stopped    installed_at TIMESTAMP,    current_fuel_level NUMERIC(10,2),    current_hour_meter NUMERIC(12,2),    last_fuel_update_at TIMESTAMP,    last_service_at TIMESTAMP,    qr_code TEXT,    created_at TIMESTAMP DEFAULT NOW(),    updated_at TIMESTAMP DEFAULT NOW());

6. Задачи
tasks
CREATE TABLE tasks (    id BIGSERIAL PRIMARY KEY,    equipment_id BIGINT NOT NULL        REFERENCES equipment(id),    task_type VARCHAR(50) NOT NULL,    -- refuel    -- oil_check    -- filter_replace    -- inspection    priority VARCHAR(20) DEFAULT 'normal',    -- low    -- normal    -- high    -- critical    status VARCHAR(30) DEFAULT 'new',    -- new    -- assigned    -- in_progress    -- completed    -- cancelled    -- overdue    planned_at TIMESTAMP,    deadline_at TIMESTAMP,    created_by BIGINT REFERENCES users(id),    description TEXT,    created_at TIMESTAMP DEFAULT NOW(),    updated_at TIMESTAMP DEFAULT NOW());

7. Назначения задач
task_assignments
История назначения задач.
CREATE TABLE task_assignments (    id BIGSERIAL PRIMARY KEY,    task_id BIGINT NOT NULL        REFERENCES tasks(id),    user_id BIGINT NOT NULL        REFERENCES users(id),    assigned_by BIGINT        REFERENCES users(id),    assigned_at TIMESTAMP DEFAULT NOW(),    accepted_at TIMESTAMP,    completed_at TIMESTAMP,    transfer_reason TEXT,    status VARCHAR(30) DEFAULT 'assigned');

8. Операции заправки
fuel_operations
CREATE TABLE fuel_operations (    id BIGSERIAL PRIMARY KEY,    equipment_id BIGINT NOT NULL        REFERENCES equipment(id),    operator_id BIGINT NOT NULL        REFERENCES users(id),    task_id BIGINT        REFERENCES tasks(id),    fuel_type VARCHAR(30),    liters NUMERIC(10,2) NOT NULL,    fuel_before NUMERIC(10,2),    fuel_after NUMERIC(10,2),    hour_meter NUMERIC(12,2),    location GEOGRAPHY(POINT, 4326),    comment TEXT,    created_at TIMESTAMP DEFAULT NOW());

9. Проверки и обслуживание
maintenance_operations
CREATE TABLE maintenance_operations (    id BIGSERIAL PRIMARY KEY,    equipment_id BIGINT NOT NULL        REFERENCES equipment(id),    operator_id BIGINT NOT NULL        REFERENCES users(id),    task_id BIGINT        REFERENCES tasks(id),    oil_level VARCHAR(30),    -- normal    -- low    -- critical    oil_condition VARCHAR(30),    filter_condition VARCHAR(30),    filter_replaced BOOLEAN DEFAULT FALSE,    notes TEXT,    location GEOGRAPHY(POINT, 4326),    created_at TIMESTAMP DEFAULT NOW());

10. Моточасы
hour_meter_readings
CREATE TABLE hour_meter_readings (    id BIGSERIAL PRIMARY KEY,    equipment_id BIGINT NOT NULL        REFERENCES equipment(id),    operator_id BIGINT        REFERENCES users(id),    source VARCHAR(30),    -- manual    -- iot    reading NUMERIC(12,2) NOT NULL,    reading_at TIMESTAMP NOT NULL,    created_at TIMESTAMP DEFAULT NOW());

11. Фотографии
photos
CREATE TABLE photos (    id BIGSERIAL PRIMARY KEY,    entity_type VARCHAR(50),    -- equipment    -- task    -- fuel_operation    -- maintenance    entity_id BIGINT NOT NULL,    uploaded_by BIGINT        REFERENCES users(id),    file_url TEXT NOT NULL,    photo_type VARCHAR(50),    -- equipment    -- fuel    -- filter    -- oil    -- meter    latitude NUMERIC(10,7),    longitude NUMERIC(10,7),    taken_at TIMESTAMP,    created_at TIMESTAMP DEFAULT NOW());

12. Телеметрия
telemetry
Если будут IoT датчики.
CREATE TABLE telemetry (    id BIGSERIAL PRIMARY KEY,    equipment_id BIGINT NOT NULL        REFERENCES equipment(id),    fuel_level NUMERIC(10,2),    oil_pressure NUMERIC(10,2),    temperature NUMERIC(10,2),    battery_voltage NUMERIC(10,2),    engine_hours NUMERIC(12,2),    payload JSONB,    received_at TIMESTAMP DEFAULT NOW());

13. Уведомления
notifications
CREATE TABLE notifications (    id BIGSERIAL PRIMARY KEY,    user_id BIGINT REFERENCES users(id),    type VARCHAR(50),    title VARCHAR(255),    body TEXT,    is_read BOOLEAN DEFAULT FALSE,    sent_at TIMESTAMP DEFAULT NOW());

14. Полное логирование
audit_logs
КРИТИЧЕСКАЯ таблица.
CREATE TABLE audit_logs (    id BIGSERIAL PRIMARY KEY,    user_id BIGINT REFERENCES users(id),    entity_type VARCHAR(100),    entity_id BIGINT,    action VARCHAR(100),    -- create    -- update    -- delete    -- login    -- assign    -- transfer    -- complete    old_data JSONB,    new_data JSONB,    ip_address INET,    user_agent TEXT,    created_at TIMESTAMP DEFAULT NOW());

15. Маршруты операторов
routes
CREATE TABLE routes (    id BIGSERIAL PRIMARY KEY,    operator_id BIGINT REFERENCES users(id),    started_at TIMESTAMP,    finished_at TIMESTAMP,    total_distance_km NUMERIC(10,2),    created_at TIMESTAMP DEFAULT NOW());

16. GPS точки маршрутов
route_points
CREATE TABLE route_points (    id BIGSERIAL PRIMARY KEY,    route_id BIGINT REFERENCES routes(id),    location GEOGRAPHY(POINT, 4326),    speed NUMERIC(10,2),    recorded_at TIMESTAMP DEFAULT NOW());

17. Расходники
consumables
CREATE TABLE consumables (    id BIGSERIAL PRIMARY KEY,    name VARCHAR(255),    type VARCHAR(50),    -- filter    -- oil    -- coolant    unit VARCHAR(20));

18. Склад
inventory
CREATE TABLE inventory (    id BIGSERIAL PRIMARY KEY,    consumable_id BIGINT REFERENCES consumables(id),    quantity NUMERIC(10,2),    warehouse_name VARCHAR(255),    updated_at TIMESTAMP DEFAULT NOW());

19. История замен
equipment_consumable_history
CREATE TABLE equipment_consumable_history (    id BIGSERIAL PRIMARY KEY,    equipment_id BIGINT REFERENCES equipment(id),    consumable_id BIGINT REFERENCES consumables(id),    maintenance_operation_id BIGINT        REFERENCES maintenance_operations(id),    quantity NUMERIC(10,2),    replaced_at TIMESTAMP DEFAULT NOW());

Важные индексы
Геоиндексы
CREATE INDEX idx_locations_geomON locations USING GIST (geom);CREATE INDEX idx_route_points_geomON route_points USING GIST (location);

Производительность
CREATE INDEX idx_tasks_statusON tasks(status);CREATE INDEX idx_tasks_deadlineON tasks(deadline_at);CREATE INDEX idx_audit_logs_createdON audit_logs(created_at);CREATE INDEX idx_fuel_operations_equipmentON fuel_operations(equipment_id);

Очень важные вещи
1. История изменений
НИКОГДА не удалять данные физически.
Добавить:
deleted_at TIMESTAMP

2. JSONB для гибкости
Для нестандартных параметров:
metadata JSONB

Прогнозирование топлива
Лучше сделать отдельную агрегированную таблицу.
fuel_statistics_daily
CREATE TABLE fuel_statistics_daily (    id BIGSERIAL PRIMARY KEY,    equipment_id BIGINT REFERENCES equipment(id),    date DATE,    total_consumption NUMERIC(10,2),    engine_hours NUMERIC(10,2),    avg_consumption_per_hour NUMERIC(10,2));

Для AI и аналитики
Нужны:
anomalies
CREATE TABLE anomalies (    id BIGSERIAL PRIMARY KEY,    equipment_id BIGINT REFERENCES equipment(id),    anomaly_type VARCHAR(100),    severity VARCHAR(30),    description TEXT,    detected_at TIMESTAMP DEFAULT NOW(),    resolved BOOLEAN DEFAULT FALSE);

Что будет самым тяжелым
Самые нагруженные таблицы:


telemetry


route_points


audit_logs


photos


Их лучше:


партиционировать


архивировать


хранить отдельно



Рекомендую сразу заложить
Партиционирование
Например:
PARTITION BY RANGE(created_at)
Для:


telemetry


audit_logs


route_points



Архитектура хранения фото
НЕ хранить фото в БД.
Хранить:


S3


MinIO


В БД только ссылки.

Финальная архитектура
PostgreSQL ├── Core schema ├── Geo schema ├── Audit schema ├── Analytics schema └── Telemetry schema

Что я бы сделал следующим шагом


ERD диаграмму


API контракт


Telegram bot flow


RBAC модель


Event-driven архитектуру


Схему прогнозирования топлива


Схему antifraud контроля


Offline-first механику для операторов

