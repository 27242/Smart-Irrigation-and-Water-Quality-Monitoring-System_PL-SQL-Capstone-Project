-- ============================================
-- PHASE VI: PART 3 - CURSORS & WINDOW FUNCTIONS
-- File: 03_cursors_window.sql
-- ============================================

-- Example 1: Explicit cursor for processing zones
CREATE OR REPLACE PROCEDURE sp_process_zones_with_cursor
IS
    CURSOR cur_active_zones IS
        SELECT zone_id, zone_name, area_sqft, status
        FROM garden_zones
        WHERE status = 'ACTIVE'
        ORDER BY zone_id;
    
    v_zone_id NUMBER;
    v_zone_name VARCHAR2(100);
    v_area_sqft NUMBER;
    v_status VARCHAR2(20);
    v_zone_count NUMBER := 0;
    v_total_area NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Processing active zones...');
    
    OPEN cur_active_zones;
    
    LOOP
        FETCH cur_active_zones INTO v_zone_id, v_zone_name, v_area_sqft, v_status;
        EXIT WHEN cur_active_zones%NOTFOUND;
        
        v_zone_count := v_zone_count + 1;
        v_total_area := v_total_area + v_area_sqft;
        
        -- Process each zone
        DBMS_OUTPUT.PUT_LINE('  Zone ' || v_zone_id || ': ' || v_zone_name || 
                           ' (' || v_area_sqft || ' sqft)');
        
        -- Could add more processing here
    END LOOP;
    
    CLOSE cur_active_zones;
    
    DBMS_OUTPUT.PUT_LINE('Total active zones: ' || v_zone_count);
    DBMS_OUTPUT.PUT_LINE('Total area: ' || v_total_area || ' sqft');
    
EXCEPTION
    WHEN OTHERS THEN
        IF cur_active_zones%ISOPEN THEN
            CLOSE cur_active_zones;
        END IF;
        RAISE;
END sp_process_zones_with_cursor;
/

-- Example 2: Cursor with parameters
CREATE OR REPLACE PROCEDURE sp_get_zone_readings(
    p_zone_id IN NUMBER,
    p_hours_back IN NUMBER DEFAULT 24
)
IS
    CURSOR cur_readings IS
        SELECT reading_id, reading_timestamp, moisture_level, ph_level, temperature_c
        FROM sensor_readings
        WHERE zone_id = p_zone_id
          AND reading_timestamp > SYSTIMESTAMP - (p_hours_back/24)
        ORDER BY reading_timestamp DESC;
    
    v_reading_id NUMBER;
    v_timestamp TIMESTAMP;
    v_moisture NUMBER;
    v_ph NUMBER;
    v_temp NUMBER;
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Readings for zone ' || p_zone_id || ' (last ' || p_hours_back || ' hours):');
    
    OPEN cur_readings;
    
    LOOP
        FETCH cur_readings INTO v_reading_id, v_timestamp, v_moisture, v_ph, v_temp;
        EXIT WHEN cur_readings%NOTFOUND;
        
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE('  ' || TO_CHAR(v_timestamp, 'HH24:MI') || 
                           ' - Moisture: ' || NVL(TO_CHAR(v_moisture), 'NULL') || 
                           '%, pH: ' || NVL(TO_CHAR(v_ph), 'NULL') ||
                           ', Temp: ' || NVL(TO_CHAR(v_temp), 'NULL') || '°C');
    END LOOP;
    
    CLOSE cur_readings;
    
    DBMS_OUTPUT.PUT_LINE('Total readings: ' || v_count);
    
EXCEPTION
    WHEN OTHERS THEN
        IF cur_readings%ISOPEN THEN
            CLOSE cur_readings;
        END IF;
        RAISE;
END sp_get_zone_readings;
/

-- Example 3: Bulk collect with cursor (for optimization)
CREATE OR REPLACE PROCEDURE sp_bulk_process_alerts
IS
    CURSOR cur_open_alerts IS
        SELECT alert_id, zone_id, alert_type, alert_message, priority
        FROM alerts
        WHERE status = 'OPEN'
        ORDER BY priority DESC, alert_timestamp;
    
    TYPE alert_table_type IS TABLE OF cur_open_alerts%ROWTYPE;
    v_alerts alert_table_type;
    v_high_priority_count NUMBER := 0;
    v_medium_priority_count NUMBER := 0;
    v_low_priority_count NUMBER := 0;
