-- ============================================
-- PHASE V: PART 2 - DATA INSERTION
-- File: 02_insert_data.sql
-- Run this SECOND (after 01_create_tables.sql)
-- ============================================

-- 1. INSERT CROP_TYPES (10 crops)
INSERT INTO crop_types (crop_type_id, crop_name, ideal_moisture_min, 
                       ideal_moisture_max, ideal_ph_min, ideal_ph_max, 
                       water_req_mm) VALUES
(seq_crop_type.NEXTVAL, 'Tomato', 60.0, 80.0, 6.0, 6.8, 25.0);
INSERT INTO crop_types VALUES (seq_crop_type.NEXTVAL, 'Lettuce', 70.0, 85.0, 6.0, 7.0, 20.0);
INSERT INTO crop_types VALUES (seq_crop_type.NEXTVAL, 'Carrot', 65.0, 75.0, 5.5, 7.0, 22.0);
INSERT INTO crop_types VALUES (seq_crop_type.NEXTVAL, 'Potato', 60.0, 70.0, 5.0, 6.5, 28.0);
INSERT INTO crop_types VALUES (seq_crop_type.NEXTVAL, 'Cucumber', 75.0, 85.0, 5.5, 7.0, 30.0);
INSERT INTO crop_types VALUES (seq_crop_type.NEXTVAL, 'Bell Pepper', 65.0, 75.0, 6.0, 6.8, 24.0);
INSERT INTO crop_types VALUES (seq_crop_type.NEXTVAL, 'Strawberry', 70.0, 80.0, 5.5, 6.5, 26.0);
INSERT INTO crop_types VALUES (seq_crop_type.NEXTVAL, 'Spinach', 75.0, 85.0, 6.5, 7.5, 23.0);
INSERT INTO crop_types VALUES (seq_crop_type.NEXTVAL, 'Corn', 60.0, 70.0, 5.8, 7.0, 35.0);
INSERT INTO crop_types VALUES (seq_crop_type.NEXTVAL, 'Green Beans', 65.0, 75.0, 6.0, 7.5, 21.0);

