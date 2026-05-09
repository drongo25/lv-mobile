-- =========================================================
-- FMS (Fuel & Field Maintenance System)
-- Спецификация: MySQL 8.0+
-- Описание: Система управления топливом и техническим обслуживанием
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------
-- БЛОК 1: УПРАВЛЕНИЕ ДОСТУПОМ
-- ---------------------------------------------------------

-- 1. Справочник ролей пользователей (admin, operator и т.д.)
-- CREATE TABLE roles
-- (
--     id          BIGINT AUTO_INCREMENT PRIMARY KEY,
--     code        VARCHAR(50) UNIQUE NOT NULL, -- Код для программной логики
--     name        VARCHAR(100)       NOT NULL, -- Отображаемое название
--     description TEXT                         -- Подробное описание прав
-- ) ENGINE = InnoDB;

-- 2. Таблица пользователей системы
-- CREATE TABLE users
-- (
--     id            BIGINT AUTO_INCREMENT PRIMARY KEY,
--     uuid          VARCHAR(36)                             NOT NULL,
--     telegram_id   BIGINT UNIQUE,                  -- Для интеграции с ботом
--     phone         VARCHAR(30) UNIQUE,
--     first_name    VARCHAR(100)                            NOT NULL,
--     last_name     VARCHAR(100),
--     role_id       BIGINT                                  NOT NULL,
--     status        ENUM ('active', 'blocked', 'dismissed') NOT NULL DEFAULT 'active',
--     password_hash TEXT,                           -- Хеш пароля для веб-панели
--     hired_at      TIMESTAMP                               NULL,
--     dismissed_at  TIMESTAMP                               NULL,
--     created_at    TIMESTAMP                                        DEFAULT CURRENT_TIMESTAMP,
--     updated_at    TIMESTAMP                                        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--     deleted_at    TIMESTAMP                               NULL,
--     CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES roles (id)
-- ) ENGINE = InnoDB;

-- ---------------------------------------------------------
-- БЛОК 2: ОБЪЕКТЫ И ОБОРУДОВАНИЕ
-- ---------------------------------------------------------

-- 3. Географические локации (адреса объектов)
CREATE TABLE locations
(
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    region     VARCHAR(255),
    city       VARCHAR(255),
    district   VARCHAR(255),
    address    TEXT,
    latitude   DECIMAL(10, 7) NULL, -- Широта (Decimal для точности)
    longitude  DECIMAL(10, 7) NULL, -- Долгота
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_lat_lng (latitude, longitude)
) ENGINE = InnoDB;