BEGIN
    OPEN cur_open_alerts;
    
    -- Fetch all rows at once (bulk operation)
    FETCH cur_open_alerts BULK COLLECT INTO v_alerts;
    
    CLOSE cur_open_alerts;
    
    DBMS_OUTPUT.PUT_LINE('Processing ' || v_alerts.COUNT || ' open alerts...');
    
    -- Process in bulk
    FOR i IN 1..v_alerts.COUNT LOOP
        CASE v_alerts(i).priority
            WHEN 'HIGH' THEN
                v_high_priority_count := v_high_priority_count + 1;
                DBMS_OUTPUT.PUT_LINE('  [HIGH] Zone ' || v_alerts(i).zone_id || 
                                   ': ' || v_alerts(i).alert_type);
            WHEN 'MEDIUM' THEN
                v_medium_priority_count := v_medium_priority_count + 1;
            WHEN 'LOW' THEN
                v_low_priority_count := v_low_priority_count + 1;
        END CASE;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Priority breakdown:');
    DBMS_OUTPUT.PUT_LINE('  HIGH: ' || v_high_priority_count);
    DBMS_OUTPUT.PUT_LINE('  MEDIUM: ' || v_medium_priority_count);
    DBMS_OUTPUT.PUT_LINE('  LOW: ' || v_low_priority_count);
    
END sp_bulk_process_alerts;
/

-- Example 4: Window Functions examples
CREATE OR REPLACE PROCEDURE sp_demonstrate_window_functions
IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== WINDOW FUNCTION EXAMPLES ===');
    
    -- Example 1: ROW_NUMBER() - Latest reading per zone
    DBMS_OUTPUT.PUT_LINE('1. Latest reading per zone (using ROW_NUMBER):');
    FOR rec IN (
        SELECT zone_id, reading_timestamp, moisture_level, ph_level,
               ROW_NUMBER() OVER (PARTITION BY zone_id ORDER BY reading_timestamp DESC) as rn
        FROM sensor_readings
        WHERE zone_id IN (1, 2, 3)
    ) LOOP
        IF rec.rn = 1 THEN
            DBMS_OUTPUT.PUT_LINE('   Zone ' || rec.zone_id || ': ' || 
                               TO_CHAR(rec.reading_timestamp, 'DD-MON HH24:MI') ||
                               ' - Moisture: ' || rec.moisture_level || '%');
        END IF;
    END LOOP;
    
    -- Example 2: RANK() - Zones by average moisture
    DBMS_OUTPUT.PUT_LINE('2. Zones ranked by average moisture:');
    FOR rec IN (
        SELECT zone_id, 
               AVG(moisture_level) as avg_moisture,
               RANK() OVER (ORDER BY AVG(moisture_level) DESC) as moisture_rank
        FROM sensor_readings
        WHERE moisture_level IS NOT NULL
          AND reading_timestamp > SYSTIMESTAMP - INTERVAL '7' DAY
        GROUP BY zone_id
        HAVING COUNT(*) > 5
        ORDER BY avg_moisture DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('   Rank ' || rec.moisture_rank || 
                           ': Zone ' || rec.zone_id || 
                           ' - ' || ROUND(rec.avg_moisture, 1) || '%');
    END LOOP;
    
    -- Example 3: LAG() - Compare with previous reading
    DBMS_OUTPUT.PUT_LINE('3. Moisture change from previous reading (Zone 1):');
    FOR rec IN (
        SELECT reading_timestamp, moisture_level,
               LAG(moisture_level) OVER (ORDER BY reading_timestamp) as prev_moisture,
               moisture_level - LAG(moisture_level) OVER (ORDER BY reading_timestamp) as change
        FROM sensor_readings
        WHERE zone_id = 1
          AND moisture_level IS NOT NULL
          AND reading_timestamp > SYSDATE - 1
        ORDER BY reading_timestamp
    ) LOOP
        IF rec.prev_moisture IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   ' || TO_CHAR(rec.reading_timestamp, 'HH24:MI') ||
                               ': ' || rec.moisture_level || '% (change: ' || 
                               ROUND(rec.change, 1) || '%)');
        END IF;
    END LOOP;
    
    -- Example 4: Aggregation with OVER clause
    DBMS_OUTPUT.PUT_LINE('4. Running total of water used:');
    FOR rec IN (
        SELECT task_id, zone_id, actual_water_used,
               SUM(actual_water_used) OVER (ORDER BY completion_timestamp) as running_total,
               AVG(actual_water_used) OVER () as overall_avg
        FROM watering_tasks
        WHERE actual_water_used IS NOT NULL
          AND completion_timestamp > SYSDATE - 30
        ORDER BY completion_timestamp
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('   Task ' || rec.task_id || 
                           ': ' || rec.actual_water_used || 'L ' ||
                           '(Running total: ' || ROUND(rec.running_total, 1) || 'L)');
    END LOOP;
    
END sp_demonstrate_window_functions;
/

-- Test cursor and window functions
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== CURSOR & WINDOW FUNCTION TESTS ===');
    sp_process_zones_with_cursor;
    DBMS_OUTPUT.PUT_LINE('---');
    sp_get_zone_readings(1, 12);
    DBMS_OUTPUT.PUT_LINE('---');
    sp_bulk_process_alerts;
    DBMS_OUTPUT.PUT_LINE('---');
    sp_demonstrate_window_functions;
END;
/