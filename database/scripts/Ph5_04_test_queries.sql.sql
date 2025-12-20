-- ============================================
-- PHASE V: PART 3 - VERIFICATION
-- File: 03_verification.sql
-- Run this LAST (after 02_insert_data.sql)
-- ============================================

-- A. BASIC ROW COUNTS
SELECT '=== BASIC ROW COUNTS ===' AS report FROM dual;

SELECT 'CROP_TYPES: ' || COUNT(*) || ' rows' AS table_count FROM crop_types
UNION ALL
SELECT 'GARDEN_ZONES: ' || COUNT(*) || ' rows' FROM garden_zones
UNION ALL
SELECT 'USERS: ' || COUNT(*) || ' rows' FROM users
UNION ALL
SELECT 'SENSOR_READINGS: ' || COUNT(*) || ' rows' FROM sensor_readings
UNION ALL
SELECT 'ALERTS: ' || COUNT(*) || ' rows' FROM alerts
UNION ALL
SELECT 'WATERING_TASKS: ' || COUNT(*) || ' rows' FROM watering_tasks
UNION ALL
SELECT 'AUDIT_LOG: ' || COUNT(*) || ' rows' FROM audit_log;

-- B. DATA INTEGRITY CHECKS
SELECT '' FROM dual;
SELECT '=== DATA INTEGRITY CHECKS ===' AS report FROM dual;

-- 1. Check for orphan records
SELECT 'Orphan garden zones (no crop type): ' || COUNT(*) AS issue_count
FROM garden_zones gz 
LEFT JOIN crop_types ct ON gz.crop_type_id = ct.crop_type_id
WHERE ct.crop_type_id IS NULL

UNION ALL

SELECT 'Orphan sensor readings (no zone): ' || COUNT(*)
FROM sensor_readings sr 
LEFT JOIN garden_zones gz ON sr.zone_id = gz.zone_id
WHERE gz.zone_id IS NULL

UNION ALL

SELECT 'Orphan alerts (no zone): ' || COUNT(*)
FROM alerts a 
LEFT JOIN garden_zones gz ON a.zone_id = gz.zone_id
WHERE gz.zone_id IS NULL

UNION ALL

SELECT 'Invalid alert resolver IDs: ' || COUNT(*)
FROM alerts a 
LEFT JOIN users u ON a.resolved_by = u.user_id
WHERE a.resolved_by IS NOT NULL AND u.user_id IS NULL;

-- 2. Check constraint violations
SELECT '=== CONSTRAINT VIOLATIONS ===' AS report FROM dual;

SELECT 'Invalid moisture values: ' || COUNT(*) AS violations
FROM sensor_readings 
WHERE moisture_level NOT BETWEEN 0 AND 100 AND moisture_level IS NOT NULL

UNION ALL

SELECT 'Invalid pH values: ' || COUNT(*)
FROM sensor_readings 
WHERE ph_level NOT BETWEEN 0 AND 14 AND ph_level IS NOT NULL

UNION ALL

SELECT 'Invalid user roles: ' || COUNT(*)
FROM users 
WHERE role NOT IN ('ADMIN', 'FARMER', 'VIEWER')

UNION ALL

SELECT 'Invalid zone status: ' || COUNT(*)
FROM garden_zones 
WHERE status NOT IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE');

-- C. SAMPLE DATA VIEW
SELECT '' FROM dual;
SELECT '=== SAMPLE DATA (First 5 rows each table) ===' AS report FROM dual;

SELECT 'CROP_TYPES:' AS table_name FROM dual;
SELECT * FROM crop_types;

SELECT 'GARDEN_ZONES:' AS table_name FROM dual;
SELECT * FROM garden_zones WHERE ROWNUM <= 5;

SELECT 'USERS:' AS table_name FROM dual;
SELECT user_id, username, full_name, role, status FROM users WHERE ROWNUM <= 5;

SELECT 'SENSOR_READINGS (latest 5):' AS table_name FROM dual;
SELECT * FROM (
    SELECT reading_id, zone_id, reading_timestamp, moisture_level, ph_level, temperature_c 
    FROM sensor_readings 
    ORDER BY reading_timestamp DESC
) WHERE ROWNUM <= 5;

SELECT 'ALERTS (latest 5):' AS table_name FROM dual;
SELECT * FROM (
    SELECT alert_id, zone_id, alert_type, priority, status, alert_timestamp 
    FROM alerts 
    ORDER BY alert_timestamp DESC
) WHERE ROWNUM <= 5;

SELECT 'WATERING_TASKS (upcoming 5):' AS table_name FROM dual;
SELECT * FROM (
    SELECT task_id, zone_id, scheduled_date, task_status, recommended_water_amt 
    FROM watering_tasks 
    WHERE scheduled_date >= TRUNC(SYSDATE)
    ORDER BY scheduled_date
) WHERE ROWNUM <= 5;

-- D. BUSINESS RULE TESTS
SELECT '' FROM dual;
SELECT '=== BUSINESS RULE TESTS ===' AS report FROM dual;

-- 1. Zones with readings outside ideal ranges
SELECT 'Zones with critical moisture issues: ' || COUNT(DISTINCT sr.zone_id) AS issue_count
FROM sensor_readings sr
JOIN garden_zones gz ON sr.zone_id = gz.zone_id
JOIN crop_types ct ON gz.crop_type_id = ct.crop_type_id
WHERE sr.moisture_level < ct.ideal_moisture_min - 10 
   OR sr.moisture_level > ct.ideal_moisture_max + 10

UNION ALL

-- 2. Overdue alerts
SELECT 'Open alerts older than 24 hours: ' || COUNT(*) 
FROM alerts 
WHERE status = 'OPEN' 
AND alert_timestamp < SYSTIMESTAMP - INTERVAL '1' DAY

UNION ALL

-- 3. Overdue watering tasks
SELECT 'Overdue watering tasks: ' || COUNT(*) 
FROM watering_tasks 
WHERE task_status IN ('PENDING', 'IN_PROGRESS')
AND scheduled_date < TRUNC(SYSDATE)

UNION ALL

-- 4. Sensor issues
SELECT 'Zones with sensor issues: ' || COUNT(DISTINCT zone_id) 
FROM sensor_readings 
WHERE sensor_status != 'OPERATIONAL';

-- E. SUMMARY STATISTICS
SELECT '' FROM dual;
SELECT '=== SUMMARY STATISTICS ===' AS report FROM dual;

SELECT 'Total water recommended (liters): ' || TO_CHAR(SUM(recommended_water_amt), '999,999.99') AS stat
FROM watering_tasks 
WHERE task_status = 'COMPLETED'

UNION ALL

SELECT 'Average moisture level: ' || TO_CHAR(AVG(moisture_level), '999.99') || '%'
FROM sensor_readings 
WHERE moisture_level IS NOT NULL

UNION ALL

SELECT 'Active zones: ' || COUNT(*) 
FROM garden_zones 
WHERE status = 'ACTIVE'

UNION ALL

SELECT 'Active farmers: ' || COUNT(*) 
FROM users 
WHERE role = 'FARMER' AND status = 'ACTIVE'

UNION ALL

SELECT 'Resolved alerts: ' || COUNT(*) 
FROM alerts 
WHERE status = 'RESOLVED';