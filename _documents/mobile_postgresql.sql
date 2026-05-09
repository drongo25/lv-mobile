
-- =========================================================
-- FMS (Fuel & Field Maintenance System)
-- Full PostgreSQL Database Schema
-- PostgreSQL 15+
-- Extensions:
--   uuid-ossp
--   postgis
-- =========================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- =========================================================
-- ENUMS
-- =========================================================

CREATE TYPE user_status AS ENUM (
    'active',
    'blocked',
    'dismissed'
);

CREATE TYPE task_status AS ENUM (
    'new',
    'assigned',
    'in_progress',
    'completed',
    'cancelled',
    'overdue'
);

CREATE TYPE task_priority AS ENUM (
    'low',
    'normal',
    'high',
    'critical'
);

CREATE TYPE equipment_status AS ENUM (
    'active',
    'maintenance',
    'broken',
    'stopped'
);

CREATE TYPE fuel_type_enum AS ENUM (
    'diesel',
    'petrol'
);

CREATE TYPE maintenance_type_enum AS ENUM (
    'inspection',
    'oil_service',
    'filter_service',
    'full_service'
);

CREATE TYPE photo_type_enum AS ENUM (
    'equipment',
    'fuel',
    'filter_old',
    'filter_new',
    'oil',
    'meter',
    'general'
);

CREATE TYPE notification_type_enum AS ENUM (
    'task',
    'alert',
    'warning',
    'system'
);

CREATE TYPE telemetry_source_enum AS ENUM (
    'manual',
    'iot'
);

CREATE TYPE anomaly_severity_enum AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);

-- =========================================================
-- UPDATED_AT TRIGGER
-- =========================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- ROLES
-- =========================================================

CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

INSERT INTO roles(code, name) VALUES
('admin', 'Administrator'),
('manager', 'Manager'),
('dispatcher', 'Dispatcher'),
('senior_operator', 'Senior Operator'),
('operator', 'Operator');

-- =========================================================
-- USERS
-- =========================================================

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,

    uuid UUID DEFAULT uuid_generate_v4(),

    telegram_id BIGINT UNIQUE,
    phone VARCHAR(30) UNIQUE,

    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),

    role_id BIGINT NOT NULL REFERENCES roles(id),

    status user_status NOT NULL DEFAULT 'active',

    password_hash TEXT,

    hired_at TIMESTAMP,
    dismissed_at TIMESTAMP,

    last_login_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP
);

CREATE TRIGGER trg_users_updated
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- LOCATIONS
-- =========================================================

CREATE TABLE locations (
    id BIGSERIAL PRIMARY KEY,

    region VARCHAR(255),
    city VARCHAR(255),
    district VARCHAR(255),
    address TEXT,

    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),

    geom GEOGRAPHY(POINT, 4326),

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_locations_geom
ON locations USING GIST(geom);

-- =========================================================
-- EQUIPMENT TYPES
-- =========================================================

