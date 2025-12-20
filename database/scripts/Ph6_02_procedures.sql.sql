-- ============================================
-- PHASE VI: PART 2 - PROCEDURES
-- File: 02_procedures.sql
-- ============================================

-- PROCEDURE 1: Add new sensor reading with validation
CREATE OR REPLACE PROCEDURE sp_add_sensor_reading(
    p_zone_id IN NUMBER,
    p_moisture IN NUMBER,
    p_ph IN NUMBER,
    p_temperature IN NUMBER,
    p_sensor_status IN VARCHAR2 DEFAULT 'OPERATIONAL',
    p_reading_id OUT NUMBER,
    p_status OUT VARCHAR2
)
IS
    v_validation_result VARCHAR2(100);
    v_zone_exists NUMBER;
BEGIN
    p_status := 'SUCCESS';
    
    -- Check if zone exists
    SELECT COUNT(*) INTO v_zone_exists 
    FROM garden_zones 
    WHERE zone_id = p_zone_id;
    
    IF v_zone_exists = 0 THEN
        p_status := 'ERROR: Zone does not exist';
        RETURN;
    END IF;
    
    -- Validate sensor reading
    v_validation_result := fn_validate_sensor_reading(p_moisture, p_ph, p_temperature);
    
    IF v_validation_result != 'VALID' THEN
        p_status := 'ERROR: ' || v_validation_result;
        
        -- Still insert but mark as faulty
        INSERT INTO sensor_readings (
            reading_id, zone_id, moisture_level, 
            ph_level, temperature_c, sensor_status
        ) VALUES (
            seq_reading_id.NEXTVAL, p_zone_id, p_moisture,
            p_ph, p_temperature, 'FAULTY'
        )
        RETURNING reading_id INTO p_reading_id;
        
        -- Log the invalid reading
        INSERT INTO audit_log (audit_id, table_name, change_type, changed_by, old_value, new_value)
        VALUES (seq_audit_id.NEXTVAL, 'SENSOR_READINGS', 'INSERT', 'SYSTEM', 
                NULL, 'Invalid reading: ' || v_validation_result);
        RETURN;
    END IF;
    
    -- Insert valid reading
    INSERT INTO sensor_readings (
        reading_id, zone_id, moisture_level, 
        ph_level, temperature_c, sensor_status
    ) VALUES (
        seq_reading_id.NEXTVAL, p_zone_id, p_moisture,
        p_ph, p_temperature, p_sensor_status
    )
    RETURNING reading_id INTO p_reading_id;
    
    -- Check if reading triggers an alert
    sp_check_for_alerts(p_zone_id, p_moisture, p_ph, p_temperature);
    
    COMMIT;
    p_status := 'SUCCESS: Reading added';
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_status := 'ERROR: ' || SQLERRM;
        p_reading_id := NULL;
END sp_add_sensor_reading;
/

-- PROCEDURE 2: Generate watering schedule for a date
CREATE OR REPLACE PROCEDURE sp_generate_watering_schedule(
    p_for_date IN DATE DEFAULT TRUNC(SYSDATE) + 1,
    p_dry_threshold IN NUMBER DEFAULT 70
)
IS
    CURSOR cur_zones IS
        SELECT zone_id, zone_name
        FROM garden_zones
        WHERE status = 'ACTIVE';
    
    v_water_needed NUMBER;
    v_current_moisture NUMBER;
    v_health_status VARCHAR2(20);
    v_task_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Generating watering schedule for: ' || TO_CHAR(p_for_date, 'DD-MON-YYYY'));
    
    FOR zone_rec IN cur_zones LOOP
        -- Get latest moisture reading
        BEGIN
            SELECT moisture_level INTO v_current_moisture
            FROM (
                SELECT moisture_level
                FROM sensor_readings
                WHERE zone_id = zone_rec.zone_id
                  AND moisture_level IS NOT NULL
                ORDER BY reading_timestamp DESC
            )
            WHERE ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_current_moisture := NULL;
        END;
        
        -- Only schedule if moisture is low or no data
        IF v_current_moisture IS NULL OR v_current_moisture < p_dry_threshold THEN
            v_water_needed := fn_calculate_water_needed(zone_rec.zone_id, v_current_moisture);
            
            -- Insert watering task
            INSERT INTO watering_tasks (
                task_id, zone_id, scheduled_date, 
                recommended_water_amt, task_status
            ) VALUES (
                seq_task_id.NEXTVAL, zone_rec.zone_id, p_for_date,
                v_water_needed, 'PENDING'
            );
            
            v_task_count := v_task_count + 1;
            DBMS_OUTPUT.PUT_LINE('  - Zone ' || zone_rec.zone_id || ' (' || zone_rec.zone_name || 
                               '): ' || v_water_needed || ' liters');
        END IF;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Total tasks created: ' || v_task_count);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END sp_generate_watering_schedule;
/

-- PROCEDURE 3: Check for and create alerts based on sensor readings
CREATE OR REPLACE PROCEDURE sp_check_for_alerts(
    p_zone_id IN NUMBER,
    p_moisture IN NUMBER,
    p_ph IN NUMBER,
    p_temperature IN NUMBER
)
IS
    v_crop_type_id NUMBER;
    v_ideal_moisture_min NUMBER;
    v_ideal_moisture_max NUMBER;
    v_ideal_ph_min NUMBER;
    v_ideal_ph_max NUMBER;
    v_alert_message VARCHAR2(500);
    v_alert_type VARCHAR2(30);
    v_priority VARCHAR2(20);