-- 2. INSERT USERS (15 users)
INSERT INTO users (user_id, username, full_name, role, email, status) VALUES
(seq_user_id.NEXTVAL, 'admin_aime', 'Aime Bouckamba', 'ADMIN', 'aime.bouckamba@irrigation.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'farmer_john', 'John Kamanzi', 'FARMER', 'john.k@farm.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'farmer_marie', 'Marie Uwase', 'FARMER', 'marie.u@farm.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'viewer_tech', 'Technical Viewer', 'VIEWER', 'tech@irrigation.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'farmer_paul', 'Paul Mugisha', 'FARMER', 'paul.m@farm.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'admin_sys', 'System Admin', 'ADMIN', 'sysadmin@irrigation.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'farmer_sarah', 'Sarah Iradukunda', 'FARMER', NULL, 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'viewer_audit', 'Audit Viewer', 'VIEWER', 'audit@irrigation.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'farmer_david', 'David Niyonkuru', 'FARMER', 'david.n@farm.rw', 'INACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'farmer_anna', 'Anna Mukamana', 'FARMER', 'anna.m@farm.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'farmer_peter', 'Peter Habimana', 'FARMER', NULL, 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'viewer_guest', 'Guest User', 'VIEWER', 'guest@irrigation.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'farmer_mark', 'Mark Twagirimana', 'FARMER', 'mark.t@farm.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'farmer_grace', 'Grace Uwimana', 'FARMER', 'grace.u@farm.rw', 'ACTIVE');
INSERT INTO users VALUES (seq_user_id.NEXTVAL, 'admin_backup', 'Backup Admin', 'ADMIN', 'backup@irrigation.rw', 'ACTIVE');

-- 3. INSERT GARDEN_ZONES (20 zones)
INSERT INTO garden_zones (zone_id, zone_name, crop_type_id, area_sqft, soil_type, status) VALUES
(seq_zone_id.NEXTVAL, 'Tomato Bed A', 100, 120.5, 'LOAM', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Tomato Bed B', 100, 110.0, 'SANDY LOAM', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Lettuce Patch 1', 101, 80.0, 'CLAY', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Lettuce Patch 2', 101, 75.5, 'LOAM', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Carrot Field', 102, 200.0, 'SANDY', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Potato Zone 1', 103, 150.0, 'LOAM', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Cucumber Trellis', 104, 90.0, 'SILT', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Bell Pepper Area', 105, 100.0, 'LOAM', 'MAINTENANCE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Strawberry Rows', 106, 130.0, 'ACIDIC', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Spinach Corner', 107, 70.0, 'CLAY LOAM', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Corn Field A', 108, 300.0, 'LOAM', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Corn Field B', 108, 280.0, 'SANDY LOAM', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Green Beans Plot', 109, 95.0, 'LOAM', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Mixed Vegetables', 100, 85.0, 'LOAM', 'INACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Tomato Greenhouse', 100, 200.0, 'POTTING MIX', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Lettuce Hydroponics', 101, 50.0, 'HYDROPONIC', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Experimental Zone', 102, 60.0, 'VARIABLE', 'MAINTENANCE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Herb Garden', 105, 40.0, 'LOAM', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Seedling Area', 103, 30.0, 'SEED STARTING', 'ACTIVE');
INSERT INTO garden_zones VALUES (seq_zone_id.NEXTVAL, 'Compost Test Zone', 106, 25.0, 'COMPOST', 'ACTIVE');

-- 4. INSERT SENSOR_READINGS (50+ readings)
INSERT INTO sensor_readings (reading_id, zone_id, moisture_level, ph_level, temperature_c) VALUES
(seq_reading_id.NEXTVAL, 1, 65.5, 6.2, 22.5);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 2, 68.0, 6.3, 23.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 3, 72.5, 6.8, 21.5);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 4, 70.0, 6.5, 22.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 5, 62.0, 6.0, 24.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 6, 58.5, 5.8, 23.5);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 7, 78.0, 5.9, 25.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 8, 50.0, 6.1, 22.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 9, 75.5, 5.7, 21.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 10, 80.0, 7.2, 22.5);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 1, 60.0, 6.2, 28.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 2, 62.5, 6.3, 29.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 3, 67.0, 6.8, 27.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 4, 65.0, 6.5, 28.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 5, 55.0, 6.0, 30.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 6, 52.0, 5.8, 29.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 7, 72.0, 5.9, 31.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 8, 45.0, 6.1, 28.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 9, 70.0, 5.7, 27.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 10, 75.0, 7.2, 28.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 1, NULL, 6.2, 22.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 3, 72.5, NULL, 21.5);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 5, 62.0, 6.0, NULL);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 8, 85.0, 4.5, 22.0);
INSERT INTO sensor_readings VALUES (seq_reading_id.NEXTVAL, 9, 40.0, 5.7, 21.0);

-- Add 25 more random readings
BEGIN
    FOR i IN 1..25 LOOP
        INSERT INTO sensor_readings (reading_id, zone_id, moisture_level, ph_level, temperature_c) 
        VALUES (
            seq_reading_id.NEXTVAL,
            MOD(i, 15) + 1,
            ROUND(DBMS_RANDOM.VALUE(40, 85), 1),
            ROUND(DBMS_RANDOM.VALUE(5.0, 7.5), 1),
            ROUND(DBMS_RANDOM.VALUE(18, 32), 1)
        );
    END LOOP;
END;
/

