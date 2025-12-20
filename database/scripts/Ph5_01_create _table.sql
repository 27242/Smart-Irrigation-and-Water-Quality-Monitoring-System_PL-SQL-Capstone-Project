-- ============================================
-- PHASE V: PART 1 - TABLE CREATION
-- File: 01_create_tables.sql
-- Run this FIRST
-- ============================================

-- Connect as: irrigation_app
-- Password: aime2024

-- 1. CROP_TYPES Table (Master Data)
CREATE TABLE crop_types (
    crop_type_id      NUMBER(10)    PRIMARY KEY,
    crop_name         VARCHAR2(100) NOT NULL UNIQUE,
    ideal_moisture_min NUMBER(5,2)  NOT NULL,
    ideal_moisture_max NUMBER(5,2)  NOT NULL,
    ideal_ph_min      NUMBER(3,1)   NOT NULL,
    ideal_ph_max      NUMBER(3,1)   NOT NULL,
    water_req_mm      NUMBER(5,2),
    created_date      DATE          DEFAULT SYSDATE,
    
    CONSTRAINT ck_moisture_range CHECK (ideal_moisture_min BETWEEN 0 AND 100 
                                       AND ideal_moisture_max BETWEEN 0 AND 100
                                       AND ideal_moisture_min < ideal_moisture_max),
    CONSTRAINT ck_ph_range CHECK (ideal_ph_min BETWEEN 0 AND 14 
                                 AND ideal_ph_max BETWEEN 0 AND 14
                                 AND ideal_ph_min < ideal_ph_max)
);

-- 2. GARDEN_ZONES Table
CREATE TABLE garden_zones (
    zone_id          NUMBER(10)    PRIMARY KEY,
    zone_name        VARCHAR2(100) NOT NULL,
    crop_type_id     NUMBER(10)    NOT NULL,
    area_sqft        NUMBER(8,2)   NOT NULL,
    soil_type        VARCHAR2(50)  DEFAULT 'LOAM',
    date_created     DATE          DEFAULT SYSDATE,
    status           VARCHAR2(20)  DEFAULT 'ACTIVE',
    
    CONSTRAINT fk_garden_crop FOREIGN KEY (crop_type_id)
        REFERENCES crop_types(crop_type_id),
    CONSTRAINT ck_area_positive CHECK (area_sqft > 0),
    CONSTRAINT ck_valid_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE'))
);

-- 3. USERS Table
CREATE TABLE users (
    user_id          NUMBER(10)    PRIMARY KEY,
    username         VARCHAR2(50)  NOT NULL UNIQUE,
    full_name        VARCHAR2(100) NOT NULL,
    role             VARCHAR2(30)  DEFAULT 'FARMER',
    email            VARCHAR2(100),
    date_registered  DATE          DEFAULT SYSDATE,
    status           VARCHAR2(20)  DEFAULT 'ACTIVE',
    
    CONSTRAINT ck_valid_role CHECK (role IN ('ADMIN', 'FARMER', 'VIEWER')),
    CONSTRAINT ck_valid_user_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_email_format CHECK (email LIKE '%@%.%' OR email IS NULL)
);

-- 4. SENSOR_READINGS Table
CREATE TABLE sensor_readings (
    reading_id       NUMBER(15)    PRIMARY KEY,
    zone_id          NUMBER(10)    NOT NULL,
    reading_timestamp TIMESTAMP    DEFAULT SYSTIMESTAMP,
    moisture_level   NUMBER(5,2),
    ph_level         NUMBER(3,1),
    temperature_c    NUMBER(4,1),
    sensor_status    VARCHAR2(20)  DEFAULT 'OPERATIONAL',
    
    CONSTRAINT fk_sensor_zone FOREIGN KEY (zone_id)
        REFERENCES garden_zones(zone_id),
    CONSTRAINT ck_moisture CHECK (moisture_level BETWEEN 0 AND 100 
                                 OR moisture_level IS NULL),
    CONSTRAINT ck_ph CHECK (ph_level BETWEEN 0 AND 14 OR ph_level IS NULL),
    CONSTRAINT ck_sensor_status CHECK (sensor_status IN 
        ('OPERATIONAL', 'FAULTY', 'CALIBRATING', 'OFFLINE'))
);

