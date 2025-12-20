-- ============================================
-- PHASE VII: PART 4 - COMPOUND TRIGGER
-- File: 04_compound_trigger.sql
-- ============================================

-- COMPOUND TRIGGER: Comprehensive audit for sensor readings
-- Tracks before/after values and aggregates changes
CREATE OR REPLACE TRIGGER trg_compound_audit_sensor_readings
FOR INSERT OR UPDATE OR DELETE ON sensor_readings
COMPOUND TRIGGER

    -- Type declarations
    TYPE t_audit_rec IS RECORD (
        table_name VARCHAR2(50),
        column_name VARCHAR2(50),
        old_value VARCHAR2(4000),
        new_value VARCHAR2(4000),
        change_type VARCHAR2(10),
        changed_by VARCHAR2(100)
    );
    
    TYPE t_audit_table IS TABLE OF t_audit_rec;
    v_audit_data t_audit_table := t_audit_table();
    
    -- Before each row: Collect old values
    BEFORE EACH ROW IS
    BEGIN
        -- Initialize collection
        v_audit_data.EXTEND;
        
        IF INSERTING THEN
            v_audit_data(v_audit_data.LAST).change_type := 'INSERT';
            v_audit_data(v_audit_data.LAST).old_value := NULL;
            v_audit_data(v_audit_data.LAST).new_value := 
                'Zone:' || :NEW.zone_id || ' M:' || :NEW.moisture_level || 
                ' pH:' || :NEW.ph_level || ' T:' || :NEW.temperature_c;
        ELSIF UPDATING THEN
            v_audit_data(v_audit_data.LAST).change_type := 'UPDATE';
            v_audit_data(v_audit_data.LAST).old_value := 
                'Zone:' || :OLD.zone_id || ' M:' || :OLD.moisture_level || 
                ' pH:' || :OLD.ph_level || ' T:' || :OLD.temperature_c;
            v_audit_data(v_audit_data.LAST).new_value := 
                'Zone:' || :NEW.zone_id || ' M:' || :NEW.moisture_level || 
                ' pH:' || :NEW.ph_level || ' T:' || :NEW.temperature_c;
        ELSE -- DELETING
            v_audit_data(v_audit_data.LAST).change_type := 'DELETE';
            v_audit_data(v_audit_data.LAST).old_value := 
                'Zone:' || :OLD.zone_id || ' M:' || :OLD.moisture_level || 
                ' pH:' || :OLD.ph_level || ' T:' || :OLD.temperature_c;
            v_audit_data(v_audit_data.LAST).new_value := NULL;
        END IF;
        
        v_audit_data(v_audit_data.LAST).table_name := 'SENSOR_READINGS';
        v_audit_data(v_audit_data.LAST).column_name := 'READING_DATA';
        v_audit_data(v_audit_data.LAST).changed_by := 'SENSOR_SYSTEM';
        
    END BEFORE EACH ROW;
    
    -- After statement: Bulk insert all collected audit data
    AFTER STATEMENT IS
    BEGIN
        IF v_audit_data.COUNT > 0 THEN
            FORALL i IN 1..v_audit_data.COUNT
                INSERT INTO audit_log (audit_id, table_name, column_name, 
                                      old_value, new_value, change_type, changed_by)
                VALUES (seq_audit_id.NEXTVAL,
                       v_audit_data(i).table_name,
                       v_audit_data(i).column_name,
                       v_audit_data(i).old_value,
                       v_audit_data(i).new_value,
                       v_audit_data(i).change_type,
                       v_audit_data(i).changed_by);
        END IF;
        
        -- Clear collection for next operation
        v_audit_data.DELETE;
        
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- Don't fail main operation if audit fails
    END AFTER STATEMENT;
    
END trg_compound_audit_sensor_readings;
/

-- Test message
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== COMPOUND TRIGGER CREATED ===');
    DBMS_OUTPUT.PUT_LINE('Compound trigger for sensor readings audit created successfully');
END;
/