-- 5. INSERT ALERTS (30+ alerts)
INSERT INTO alerts (alert_id, zone_id, alert_type, alert_message, priority, status, resolved_by) VALUES
(seq_alert_id.NEXTVAL, 5, 'LOW_MOISTURE', 'Zone 5 (Carrot Field) moisture at 55% - below minimum threshold', 'MEDIUM', 'OPEN', NULL);
INSERT INTO alerts VALUES (seq_alert_id.NEXTVAL, 8, 'CRITICAL_PH', 'Zone 8 (Bell Pepper Area) pH at 4.5 - critically acidic!', 'HIGH', 'OPEN', NULL);
INSERT INTO alerts VALUES (seq_alert_id.NEXTVAL, 9, 'LOW_MOISTURE', 'Zone 9 (Strawberry Rows) moisture at 40% - plants under stress', 'HIGH', 'RESOLVED', 1002);
INSERT INTO alerts VALUES (seq_alert_id.NEXTVAL, 1, 'SENSOR_FAILURE', 'Moisture sensor in Zone 1 (Tomato Bed A) reporting NULL values', 'MEDIUM', 'ACKNOWLEDGED', 1001);
INSERT INTO alerts VALUES (seq_alert_id.NEXTVAL, 3, 'SENSOR_FAILURE', 'pH sensor in Zone 3 (Lettuce Patch 1) offline', 'MEDIUM', 'OPEN', NULL);
INSERT INTO alerts VALUES (seq_alert_id.NEXTVAL, 8, 'HIGH_MOISTURE', 'Zone 8 moisture at 85% - risk of root rot', 'HIGH', 'OPEN', NULL);
INSERT INTO alerts VALUES (seq_alert_id.NEXTVAL, 11, 'TEMP_EXTREME', 'Zone 11 (Corn Field A) temperature at 35°C - heat stress risk', 'MEDIUM', 'RESOLVED', 1003);
INSERT INTO alerts VALUES (seq_alert_id.NEXTVAL, 5, 'LOW_MOISTURE', 'Zone 5 moisture at 52% - irrigation needed', 'MEDIUM', 'RESOLVED', 1002);
INSERT INTO alerts VALUES (seq_alert_id.NEXTVAL, 2, 'HIGH_MOISTURE', 'Zone 2 (Tomato Bed B) moisture at 88% - overwatered', 'LOW', 'OPEN', NULL);
INSERT INTO alerts VALUES (seq_alert_id.NEXTVAL, 6, 'SENSOR_FAILURE', 'Temperature sensor fluctuation in Zone 6', 'LOW', 'ACKNOWLEDGED', 1001);

-- Add 20 more alerts
BEGIN
    FOR i IN 1..20 LOOP
        DECLARE
            v_zone NUMBER := MOD(i, 15) + 1;
            v_alert_type VARCHAR2(30);
            v_message VARCHAR2(500);
            v_priority VARCHAR2(20);
            v_status VARCHAR2(20);
            v_resolved NUMBER;
        BEGIN
            CASE MOD(i, 5)
                WHEN 0 THEN v_alert_type := 'CRITICAL_PH'; v_priority := 'HIGH';
                WHEN 1 THEN v_alert_type := 'LOW_MOISTURE'; v_priority := 'MEDIUM';
                WHEN 2 THEN v_alert_type := 'HIGH_MOISTURE'; v_priority := 'MEDIUM';
                WHEN 3 THEN v_alert_type := 'SENSOR_FAILURE'; v_priority := 'LOW';
                WHEN 4 THEN v_alert_type := 'TEMP_EXTREME'; v_priority := 'MEDIUM';
            END CASE;
            
            v_message := 'Alert for Zone ' || v_zone || ': ' || v_alert_type || ' detected';
            
            CASE MOD(i, 4)
                WHEN 0 THEN v_status := 'OPEN'; v_resolved := NULL;
                WHEN 1 THEN v_status := 'ACKNOWLEDGED'; v_resolved := 1001;
                WHEN 2 THEN v_status := 'RESOLVED'; v_resolved := 1002;
                WHEN 3 THEN v_status := 'RESOLVED'; v_resolved := 1003;
            END CASE;
            
            INSERT INTO alerts (alert_id, zone_id, alert_type, alert_message, priority, status, resolved_by)
            VALUES (seq_alert_id.NEXTVAL, v_zone, v_alert_type, v_message, v_priority, v_status, v_resolved);
        END;
    END LOOP;
END;
/