-- 5. ALERTS Table
CREATE TABLE alerts (
    alert_id          NUMBER(10)    PRIMARY KEY,
    zone_id           NUMBER(10)    NOT NULL,
    alert_timestamp   TIMESTAMP     DEFAULT SYSTIMESTAMP,
    alert_type        VARCHAR2(30)  NOT NULL,
    alert_message     VARCHAR2(500) NOT NULL,
    priority          VARCHAR2(20)  DEFAULT 'MEDIUM',
    status            VARCHAR2(20)  DEFAULT 'OPEN',
    resolved_by       NUMBER(10),
    resolution_notes  VARCHAR2(1000),
    
    CONSTRAINT fk_alert_zone FOREIGN KEY (zone_id)
        REFERENCES garden_zones(zone_id),
    CONSTRAINT fk_alert_resolved FOREIGN KEY (resolved_by)
        REFERENCES users(user_id),
    CONSTRAINT ck_alert_type CHECK (alert_type IN 
        ('CRITICAL_PH', 'LOW_MOISTURE', 'HIGH_MOISTURE', 
         'SENSOR_FAILURE', 'TEMP_EXTREME')),
    CONSTRAINT ck_priority CHECK (priority IN ('HIGH', 'MEDIUM', 'LOW')),
    CONSTRAINT ck_alert_status CHECK (status IN 
        ('OPEN', 'ACKNOWLEDGED', 'RESOLVED'))
);

-- 6. WATERING_TASKS Table
CREATE TABLE watering_tasks (
    task_id               NUMBER(10)    PRIMARY KEY,
    zone_id               NUMBER(10)    NOT NULL,
    scheduled_date        DATE          NOT NULL,
    recommended_water_amt NUMBER(8,2),
    actual_water_used     NUMBER(8,2),
    task_status           VARCHAR2(20)  DEFAULT 'PENDING',
    completed_by          NUMBER(10),
    completion_timestamp  TIMESTAMP,
    notes                 VARCHAR2(500),
    
    CONSTRAINT fk_task_zone FOREIGN KEY (zone_id)
        REFERENCES garden_zones(zone_id),
    CONSTRAINT fk_task_completed FOREIGN KEY (completed_by)
        REFERENCES users(user_id),
    CONSTRAINT ck_task_status CHECK (task_status IN 
        ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT ck_water_amounts CHECK (
        (recommended_water_amt IS NULL OR recommended_water_amt > 0) AND
        (actual_water_used IS NULL OR actual_water_used > 0)
    )
);

-- 7. AUDIT_LOG Table
CREATE TABLE audit_log (
    audit_id          NUMBER(15)    PRIMARY KEY,
    table_name        VARCHAR2(50)  NOT NULL,
    column_name       VARCHAR2(50),
    old_value         VARCHAR2(4000),
    new_value         VARCHAR2(4000),
    change_type       VARCHAR2(10)  NOT NULL,
    changed_by        VARCHAR2(100),
    change_timestamp  TIMESTAMP     DEFAULT SYSTIMESTAMP,
    
    CONSTRAINT ck_change_type CHECK (change_type IN 
        ('INSERT', 'UPDATE', 'DELETE'))
);

-- ============================================
-- INDEXES for Performance
-- ============================================

-- Foreign key indexes
CREATE INDEX idx_garden_crop ON garden_zones(crop_type_id);
CREATE INDEX idx_sensor_zone ON sensor_readings(zone_id);
CREATE INDEX idx_alert_zone ON alerts(zone_id);
CREATE INDEX idx_alert_resolved ON alerts(resolved_by);
CREATE INDEX idx_task_zone ON watering_tasks(zone_id);
CREATE INDEX idx_task_completed ON watering_tasks(completed_by);

-- Query performance indexes
CREATE INDEX idx_sensor_time ON sensor_readings(reading_timestamp);
CREATE INDEX idx_alert_time ON alerts(alert_timestamp);
CREATE INDEX idx_task_date ON watering_tasks(scheduled_date);
CREATE INDEX idx_alert_priority ON alerts(priority, status);
CREATE INDEX idx_task_status ON watering_tasks(task_status);
CREATE INDEX idx_user_role ON users(role, status);

-- Composite indexes for common queries
CREATE INDEX idx_zone_sensor ON sensor_readings(zone_id, reading_timestamp);
CREATE INDEX idx_zone_alert ON alerts(zone_id, alert_timestamp);
CREATE INDEX idx_zone_task ON watering_tasks(zone_id, scheduled_date);
CREATE INDEX idx_audit_table ON audit_log(table_name, change_timestamp);

-- ============================================
-- SEQUENCES for Primary Keys
-- ============================================

CREATE SEQUENCE seq_crop_type START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE seq_zone_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_user_id START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE seq_reading_id START WITH 100000 INCREMENT BY 1;
CREATE SEQUENCE seq_alert_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_task_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_id START WITH 1 INCREMENT BY 1;

COMMIT;

-- Verify tables were created
SELECT 'Tables created successfully' AS status FROM dual;
SELECT table_name FROM user_tables ORDER BY table_name;