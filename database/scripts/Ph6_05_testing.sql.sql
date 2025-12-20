-- ============================================
-- PHASE VI: PART 5 - TESTING (CORRECTED)
-- File: 05_testing.sql
-- ============================================

-- Create error log table
CREATE TABLE error_log (
    error_id NUMBER PRIMARY KEY,
    error_time TIMESTAMP DEFAULT SYSTIMESTAMP,
    procedure_name VARCHAR2(100),
    error_message VARCHAR2(4000)
);

CREATE SEQUENCE seq_error START WITH 1;

-- Test procedure with exceptions
CREATE OR REPLACE PROCEDURE sp_test_exceptions
IS
    e_custom_error EXCEPTION;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Testing exception handling...');
    
    -- Test 1: Normal case
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Test 1: Normal operation');
        INSERT INTO error_log (error_id, procedure_name, error_message)
        VALUES (seq_error.NEXTVAL, 'sp_test_exceptions', 'Test log entry');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  ERROR: ' || SQLERRM);
    END;
    
    -- Test 2: Custom exception
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Test 2: Raising custom exception');
        RAISE e_custom_error;
    EXCEPTION
        WHEN e_custom_error THEN
            DBMS_OUTPUT.PUT_LINE('  Caught: Custom error');
    END;
    
    -- Test 3: Division by zero
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Test 3: Division by zero');
        DBMS_OUTPUT.PUT_LINE('Result: ' || (10 / 0));
    EXCEPTION
        WHEN ZERO_DIVIDE THEN
            DBMS_OUTPUT.PUT_LINE('  Caught: Division by zero');
    END;
    
    DBMS_OUTPUT.PUT_LINE('All tests completed');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END sp_test_exceptions;
/

-- Run tests (RUN THIS IN PL/SQL BLOCK)
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== EXCEPTION HANDLING TESTS ===');
    sp_test_exceptions;
    
    DBMS_OUTPUT.PUT_LINE('=== FINAL VERIFICATION ===');
    
    -- Show what we created (using DBMS_OUTPUT, not SELECT)
    DBMS_OUTPUT.PUT_LINE('Created in Phase VI:');
    DBMS_OUTPUT.PUT_LINE('  1. 3 Functions');
    DBMS_OUTPUT.PUT_LINE('  2. 3 Procedures (plus package procedures)');
    DBMS_OUTPUT.PUT_LINE('  3. Cursors with different types');
    DBMS_OUTPUT.PUT_LINE('  4. Window functions (ROW_NUMBER, RANK, LAG)');
    DBMS_OUTPUT.PUT_LINE('  5. Complete package with spec and body');
    DBMS_OUTPUT.PUT_LINE('  6. Exception handling with custom exceptions');
    DBMS_OUTPUT.PUT_LINE('  7. Error logging table');
    
    -- To see actual data counts, run these as SEPARATE SQL queries (not in PL/SQL block):
    -- SELECT 'SENSOR_READINGS: ' || COUNT(*) || ' rows' FROM sensor_readings;
    -- SELECT 'ALERTS: ' || COUNT(*) || ' rows' FROM alerts;
    -- SELECT 'WATERING_TASKS: ' || COUNT(*) || ' rows' FROM watering_tasks;
END;
/