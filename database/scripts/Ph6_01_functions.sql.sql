-- ============================================
-- PHASE VI: PART 1 - FUNCTIONS
-- File: 01_functions.sql
-- ============================================

-- FUNCTION 1: Calculate water requirement based on zone and moisture
CREATE OR REPLACE FUNCTION fn_calculate_water_needed(
    p_zone_id IN NUMBER,
    p_current_moisture IN NUMBER
) RETURN NUMBER
IS
    v_area_sqft NUMBER;
    v_crop_water_mm NUMBER;
    v_moisture_deficit NUMBER;
    v_water_liters NUMBER;
    v_zone_exists NUMBER;
BEGIN
    -- Check if zone exists
    SELECT COUNT(*) INTO v_zone_exists 
    FROM garden_zones 
    WHERE zone_id = p_zone_id;
    
    IF v_zone_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Zone ' || p_zone_id || ' does not exist');
    END IF;
    
    -- Get zone area and crop water requirement
    SELECT gz.area_sqft, ct.water_req_mm
    INTO v_area_sqft, v_crop_water_mm
    FROM garden_zones gz
    JOIN crop_types ct ON gz.crop_type_id = ct.crop_type_id
    WHERE gz.zone_id = p_zone_id;
    
    -- Calculate moisture deficit (assume 75% is ideal for calculation)
    v_moisture_deficit := GREATEST(75 - NVL(p_current_moisture, 75), 0);
    
    -- Calculate water in liters: area (sqft) * water req (mm) * deficit factor * conversion
    -- Simplified formula: area * water_req * (deficit/100) * 0.0283
    v_water_liters := ROUND(v_area_sqft * v_crop_water_mm * (v_moisture_deficit / 100) * 0.0283, 2);
    
    -- Ensure minimum water amount
    IF v_water_liters < 5 THEN
        v_water_liters := 5;
    END IF;
    
    RETURN v_water_liters;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error calculating water need: ' || SQLERRM);
END fn_calculate_water_needed;
/

-- FUNCTION 2: Check zone health status
CREATE OR REPLACE FUNCTION fn_check_zone_health(
    p_zone_id IN NUMBER
) RETURN VARCHAR2
IS
    v_moisture_status VARCHAR2(20);
    v_ph_status VARCHAR2(20);
    v_sensor_status VARCHAR2(20);
    v_latest_moisture NUMBER;
    v_latest_ph NUMBER;
    v_ideal_moisture_min NUMBER;
    v_ideal_moisture_max NUMBER;
    v_ideal_ph_min NUMBER;
    v_ideal_ph_max NUMBER;
BEGIN
    -- Get latest sensor reading
    SELECT moisture_level, ph_level
    INTO v_latest_moisture, v_latest_ph
    FROM (
        SELECT moisture_level, ph_level
        FROM sensor_readings
        WHERE zone_id = p_zone_id
        ORDER BY reading_timestamp DESC
    )
    WHERE ROWNUM = 1;
    
    -- Get ideal ranges for this zone's crop
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
END fn_check_zone_health;
/

-- FUNCTION 3: Validate sensor reading
CREATE OR REPLACE FUNCTION fn_validate_sensor_reading(
    p_moisture IN NUMBER,
    p_ph IN NUMBER,
    p_temperature IN NUMBER
) RETURN VARCHAR2
IS
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
    
    -- Check temperature range (reasonable for agriculture)
    IF p_temperature IS NOT NULL AND (p_temperature < -10 OR p_temperature > 50) THEN
        v_validation_result := 'INVALID_TEMPERATURE';
    END IF;
    
    -- Check for extreme values that might indicate sensor error
    IF p_moisture = 0 OR p_moisture = 100 THEN
        v_validation_result := 'SUSPICIOUS_MOISTURE';
    END IF;
    
    IF p_ph = 0 OR p_ph = 14 THEN
        v_validation_result := 'SUSPICIOUS_PH';
    END IF;
    
    RETURN v_validation_result;
END fn_validate_sensor_reading;
/

-- Test the functions
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== FUNCTION TESTS ===');
    DBMS_OUTPUT.PUT_LINE('Water needed for zone 1: ' || fn_calculate_water_needed(1, 60));
    DBMS_OUTPUT.PUT_LINE('Health status for zone 1: ' || fn_check_zone_health(1));
    DBMS_OUTPUT.PUT_LINE('Sensor validation (65, 6.5, 25): ' || fn_validate_sensor_reading(65, 6.5, 25));
    DBMS_OUTPUT.PUT_LINE('Sensor validation (150, 6.5, 25): ' || fn_validate_sensor_reading(150, 6.5, 25));
END;
/