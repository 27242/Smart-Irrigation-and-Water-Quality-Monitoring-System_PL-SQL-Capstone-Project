    -- Continue from where it left off...
        -- Get ideal ranges
        SELECT ct.ideal_moisture_min, ct.ideal_moisture_max,
               ct.ideal_ph_min, ct.ideal_ph_max
        INTO v_ideal_moisture_min, v_ideal_moisture_max,
             v_ideal_ph_min, v_ideal_ph_max
        FROM garden_zones gz
        JOIN crop_types ct ON gz.crop_type_id = ct.crop_type_id
        WHERE gz.zone_id = p_zone_id;
        
        -- Determine moisture status
        IF v_latest_moisture IS NULL THEN
            v_moisture_status := 'SENSOR_ERROR';
        ELSIF v_latest_moisture < v_ideal_moisture_min THEN
            v_moisture_status := 'LOW';
        ELSIF v_latest_moisture > v_ideal_moisture_max THEN
            v_moisture_status := 'HIGH';
        ELSE
            v_moisture_status := 'OK';
        END IF;
        
        -- Determine pH status
        IF v_latest_ph IS NULL THEN
            v_ph_status := 'SENSOR_ERROR';
        ELSIF v_latest_ph < v_ideal_ph_min THEN
            v_ph_status := 'ACIDIC';
        ELSIF v_latest_ph > v_ideal_ph_max THEN
            v_ph_status := 'ALKALINE';
        ELSE
            v_ph_status := 'OK';
        END IF;
        
        -- Overall status
        IF v_moisture_status = 'SENSOR_ERROR' OR v_ph_status = 'SENSOR_ERROR' THEN
            RETURN 'SENSOR_ISSUE';
        ELSIF v_moisture_status != 'OK' OR v_ph_status != 'OK' THEN
            RETURN 'NEEDS_ATTENTION';
        ELSE
            RETURN 'HEALTHY';
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'NO_DATA';
        WHEN OTHERS THEN
            RETURN 'ERROR';
    END check_zone_health;
    
    FUNCTION validate_sensor_reading(p_moisture NUMBER, p_ph NUMBER, p_temperature NUMBER) RETURN VARCHAR2 IS
        v_validation_result VARCHAR2(100) := 'VALID';
    BEGIN
        -- Check moisture range
        IF p_moisture IS NOT NULL AND (p_moisture < 0 OR p_moisture > 100) THEN
            v_validation_result := 'INVALID_MOISTURE';
        END IF;
        
        -- Check pH range
        IF p_ph IS NOT NULL AND (p_ph < 0 OR p_ph > 14) THEN
            v_validation_result := 'INVALID_PH';
        END IF;
        
        -- Check temperature range
        IF p_temperature IS NOT NULL AND (p_temperature < -10 OR p_temperature > 50) THEN
            v_validation_result := 'INVALID_TEMPERATURE';
        END IF;
        
        RETURN v_validation_result;
    END validate_sensor_reading;
    
    -- Procedure implementations
    PROCEDURE add_sensor_reading(
        p_zone_id IN NUMBER,
        p_moisture IN NUMBER,
        p_ph IN NUMBER,
        p_temperature IN NUMBER,
        p_sensor_status IN VARCHAR2 DEFAULT 'OPERATIONAL',
        p_reading_id OUT NUMBER,
        p_status OUT VARCHAR2
    ) IS
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
        v_validation_result := validate_sensor_reading(p_moisture, p_ph, p_temperature);
        
        IF v_validation_result != 'VALID' THEN
            p_status := 'ERROR: ' || v_validation_result;
            RETURN;
        END IF;
        
        -- Insert reading
        INSERT INTO sensor_readings (
            reading_id, zone_id, moisture_level, 
            ph_level, temperature_c, sensor_status
        ) VALUES (
            seq_reading_id.NEXTVAL, p_zone_id, p_moisture,
            p_ph, p_temperature, p_sensor_status
        )
        RETURNING reading_id INTO p_reading_id;
        
        COMMIT;
        p_status := 'SUCCESS: Reading added';
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_status := 'ERROR: ' || SQLERRM;
            p_reading_id := NULL;
    END add_sensor_reading;
    
    PROCEDURE generate_watering_schedule(
        p_for_date IN DATE DEFAULT TRUNC(SYSDATE) + 1,
        p_dry_threshold IN NUMBER DEFAULT 70
    ) IS
        CURSOR cur_zones IS
            SELECT zone_id, zone_name
            FROM garden_zones
            WHERE status = 'ACTIVE';
        
        v_water_needed NUMBER;
        v_current_moisture NUMBER;
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
                v_water_needed := calculate_water_needed(zone_rec.zone_id, v_current_moisture);
                
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
    END generate_watering_schedule;
    
    PROCEDURE resolve_alert(
        p_alert_id IN NUMBER,
        p_resolved_by IN NUMBER,
        p_resolution_notes IN VARCHAR2,
        p_status OUT VARCHAR2
    ) IS
        v_alert_exists NUMBER;
        v_user_exists NUMBER;
    BEGIN
        -- Check if alert exists
        SELECT COUNT(*) INTO v_alert_exists
        FROM alerts
        WHERE alert_id = p_alert_id;
        
        IF v_alert_exists = 0 THEN
            p_status := 'ERROR: Alert not found';
            RETURN;
        END IF;
        
        -- Check if user exists
        SELECT COUNT(*) INTO v_user_exists
        FROM users
        WHERE user_id = p_resolved_by;
        
        IF v_user_exists = 0 THEN
            p_status := 'ERROR: User not found';
            RETURN;
        END IF;
        
        -- Update alert
        UPDATE alerts
        SET status = 'RESOLVED',
            resolved_by = p_resolved_by,
            resolution_notes = p_resolution_notes
        WHERE alert_id = p_alert_id;
        
        -- Log the resolution
        INSERT INTO audit_log (audit_id, table_name, change_type, changed_by, new_value)
        VALUES (seq_audit_id.NEXTVAL, 'ALERTS', 'UPDATE', 'USER_' || p_resolved_by, 
                'Alert ' || p_alert_id || ' resolved');
        
        COMMIT;
        p_status := 'SUCCESS: Alert resolved';
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_status := 'ERROR: ' || SQLERRM;
    END resolve_alert;
    
    PROCEDURE get_zone_report(
        p_zone_id IN NUMBER,
        p_days IN NUMBER DEFAULT 7
    ) IS
        v_zone_name VARCHAR2(100);
        v_crop_name VARCHAR2(100);
        v_avg_moisture NUMBER;
        v_avg_ph NUMBER;
        v_avg_temp NUMBER;
        v_total_water NUMBER;
        v_open_alerts NUMBER;
    BEGIN
        -- Get basic zone info
        SELECT gz.zone_name, ct.crop_name
        INTO v_zone_name, v_crop_name
        FROM garden_zones gz
        JOIN crop_types ct ON gz.crop_type_id = ct.crop_type_id
        WHERE gz.zone_id = p_zone_id;
        
        -- Get averages from last p_days
        SELECT AVG(moisture_level), AVG(ph_level), AVG(temperature_c)
        INTO v_avg_moisture, v_avg_ph, v_avg_temp
        FROM sensor_readings
        WHERE zone_id = p_zone_id
          AND reading_timestamp > SYSTIMESTAMP - p_days;
        
        -- Get total water used
        SELECT NVL(SUM(actual_water_used), 0)
        INTO v_total_water
        FROM watering_tasks
        WHERE zone_id = p_zone_id
          AND task_status = 'COMPLETED'
          AND completion_timestamp > SYSTIMESTAMP - p_days;
        
        -- Get open alerts
        SELECT COUNT(*)
        INTO v_open_alerts
        FROM alerts
        WHERE zone_id = p_zone_id
          AND status = 'OPEN';
        
        -- Display report
        DBMS_OUTPUT.PUT_LINE('=== ZONE REPORT ===');
        DBMS_OUTPUT.PUT_LINE('Zone: ' || v_zone_name || ' (ID: ' || p_zone_id || ')');
        DBMS_OUTPUT.PUT_LINE('Crop: ' || v_crop_name);
        DBMS_OUTPUT.PUT_LINE('---');
        DBMS_OUTPUT.PUT_LINE('Last ' || p_days || ' days statistics:');
        DBMS_OUTPUT.PUT_LINE('  Average moisture: ' || ROUND(NVL(v_avg_moisture, 0), 1) || '%');
        DBMS_OUTPUT.PUT_LINE('  Average pH: ' || ROUND(NVL(v_avg_ph, 0), 1));
        DBMS_OUTPUT.PUT_LINE('  Average temperature: ' || ROUND(NVL(v_avg_temp, 0), 1) || '°C');
        DBMS_OUTPUT.PUT_LINE('  Total water used: ' || ROUND(v_total_water, 1) || ' liters');
        DBMS_OUTPUT.PUT_LINE('---');
        DBMS_OUTPUT.PUT_LINE('Current status: ' || check_zone_health(p_zone_id));
        DBMS_OUTPUT.PUT_LINE('Open alerts: ' || v_open_alerts);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Zone ' || p_zone_id || ' not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR generating report: ' || SQLERRM);
    END get_zone_report;
    
