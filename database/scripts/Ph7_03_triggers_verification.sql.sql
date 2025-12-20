-- ============================================
-- PHASE VII: PART 6 - VERIFICATION QUERIES
-- File: 06_verification.sql
-- ============================================

-- 1. Show all triggers created
SELECT trigger_name, table_name, trigger_type, triggering_event, status
FROM user_triggers
WHERE table_name IN ('WATERING_TASKS', 'SYSTEM_CONFIG', 'SENSOR_READINGS')
ORDER BY table_name, trigger_name;

-- 2. Show functions created
SELECT object_name, object_type, status
FROM user_objects
WHERE object_type = 'FUNCTION'
AND object_name LIKE 'FN_%'
ORDER BY object_name;

-- 3. Show package status
SELECT object_name, object_type, status
FROM user_objects
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
ORDER BY object_type;

-- 4. Show audit trail summary
SELECT 
    table_name,
    change_type,
    COUNT(*) as operation_count,
    MIN(change_timestamp) as first_operation,
    MAX(change_timestamp) as last_operation
FROM audit_log
GROUP BY table_name, change_type
ORDER BY table_name, change_type;

-- 5. Show restriction test results
SELECT 
    'WEEKEND_CHECK' as test_case,
    fn_is_weekend() as result,
    CASE 
        WHEN fn_is_weekend() = 'YES' THEN 'Manual tasks blocked'
        ELSE 'Manual tasks allowed'
    END as implication
FROM dual
UNION ALL
SELECT 
    'HOLIDAY_CHECK',
    fn_is_holiday(),
    CASE 
        WHEN fn_is_holiday() = 'YES' THEN 'Config changes blocked'
        ELSE 'Config changes allowed'
    END
FROM dual;