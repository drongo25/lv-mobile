-- =========================================================
-- FMS Complete Demo Data (100+ Records)
-- =========================================================

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Справочник расходников
TRUNCATE TABLE consumables;
INSERT INTO consumables (name, type, unit)
VALUES ('Масло Shell Rimula 10W-40', 'oil', 'L'),
       ('Масляный фильтр Perkins 2654', 'filter', 'pcs'),
       ('Топливный фильтр Perkins 2656', 'filter', 'pcs'),
       ('Антифриз G12 Red', 'coolant', 'L'),
       ('Набор прокладок ГБЦ', 'spare_part', 'set');

-- 2. Складские запасы
TRUNCATE TABLE inventory;
INSERT INTO inventory (consumable_id, warehouse_name, quantity)
VALUES (1, 'Главный склад', 1000.00),
       (2, 'Главный склад', 100.00),
       (3, 'Главный склад', 85.00),
       (4, 'Главный склад', 250.00),
       (1, 'Сервисный модуль №1', 60.00),
       (2, 'Сервисный модуль №1', 10.00);

-- 3. Роли и Пользователи
-- TRUNCATE TABLE roles;
-- INSERT INTO roles (code, name)
-- VALUES ('admin', 'Administrator'),
--        ('manager', 'Manager'),
--        ('dispatcher', 'Dispatcher'),
--        ('operator', 'Operator');

-- TRUNCATE TABLE users;
-- INSERT INTO users (uuid, telegram_id, phone, first_name, last_name, role_id, status)
-- VALUES (UUID(), 100001, '+79001112233', 'Иван', 'Админов', 1, 'active'),
--        (UUID(), 200001, '+79005556601', 'Алексей', 'Операторов', 4, 'active'),
--        (UUID(), 200002, '+79005556602', 'Дмитрий', 'Полевой', 4, 'active'),
--        (UUID(), 200003, '+79005556603', 'Сергей', 'Техников', 4, 'active');

-- 4. Локации и Оборудование
TRUNCATE TABLE locations;
INSERT INTO locations (region, city, address, latitude, longitude)
VALUES ('МО', 'Москва', 'Промзона 1', 55.7558, 37.6173),
       ('МО', 'Химки', 'Объект Север', 55.8941, 37.4440),
       ('МО', 'Подольск', 'Объект Юг', 55.4312, 37.5458);

TRUNCATE TABLE equipment_types;
INSERT INTO equipment_types (name, fuel_type, fuel_tank_capacity, avg_fuel_consumption_per_hour)
VALUES ('Генератор 200кВт', 'diesel', 400.00, 25.0),
       ('Генератор 50кВт', 'diesel', 120.00, 8.5);

TRUNCATE TABLE equipment;
INSERT INTO equipment (uuid, inventory_number, equipment_type_id, location_id, name, status, current_fuel_level,
                       current_hour_meter)
VALUES (UUID(), 'GEN-01', 1, 1, 'Основной Цех', 'active', 320.0, 1500.0),
       (UUID(), 'GEN-02', 2, 2, 'Резерв Химки', 'active', 95.0, 420.5),
       (UUID(), 'GEN-03', 1, 3, 'Подольск Склад', 'maintenance', 50.0, 3100.2);

-- 5. Массовая генерация 100 ЗАДАЧ и ОПЕРАЦИЙ
DELIMITER //
CREATE PROCEDURE PopulateDemo()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE cur_eq_id BIGINT;
    DECLARE cur_op_id BIGINT;

    WHILE i <= 100
        DO
            -- Выбираем случайное оборудование и оператора
            SELECT id INTO cur_eq_id FROM equipment ORDER BY RAND() LIMIT 1;
            SELECT id INTO cur_op_id FROM users WHERE role_id = 4 ORDER BY RAND() LIMIT 1;

            -- Создаем задачу
            INSERT INTO tasks (uuid, equipment_id, created_by, task_type, status, title, created_at)
            VALUES (UUID(), cur_eq_id, 1,
                    IF(i % 2 = 0, 'refuel', 'maintenance'),
                    IF(i % 4 = 0, 'completed', 'new'),
                    CONCAT('Задание #', i),
                    NOW() - INTERVAL i HOUR);

            -- Если задача "выполнена", создаем операцию
            IF i % 4 = 0 THEN
                IF i % 2 = 0 THEN
                    -- Заправка
                    INSERT INTO fuel_operations (equipment_id, operator_id, fuel_type, liters, fuel_before, fuel_after,
                                                 created_at)
                    VALUES (cur_eq_id, cur_op_id, 'diesel', 50.0, 100.0, 150.0, NOW() - INTERVAL i HOUR);
                ELSE
                    -- ТО
                    INSERT INTO maintenance_operations (equipment_id, operator_id, maintenance_type, oil_changed,
                                                        filter_replaced, created_at)
                    VALUES (cur_eq_id, cur_op_id, 'oil_service', TRUE, TRUE, NOW() - INTERVAL i HOUR);
                END IF;
            END IF;

            SET i = i + 1;
        END WHILE;
END //
DELIMITER ;

CALL PopulateDemo();
DROP PROCEDURE PopulateDemo;

-- 6. Телеметрия и Логи (Партиции)
INSERT INTO telemetry (equipment_id, fuel_level, engine_hours, battery_voltage, received_at)
VALUES (1, 315.5, 1501.2, 24.5, NOW()),
       (2, 92.0, 421.0, 24.2, NOW());

INSERT INTO audit_logs (user_id, entity_type, action, new_data, created_at)
VALUES (1, 'equipment', 'update', '{
  "status": "maintenance"
}', NOW());

SET FOREIGN_KEY_CHECKS = 1;