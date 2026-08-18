-- HR System - Validate Employee Access Function
-- MIXED: Demonstrates both safe and vulnerable patterns

CREATE OR REPLACE FUNCTION validate_employee_access(
    p_emp_id NUMBER,
    p_resource_type VARCHAR2
) RETURN BOOLEAN
AS
    v_result BOOLEAN := FALSE;
    v_job_title VARCHAR2(100);
    v_is_manager BOOLEAN := FALSE;
    v_is_hr_staff BOOLEAN := FALSE;
    v_dept_id NUMBER;
    v_query VARCHAR2(1000);
    v_count NUMBER;
BEGIN
    -- Get employee details (safe query)
    SELECT job_title, dept_id INTO v_job_title, v_dept_id
    FROM EMPLOYEES
    WHERE emp_id = p_emp_id
    AND is_active = 'Y';

    -- Determine role (safe)
    v_is_manager := (v_job_title LIKE '%MANAGER%');
    v_is_hr_staff := (v_job_title LIKE '%HR%' OR v_job_title LIKE '%HUMAN%');

    -- Check resource access based on role (safe)
    CASE p_resource_type
        WHEN 'SALARY_DATA' THEN
            -- Only managers and HR can access salary data
            v_result := v_is_manager OR v_is_hr_staff;

        WHEN 'AUDIT_LOG' THEN
            -- Only HR staff can access audit logs
            v_result := v_is_hr_staff;

        WHEN 'EMPLOYEE_DIRECTORY' THEN
            -- All active employees can view directory
            v_result := TRUE;

        WHEN 'HIRING_FORMS' THEN
            -- Only HR staff can access hiring forms
            v_result := v_is_hr_staff;

        WHEN 'PAYROLL' THEN
            -- Only payroll-related roles
            v_result := (v_job_title LIKE '%PAYROLL%' OR v_job_title LIKE '%FINANCE%');

        WHEN 'REPORTS' THEN
            -- VULNERABILITY: CWE-89 (SQL Injection)
            -- Resource type is used in dynamic query (though basic here)
            -- In complex scenarios, this could be exploited
            -- This demonstrates how tainted data can flow through functions
            v_query := 'SELECT COUNT(*) FROM AUDIT_LOG WHERE operation = ''' ||
                      p_resource_type || '''';
            -- Note: This is contrived but shows injection potential
            -- Normal implementation would use proper parameterization

            -- For this example, just check if user is manager or HR
            v_result := v_is_manager OR v_is_hr_staff;

        ELSE
            -- Default: deny access
            v_result := FALSE;
    END CASE;

    RETURN v_result;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;  -- Deny access if employee not found
    WHEN OTHERS THEN
        -- Log error and deny access
        INSERT INTO AUDIT_LOG (
            audit_id, table_name, operation, record_id,
            timestamp, user_id, details
        ) VALUES (
            SEQ_AUDIT_LOG_ID.NEXTVAL, 'ACCESS_CONTROL', 'ERROR',
            p_emp_id, SYSDATE, USER,
            'Access validation error: ' || SQLERRM
        );
        RETURN FALSE;
END validate_employee_access;
/

COMMIT;