END irrigation_pkg;
/

-- Test the package
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== IRRIGATION PACKAGE TESTS ===');
    
    -- Test functions
    DBMS_OUTPUT.PUT_LINE('1. Water needed for zone 1 (60% moisture): ' || 
                        irrigation_pkg.calculate_water_needed(1, 60) || ' liters');
    
    DBMS_OUTPUT.PUT_LINE('2. Zone 1 health: ' || irrigation_pkg.check_zone_health(1));
    
    DBMS_OUTPUT.PUT_LINE('3. Sensor validation (65, 6.5, 25): ' || 
                        irrigation_pkg.validate_sensor_reading(65, 6.5, 25));
    
    -- Test procedures
    DECLARE
        v_reading_id NUMBER;
        v_status VARCHAR2(100);
    BEGIN
        irrigation_pkg.add_sensor_reading(1, 68, 6.3, 24, 'OPERATIONAL', v_reading_id, v_status);
        DBMS_OUTPUT.PUT_LINE('4. Add sensor reading: ' || v_status);
    END;
    
    DBMS_OUTPUT.PUT_LINE('5. Generating watering schedule...');
    irrigation_pkg.generate_watering_schedule(TRUNC(SYSDATE) + 1, 70);
    
    DBMS_OUTPUT.PUT_LINE('6. Zone report:');
    irrigation_pkg.get_zone_report(1, 7);
    
END;
/