BEGIN
    -- Get crop requirements for this zone
    SELECT gz.crop_type_id, ct.ideal_moisture_min, ct.ideal_moisture_max,
           ct.ideal_ph_min, ct.ideal_ph_max
    INTO v_crop_type_id, v_ideal_moisture_min, v_ideal_moisture_max,
         v_ideal_ph_min, v_ideal_ph_max
    FROM garden_zones gz
    JOIN crop_types ct ON gz.crop_type_id = ct.crop_type_id
    WHERE gz.zone_id = p_zone_id;
    
    -- Check moisture
    IF p_moisture IS NOT NULL THEN
        IF p_moisture < v_ideal_moisture_min - 10 THEN
            v_alert_type := 'LOW_MOISTURE';
            v_priority := 'HIGH';
            v_alert_message := 'Critical low moisture: ' || p_moisture || '% (min: ' || v_ideal_moisture_min || '%)';
            sp_create_alert(p_zone_id, v_alert_type, v_alert_message, v_priority);
        ELSIF p_moisture > v_ideal_moisture_max + 10 THEN
            v_alert_type := 'HIGH_MOISTURE';
            v_priority := 'MEDIUM';
            v_alert_message := 'High moisture risk: ' || p_moisture || '% (max: ' || v_ideal_moisture_max || '%)';
            sp_create_alert(p_zone_id, v_alert_type, v_alert_message, v_priority);
        END IF;
    END IF;
    
    -- Check pH
    IF p_ph IS NOT NULL THEN
        IF p_ph < v_ideal_ph_min - 1 THEN
            v_alert_type := 'CRITICAL_PH';
            v_priority := 'HIGH';
            v_alert_message := 'Critically acidic pH: ' || p_ph || ' (min: ' || v_ideal_ph_min || ')';
            sp_create_alert(p_zone_id, v_alert_type, v_alert_message, v_priority);
        ELSIF p_ph > v_ideal_ph_max + 1 THEN
            v_alert_type := 'CRITICAL_PH';
            v_priority := 'HIGH';
            v_alert_message := 'Critically alkaline pH: ' || p_ph || ' (max: ' || v_ideal_ph_max || ')';
            sp_create_alert(p_zone_id, v_alert_type, v_alert_message, v_priority);
        END IF;
    END IF;
    
    -- Check temperature
    IF p_temperature IS NOT NULL THEN
        IF p_temperature > 35 THEN
            v_alert_type := 'TEMP_EXTREME';
            v_priority := 'MEDIUM';
            v_alert_message := 'High temperature: ' || p_temperature || '°C';
            sp_create_alert(p_zone_id, v_alert_type, v_alert_message, v_priority);
        ELSIF p_temperature < 5 THEN
            v_alert_type := 'TEMP_EXTREME';
            v_priority := 'MEDIUM';
            v_alert_message := 'Low temperature: ' || p_temperature || '°C';
            sp_create_alert(p_zone_id, v_alert_type, v_alert_message, v_priority);
        END IF;
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL; -- Zone not found, skip alert
    WHEN OTHERS THEN
        NULL; -- Don't fail main procedure if alert creation fails
END sp_check_for_alerts;
/

-- PROCEDURE 4: Create an alert
CREATE OR REPLACE PROCEDURE sp_create_alert(
    p_zone_id IN NUMBER,
    p_alert_type IN VARCHAR2,
    p_alert_message IN VARCHAR2,
    p_priority IN VARCHAR2 DEFAULT 'MEDIUM'
)
IS
    v_existing_alert_id NUMBER;
BEGIN
    -- Check if similar alert already exists and is still open
    BEGIN
        SELECT alert_id INTO v_existing_alert_id
        FROM alerts
        WHERE zone_id = p_zone_id
          AND alert_type = p_alert_type
          AND status = 'OPEN'
          AND alert_timestamp > SYSTIMESTAMP - INTERVAL '1' HOUR
        AND ROWNUM = 1;
        
        -- Update existing alert instead of creating new one
        UPDATE alerts
        SET alert_timestamp = SYSTIMESTAMP,
            alert_message = p_alert_message,
            priority = p_priority
        WHERE alert_id = v_existing_alert_id;
        
        DBMS_OUTPUT.PUT_LINE('Updated existing alert for zone ' || p_zone_id);
        RETURN;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- No existing alert, create new one
    END;
    
    -- Create new alert
    INSERT INTO alerts (
        alert_id, zone_id, alert_type, 
        alert_message, priority, status
    ) VALUES (
        seq_alert_id.NEXTVAL, p_zone_id, p_alert_type,
        p_alert_message, p_priority, 'OPEN'
    );
    
    DBMS_OUTPUT.PUT_LINE('Created new alert for zone ' || p_zone_id);
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error creating alert: ' || SQLERRM);
        ROLLBACK;
END sp_create_alert;
/

-- Test the procedures
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== PROCEDURE TESTS ===');
    
    DECLARE
        v_reading_id NUMBER;
        v_status VARCHAR2(100);
    BEGIN
        sp_add_sensor_reading(1, 65, 6.5, 25, 'OPERATIONAL', v_reading_id, v_status);
        DBMS_OUTPUT.PUT_LINE('Add reading: ' || v_status || ' (ID: ' || v_reading_id || ')');
    END;
    
    -- Test with invalid data
    DECLARE
        v_reading_id NUMBER;
        v_status VARCHAR2(100);
    BEGIN
        sp_add_sensor_reading(1, 150, 6.5, 25, 'OPERATIONAL', v_reading_id, v_status);
        DBMS_OUTPUT.PUT_LINE('Add invalid reading: ' || v_status);
    END;
    
    -- Generate schedule
    sp_generate_watering_schedule(TRUNC(SYSDATE) + 1, 70);
    
    -- Create test alert
    sp_create_alert(1, 'LOW_MOISTURE', 'Test alert message', 'HIGH');
END;
/