CREATE TABLE equipment_types (
    id BIGSERIAL PRIMARY KEY,

    name VARCHAR(255) NOT NULL,

    fuel_type fuel_type_enum NOT NULL,

    fuel_tank_capacity NUMERIC(10,2),

    avg_fuel_consumption_per_hour NUMERIC(10,2),

    oil_service_interval_hours INTEGER,
    filter_service_interval_hours INTEGER,

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- EQUIPMENT
-- =========================================================

CREATE TABLE equipment (
    id BIGSERIAL PRIMARY KEY,

    uuid UUID DEFAULT uuid_generate_v4(),

    inventory_number VARCHAR(255) UNIQUE NOT NULL,

    serial_number VARCHAR(255),

    equipment_type_id BIGINT NOT NULL
        REFERENCES equipment_types(id),

    location_id BIGINT NOT NULL
        REFERENCES locations(id),

    name VARCHAR(255),

    status equipment_status DEFAULT 'active',

    current_fuel_level NUMERIC(10,2) DEFAULT 0,

    current_hour_meter NUMERIC(12,2) DEFAULT 0,

    qr_code TEXT,

    installed_at TIMESTAMP,

    last_service_at TIMESTAMP,

    last_fuel_update_at TIMESTAMP,

    metadata JSONB,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP
);

CREATE TRIGGER trg_equipment_updated
BEFORE UPDATE ON equipment
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- TASKS
-- =========================================================

CREATE TABLE tasks (
    id BIGSERIAL PRIMARY KEY,

    uuid UUID DEFAULT uuid_generate_v4(),

    equipment_id BIGINT NOT NULL
        REFERENCES equipment(id),

    created_by BIGINT
        REFERENCES users(id),

    task_type VARCHAR(100) NOT NULL,

    priority task_priority DEFAULT 'normal',

    status task_status DEFAULT 'new',

    title VARCHAR(255),

    description TEXT,

    planned_at TIMESTAMP,

    deadline_at TIMESTAMP,

    started_at TIMESTAMP,
    completed_at TIMESTAMP,

    is_locked BOOLEAN DEFAULT FALSE,

    metadata JSONB,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP
);

CREATE TRIGGER trg_tasks_updated
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_tasks_status
ON tasks(status);

CREATE INDEX idx_tasks_deadline
ON tasks(deadline_at);

-- =========================================================
-- TASK ASSIGNMENTS
-- =========================================================

CREATE TABLE task_assignments (
    id BIGSERIAL PRIMARY KEY,

    task_id BIGINT NOT NULL
        REFERENCES tasks(id),

    user_id BIGINT NOT NULL
        REFERENCES users(id),

    assigned_by BIGINT
        REFERENCES users(id),

    assigned_at TIMESTAMP DEFAULT NOW(),

    accepted_at TIMESTAMP,

    completed_at TIMESTAMP,

    transfer_reason TEXT,

    status VARCHAR(50),

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- TASK CHECKLISTS
-- =========================================================

CREATE TABLE task_checklists (
    id BIGSERIAL PRIMARY KEY,

    task_id BIGINT NOT NULL
        REFERENCES tasks(id),

    item_name VARCHAR(255) NOT NULL,

    is_required BOOLEAN DEFAULT TRUE,

    is_completed BOOLEAN DEFAULT FALSE,

    completed_by BIGINT
        REFERENCES users(id),

    completed_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- FUEL OPERATIONS
-- =========================================================

CREATE TABLE fuel_operations (
    id BIGSERIAL PRIMARY KEY,

    task_id BIGINT
        REFERENCES tasks(id),

    equipment_id BIGINT NOT NULL
        REFERENCES equipment(id),

    operator_id BIGINT NOT NULL
        REFERENCES users(id),

    fuel_type fuel_type_enum NOT NULL,

    liters NUMERIC(10,2) NOT NULL,

    fuel_before NUMERIC(10,2),

    fuel_after NUMERIC(10,2),

    expected_consumption NUMERIC(10,2),

    actual_consumption NUMERIC(10,2),

    variance NUMERIC(10,2),

    hour_meter NUMERIC(12,2),

    location GEOGRAPHY(POINT, 4326),

    notes TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_fuel_operations_equipment
ON fuel_operations(equipment_id);

-- =========================================================
-- MAINTENANCE OPERATIONS
-- =========================================================

CREATE TABLE maintenance_operations (
    id BIGSERIAL PRIMARY KEY,

    task_id BIGINT REFERENCES tasks(id),

    equipment_id BIGINT NOT NULL
        REFERENCES equipment(id),

    operator_id BIGINT NOT NULL
        REFERENCES users(id),

    maintenance_type maintenance_type_enum NOT NULL,

    oil_level VARCHAR(50),

    oil_condition VARCHAR(50),

    filter_condition VARCHAR(50),

    filter_replaced BOOLEAN DEFAULT FALSE,

    oil_changed BOOLEAN DEFAULT FALSE,

    location GEOGRAPHY(POINT, 4326),

    notes TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- HOUR METER READINGS
-- =========================================================

CREATE TABLE hour_meter_readings (
    id BIGSERIAL PRIMARY KEY,

    equipment_id BIGINT NOT NULL
        REFERENCES equipment(id),

    operator_id BIGINT
        REFERENCES users(id),

    source telemetry_source_enum DEFAULT 'manual',

    reading NUMERIC(12,2) NOT NULL,

    reading_at TIMESTAMP NOT NULL,

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- PHOTOS
-- =========================================================

CREATE TABLE photos (
    id BIGSERIAL PRIMARY KEY,

    uuid UUID DEFAULT uuid_generate_v4(),

    entity_type VARCHAR(100) NOT NULL,

    entity_id BIGINT NOT NULL,

    uploaded_by BIGINT
        REFERENCES users(id),

    photo_type photo_type_enum,

    file_url TEXT NOT NULL,

    thumbnail_url TEXT,

    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),

    gps_point GEOGRAPHY(POINT, 4326),

    taken_at TIMESTAMP,

    metadata JSONB,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_photos_entity
ON photos(entity_type, entity_id);

-- =========================================================
-- TELEMETRY
-- =========================================================

CREATE TABLE telemetry (
    id BIGSERIAL,

    equipment_id BIGINT NOT NULL
        REFERENCES equipment(id),

    fuel_level NUMERIC(10,2),

    oil_pressure NUMERIC(10,2),

    engine_temperature NUMERIC(10,2),

    battery_voltage NUMERIC(10,2),

    engine_hours NUMERIC(12,2),

    payload JSONB,

    received_at TIMESTAMP DEFAULT NOW(),

    PRIMARY KEY(id, received_at)
)
PARTITION BY RANGE(received_at);

-- =========================================================
-- NOTIFICATIONS
-- =========================================================

CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT REFERENCES users(id),

    type notification_type_enum,

    title VARCHAR(255),

    body TEXT,

    is_read BOOLEAN DEFAULT FALSE,

    sent_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- ROUTES
-- =========================================================

CREATE TABLE routes (
    id BIGSERIAL PRIMARY KEY,

    operator_id BIGINT
        REFERENCES users(id),

    started_at TIMESTAMP,

    finished_at TIMESTAMP,

    total_distance_km NUMERIC(10,2),

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- ROUTE POINTS
-- =========================================================

CREATE TABLE route_points (
    id BIGSERIAL,

    route_id BIGINT
        REFERENCES routes(id),

    location GEOGRAPHY(POINT, 4326),

    speed NUMERIC(10,2),

    recorded_at TIMESTAMP DEFAULT NOW(),

    PRIMARY KEY(id, recorded_at)
)
PARTITION BY RANGE(recorded_at);

CREATE INDEX idx_route_points_geom
ON route_points USING GIST(location);

-- =========================================================
-- CONSUMABLES
-- =========================================================

CREATE TABLE consumables (
    id BIGSERIAL PRIMARY KEY,

    name VARCHAR(255) NOT NULL,

    type VARCHAR(100),

    unit VARCHAR(50),

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- INVENTORY
-- =========================================================

CREATE TABLE inventory (
    id BIGSERIAL PRIMARY KEY,

    consumable_id BIGINT
        REFERENCES consumables(id),

    warehouse_name VARCHAR(255),

    quantity NUMERIC(10,2),

    updated_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- EQUIPMENT CONSUMABLE HISTORY
-- =========================================================

CREATE TABLE equipment_consumable_history (
    id BIGSERIAL PRIMARY KEY,

    equipment_id BIGINT
        REFERENCES equipment(id),

    consumable_id BIGINT
        REFERENCES consumables(id),

    maintenance_operation_id BIGINT
        REFERENCES maintenance_operations(id),

    quantity NUMERIC(10,2),

    replaced_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- DAILY FUEL STATISTICS
-- =========================================================

CREATE TABLE fuel_statistics_daily (
    id BIGSERIAL PRIMARY KEY,

    equipment_id BIGINT
        REFERENCES equipment(id),

    stat_date DATE NOT NULL,

    total_consumption NUMERIC(10,2),

    engine_hours NUMERIC(10,2),

    avg_consumption_per_hour NUMERIC(10,2),

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- ANOMALIES
-- =========================================================

CREATE TABLE anomalies (
    id BIGSERIAL PRIMARY KEY,

    equipment_id BIGINT
        REFERENCES equipment(id),

    anomaly_type VARCHAR(255),

    severity anomaly_severity_enum,

    description TEXT,

    detected_at TIMESTAMP DEFAULT NOW(),

    resolved BOOLEAN DEFAULT FALSE,

    resolved_at TIMESTAMP
);

-- =========================================================
-- AUDIT LOGS
-- =========================================================

CREATE TABLE audit_logs (
    id BIGSERIAL,

    user_id BIGINT
        REFERENCES users(id),

    entity_type VARCHAR(255),

    entity_id BIGINT,

    action VARCHAR(100),

    old_data JSONB,

    new_data JSONB,

    ip_address INET,

    user_agent TEXT,

    created_at TIMESTAMP DEFAULT NOW(),

    PRIMARY KEY(id, created_at)
)
PARTITION BY RANGE(created_at);

CREATE INDEX idx_audit_logs_created
ON audit_logs(created_at);

-- =========================================================
-- LOGIN HISTORY
-- =========================================================

CREATE TABLE login_history (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT
        REFERENCES users(id),

    ip_address INET,

    user_agent TEXT,

    login_at TIMESTAMP DEFAULT NOW(),

    success BOOLEAN
);

-- =========================================================
-- SYSTEM SETTINGS
-- =========================================================

CREATE TABLE system_settings (
    id BIGSERIAL PRIMARY KEY,

    key VARCHAR(255) UNIQUE NOT NULL,

    value TEXT,

    description TEXT,

    updated_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- SLA RULES
-- =========================================================

CREATE TABLE sla_rules (
    id BIGSERIAL PRIMARY KEY,

    name VARCHAR(255),

    task_type VARCHAR(100),

    max_response_minutes INTEGER,

    max_completion_minutes INTEGER,

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- ALERTS
-- =========================================================

CREATE TABLE alerts (
    id BIGSERIAL PRIMARY KEY,

    equipment_id BIGINT
        REFERENCES equipment(id),

    task_id BIGINT
        REFERENCES tasks(id),

    severity anomaly_severity_enum,

    title VARCHAR(255),

    description TEXT,

    is_resolved BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT NOW(),

    resolved_at TIMESTAMP
);

-- =========================================================
-- GEO FENCES
-- =========================================================

CREATE TABLE geofences (
    id BIGSERIAL PRIMARY KEY,

    equipment_id BIGINT
        REFERENCES equipment(id),

    radius_meters INTEGER DEFAULT 100,

    center GEOGRAPHY(POINT, 4326),

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- DEVICE SESSIONS
-- =========================================================

CREATE TABLE device_sessions (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT
        REFERENCES users(id),

    telegram_chat_id BIGINT,

    device_info TEXT,

    ip_address INET,

    last_activity_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- FILE STORAGE
-- =========================================================

CREATE TABLE files (
    id BIGSERIAL PRIMARY KEY,

    uuid UUID DEFAULT uuid_generate_v4(),

    original_name TEXT,

    storage_path TEXT NOT NULL,

    mime_type VARCHAR(255),

    file_size BIGINT,

    checksum VARCHAR(255),

    uploaded_by BIGINT
        REFERENCES users(id),

    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- MATERIALIZED VIEW
-- CURRENT EQUIPMENT STATUS
-- =========================================================

CREATE MATERIALIZED VIEW mv_equipment_status AS
SELECT
    e.id,
    e.name,
    e.current_fuel_level,
    e.current_hour_meter,
    e.status,
    et.avg_fuel_consumption_per_hour,
    CASE
        WHEN et.avg_fuel_consumption_per_hour > 0
        THEN e.current_fuel_level / et.avg_fuel_consumption_per_hour
        ELSE NULL
    END AS estimated_hours_left
FROM equipment e
JOIN equipment_types et
ON et.id = e.equipment_type_id;

-- =========================================================
-- REFRESH FUNCTION
-- =========================================================

CREATE OR REPLACE FUNCTION refresh_equipment_status()
RETURNS void AS
$$
BEGIN
    REFRESH MATERIALIZED VIEW mv_equipment_status;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- SAMPLE PARTITIONS
-- =========================================================

CREATE TABLE telemetry_2026_01
PARTITION OF telemetry
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE route_points_2026_01
PARTITION OF route_points
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE audit_logs_2026_01
PARTITION OF audit_logs
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

-- =========================================================
-- SECURITY INDEXES
-- =========================================================

CREATE INDEX idx_users_telegram_id
ON users(telegram_id);

CREATE INDEX idx_users_phone
ON users(phone);

CREATE INDEX idx_equipment_inventory_number
ON equipment(inventory_number);

CREATE INDEX idx_tasks_equipment
ON tasks(equipment_id);

CREATE INDEX idx_task_assignments_user
ON task_assignments(user_id);

CREATE INDEX idx_notifications_user
ON notifications(user_id);

-- =========================================================
-- COMMENTS
-- =========================================================

COMMENT ON TABLE audit_logs IS
'Immutable audit trail of all user actions';

COMMENT ON TABLE telemetry IS
'IoT and sensor telemetry data';

COMMENT ON TABLE fuel_operations IS
'Fuel refill operations and consumption tracking';

COMMENT ON TABLE maintenance_operations IS
'Maintenance and inspection operations';

COMMENT ON TABLE route_points IS
'GPS tracking points for operators';

-- =========================================================
-- END OF SCHEMA
-- =========================================================