-- 4. Технические характеристики типов оборудования (генераторы, помпы и т.д.)
CREATE TABLE equipment_types
(
    id                            BIGINT AUTO_INCREMENT PRIMARY KEY,
    name                          VARCHAR(255)              NOT NULL,
    fuel_type                     ENUM ('diesel', 'petrol') NOT NULL,
    fuel_tank_capacity            DECIMAL(10, 2), -- Объем бака
    avg_fuel_consumption_per_hour DECIMAL(10, 2), -- Справочный расход
    oil_service_interval_hours    INT,            -- Интервал замены масла
    filter_service_interval_hours INT,            -- Интервал замены фильтров
    created_at                    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

-- 5. Конкретные единицы оборудования (экземпляры)
CREATE TABLE equipment
(
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid                VARCHAR(36)         NOT NULL,
    inventory_number    VARCHAR(255) UNIQUE NOT NULL, -- Инвентарный номер
    serial_number       VARCHAR(255),                -- Заводской номер
    equipment_type_id   BIGINT              NOT NULL,
    location_id         BIGINT              NOT NULL,
    name                VARCHAR(255),
    status              ENUM ('active', 'maintenance', 'broken', 'stopped') DEFAULT 'active',
    current_fuel_level  DECIMAL(10, 2)                                      DEFAULT 0,
    current_hour_meter  DECIMAL(12, 2)                                      DEFAULT 0, -- Моточасы
    qr_code             TEXT,                -- Ссылка или данные QR-кода
    installed_at        TIMESTAMP           NULL,
    last_service_at     TIMESTAMP           NULL,
    last_fuel_update_at TIMESTAMP           NULL,
    metadata            JSON,                -- Доп. параметры в формате JSON
    created_at          TIMESTAMP                                           DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP                                           DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMP           NULL,
    CONSTRAINT fk_eq_type FOREIGN KEY (equipment_type_id) REFERENCES equipment_types (id),
    CONSTRAINT fk_eq_loc FOREIGN KEY (location_id) REFERENCES locations (id)
) ENGINE = InnoDB;

-- ---------------------------------------------------------
-- БЛОК 3: ПРОЦЕССЫ И РАБОТЫ
-- ---------------------------------------------------------

-- 6. Задачи для операторов (заправка, ремонт, осмотр)
CREATE TABLE tasks
(
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid         VARCHAR(36)  NOT NULL,
    equipment_id BIGINT       NOT NULL,
    created_by   BIGINT       NULL,
    task_type    VARCHAR(100) NOT NULL,
    priority     ENUM ('low', 'normal', 'high', 'critical')                                   DEFAULT 'normal',
    status       ENUM ('new', 'assigned', 'in_progress', 'completed', 'cancelled', 'overdue') DEFAULT 'new',
    title        VARCHAR(255),
    description  TEXT,
    planned_at   TIMESTAMP    NULL,
    deadline_at  TIMESTAMP    NULL,
    started_at   TIMESTAMP    NULL,
    completed_at TIMESTAMP    NULL,
    metadata     JSON,
    created_at   TIMESTAMP                                                                    DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP                                                                    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_task_eq FOREIGN KEY (equipment_id) REFERENCES equipment (id)
) ENGINE = InnoDB;

-- 7. Журнал заправок (фиксация литража и уровня топлива)
CREATE TABLE fuel_operations
(
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id      BIGINT                    NULL, -- Связь с задачей
    equipment_id BIGINT                    NOT NULL,
    operator_id  BIGINT                    NOT NULL,
    fuel_type    ENUM ('diesel', 'petrol') NOT NULL,
    liters       DECIMAL(10, 2)            NOT NULL, -- Сколько заправлено
    fuel_before  DECIMAL(10, 2),                     -- Было до
    fuel_after   DECIMAL(10, 2),                     -- Стало после
    hour_meter   DECIMAL(12, 2),                     -- Моточасы в момент заправки
    latitude     DECIMAL(10, 7)            NULL,     -- Координаты заправки
    longitude    DECIMAL(10, 7)            NULL,
    notes        TEXT,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fuel_eq FOREIGN KEY (equipment_id) REFERENCES equipment (id),
    CONSTRAINT fk_fuel_op FOREIGN KEY (operator_id) REFERENCES users (id)
) ENGINE = InnoDB;

-- 8. Журнал технического обслуживания (ТО, замена масла/фильтров)
CREATE TABLE maintenance_operations
(
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id          BIGINT                                                                         NULL,
    equipment_id     BIGINT                                                                         NOT NULL,
    operator_id      BIGINT                                                                         NOT NULL,
    maintenance_type ENUM ('inspection', 'oil_service', 'filter_service', 'full_service', 'repair') NOT NULL,
    oil_level        ENUM ('low', 'normal', 'high') DEFAULT 'normal',
    filter_replaced  BOOLEAN                        DEFAULT FALSE,
    oil_changed      BOOLEAN                        DEFAULT FALSE,
    hour_meter       DECIMAL(12, 2),
    latitude         DECIMAL(10, 7)                                                                 NULL,
    longitude        DECIMAL(10, 7)                                                                 NULL,
    notes            TEXT,
    created_at       TIMESTAMP                      DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_maint_eq FOREIGN KEY (equipment_id) REFERENCES equipment (id),
    CONSTRAINT fk_maint_op FOREIGN KEY (operator_id) REFERENCES users (id),
    CONSTRAINT fk_maint_task FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE SET NULL
) ENGINE = InnoDB;

-- ---------------------------------------------------------
-- БЛОК 4: СКЛАДСКОЙ УЧЕТ
-- ---------------------------------------------------------

-- 9. Справочник ТМЦ (масла, фильтры, запчасти)
CREATE TABLE consumables
(
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(255)                                             NOT NULL,
    type        ENUM ('oil', 'filter', 'coolant', 'spare_part', 'other') NOT NULL,
    unit        VARCHAR(50) DEFAULT 'pcs',
    description TEXT,
    created_at  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

-- 10. Остатки на складах (центральный склад, борт машины)
CREATE TABLE inventory
(
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    consumable_id  BIGINT       NOT NULL,
    warehouse_name VARCHAR(255) NOT NULL,
    quantity       DECIMAL(10, 2) DEFAULT 0,
    updated_at     TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_inv_cons FOREIGN KEY (consumable_id) REFERENCES consumables (id) ON DELETE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------
-- БЛОК 5: ЛОГИСТИКА И МЕДИА
-- ---------------------------------------------------------

-- 11. Фотоотчеты (привязка к задачам, оборудованию или операциям)
CREATE TABLE photos
(
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid        VARCHAR(36)                             NOT NULL,
    entity_type ENUM ('task', 'equipment', 'operation') NOT NULL,
    entity_id   BIGINT                                  NOT NULL,
    uploaded_by BIGINT                                  NULL,
    photo_type  ENUM ('equipment', 'fuel', 'filter_old', 'filter_new', 'oil', 'meter', 'general'),
    file_url    TEXT                                    NOT NULL,
    latitude    DECIMAL(10, 7)                          NULL,
    longitude   DECIMAL(10, 7)                          NULL,
    taken_at    TIMESTAMP                               NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

-- 12. Маршрутные листы (рейсы операторов)
CREATE TABLE routes
(
    id                BIGINT AUTO_INCREMENT PRIMARY KEY,
    operator_id       BIGINT    NOT NULL,
    started_at        TIMESTAMP NULL,
    finished_at       TIMESTAMP NULL,
    total_distance_km DECIMAL(10, 2),
    CONSTRAINT fk_route_op FOREIGN KEY (operator_id) REFERENCES users (id)
) ENGINE = InnoDB;

-- ---------------------------------------------------------
-- БЛОК 6: БОЛЬШИЕ ДАННЫЕ (СЕКЦИОНИРОВАНИЕ)
-- ---------------------------------------------------------

-- 13. GPS-трекинг (координаты движения оператора внутри маршрута)
CREATE TABLE route_points
(
    id          BIGINT         NOT NULL AUTO_INCREMENT,
    route_id    BIGINT         NOT NULL,
    latitude    DECIMAL(10, 7) NOT NULL,
    longitude   DECIMAL(10, 7) NOT NULL,
    speed       DECIMAL(5, 2)  NULL,
    recorded_at DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, recorded_at),
    INDEX (route_id)
) ENGINE = InnoDB
    PARTITION BY RANGE (TO_DAYS(recorded_at)) (
        PARTITION p2026_01 VALUES LESS THAN (TO_DAYS('2026-02-01')),
        PARTITION p2026_02 VALUES LESS THAN (TO_DAYS('2026-03-01')),
        PARTITION p_future VALUES LESS THAN MAXVALUE
        );

-- 14. Телеметрия оборудования (данные с датчиков уровня топлива/моточасов)
CREATE TABLE telemetry
(
    id              BIGINT   NOT NULL AUTO_INCREMENT,
    equipment_id    BIGINT   NOT NULL,
    fuel_level      DECIMAL(10, 2),
    engine_hours    DECIMAL(12, 2),
    battery_voltage DECIMAL(10, 2),
    payload         JSON, -- Сырые данные от трекера
    received_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, received_at),
    INDEX (equipment_id)
) ENGINE = InnoDB
    PARTITION BY RANGE (TO_DAYS(received_at)) (
        PARTITION p2026_01 VALUES LESS THAN (TO_DAYS('2026-02-01')),
        PARTITION p2026_02 VALUES LESS THAN (TO_DAYS('2026-03-01')),
        PARTITION p_future VALUES LESS THAN MAXVALUE
        );

-- 15. Аудит действий пользователей (кто, что и когда изменил)
CREATE TABLE audit_logs
(
    id          BIGINT   NOT NULL AUTO_INCREMENT,
    user_id     BIGINT,
    entity_type VARCHAR(255), -- Название таблицы
    entity_id   BIGINT,      -- ID записи
    action      VARCHAR(100), -- create, update, delete
    old_data    JSON,
    new_data    JSON,
    ip_address  VARCHAR(45),
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at),
    INDEX (user_id)
) ENGINE = InnoDB
    PARTITION BY RANGE (TO_DAYS(created_at)) (
        PARTITION p2026_01 VALUES LESS THAN (TO_DAYS('2026-02-01')),
        PARTITION p_future VALUES LESS THAN MAXVALUE
        );

-- ---------------------------------------------------------
-- БЛОК 7: АНАЛИТИКА
-- ---------------------------------------------------------

-- Представление для мониторинга: остаток топлива в часах работы
CREATE VIEW v_equipment_monitoring AS
SELECT e.id,
       e.inventory_number,
       e.name,
       e.status,
       e.current_fuel_level,
       e.current_hour_meter,
       CASE
           WHEN et.avg_fuel_consumption_per_hour > 0
               THEN ROUND(e.current_fuel_level / et.avg_fuel_consumption_per_hour, 1)
           ELSE NULL
           END AS est_hours_remaining
FROM equipment e
         JOIN equipment_types et ON e.equipment_type_id = et.id;

SET FOREIGN_KEY_CHECKS = 1;