-- 6. INSERT WATERING_TASKS (50+ tasks)
INSERT INTO watering_tasks (task_id, zone_id, scheduled_date, recommended_water_amt, task_status, completed_by) VALUES
(seq_task_id.NEXTVAL, 5, SYSDATE - 2, 45.5, 'COMPLETED', 1002);
INSERT INTO watering_tasks VALUES (seq_task_id.NEXTVAL, 9, SYSDATE - 1, 38.0, 'COMPLETED', 1003);
INSERT INTO watering_tasks VALUES (seq_task_id.NEXTVAL, 1, SYSDATE, 25.0, 'PENDING', NULL);
INSERT INTO watering_tasks VALUES (seq_task_id.NEXTVAL, 2, SYSDATE, 23.5, 'PENDING', NULL);
INSERT INTO watering_tasks VALUES (seq_task_id.NEXTVAL, 3, SYSDATE, 20.0, 'IN_PROGRESS', 1002);
INSERT INTO watering_tasks VALUES (seq_task_id.NEXTVAL, 8, SYSDATE, 15.0, 'CANCELLED', NULL);
INSERT INTO watering_tasks VALUES (seq_task_id.NEXTVAL, 11, SYSDATE + 1, 75.0, 'PENDING', NULL);
INSERT INTO watering_tasks VALUES (seq_task_id.NEXTVAL, 12, SYSDATE + 1, 70.5, 'PENDING', NULL);
INSERT INTO watering_tasks VALUES (seq_task_id.NEXTVAL, 5, SYSDATE + 1, 42.0, 'PENDING', NULL);
INSERT INTO watering_tasks VALUES (seq_task_id.NEXTVAL, 6, SYSDATE - 3, 35.0, 'COMPLETED', 1003);

-- Add 40 more tasks
BEGIN
    FOR i IN 1..40 LOOP
        DECLARE
            v_zone NUMBER := MOD(i, 15) + 1;
            v_date DATE := SYSDATE - 7 + MOD(i, 14);
            v_status VARCHAR2(20);
            v_completed NUMBER;
            v_water NUMBER := ROUND(DBMS_RANDOM.VALUE(10, 100), 1);
        BEGIN
            IF v_date < SYSDATE - 1 THEN
                v_status := 'COMPLETED';
                v_completed := CASE MOD(i, 3) WHEN 0 THEN 1002 WHEN 1 THEN 1003 ELSE 1004 END;
            ELSIF v_date = SYSDATE THEN
                v_status := CASE MOD(i, 3) WHEN 0 THEN 'PENDING' WHEN 1 THEN 'IN_PROGRESS' ELSE 'PENDING' END;
                v_completed := CASE WHEN v_status = 'IN_PROGRESS' THEN 1002 ELSE NULL END;
            ELSIF v_date > SYSDATE THEN
                v_status := 'PENDING';
                v_completed := NULL;
            END IF;
            
            INSERT INTO watering_tasks (task_id, zone_id, scheduled_date, recommended_water_amt, task_status, completed_by)
            VALUES (seq_task_id.NEXTVAL, v_zone, v_date, v_water, v_status, v_completed);
        END;
    END LOOP;
END;
/

-- 7. INSERT AUDIT_LOG (Sample entries)
INSERT INTO audit_log (audit_id, table_name, column_name, old_value, new_value, change_type, changed_by) VALUES
(seq_audit_id.NEXTVAL, 'USERS', 'STATUS', 'ACTIVE', 'INACTIVE', 'UPDATE', 'admin_aime');
INSERT INTO audit_log VALUES (seq_audit_id.NEXTVAL, 'GARDEN_ZONES', NULL, NULL, 'Zone added', 'INSERT', 'farmer_john');
INSERT INTO audit_log VALUES (seq_audit_id.NEXTVAL, 'ALERTS', 'STATUS', 'OPEN', 'RESOLVED', 'UPDATE', 'farmer_marie');
INSERT INTO audit_log VALUES (seq_audit_id.NEXTVAL, 'CROP_TYPES', 'WATER_REQ_MM', '25.0', '26.0', 'UPDATE', 'admin_aime');
INSERT INTO audit_log VALUES (seq_audit_id.NEXTVAL, 'WATERING_TASKS', 'TASK_STATUS', 'PENDING', 'CANCELLED', 'UPDATE', 'system');

COMMIT;

SELECT 'Data inserted successfully' AS status FROM dual;