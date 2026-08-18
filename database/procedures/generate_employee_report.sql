-- HR System - Generate Employee Report Procedure
-- NOTE: Contains intentional path manipulation vulnerability for scanner testing

CREATE OR REPLACE PROCEDURE generate_employee_report(
    p_report_name VARCHAR2,
    p_output_path VARCHAR2,
    p_department_id NUMBER
)
AS
    v_file_handle UTL_FILE.FILE_TYPE;
    v_report_title VARCHAR2(200);
    v_line VARCHAR2(500);
    v_total_salary NUMBER := 0;
    v_employee_count NUMBER := 0;
BEGIN
    -- VULNERABILITY: CWE-73 (Path Manipulation)
    -- Output path is used directly without validation
    -- Could contain ../ sequences for directory traversal
    v_report_title := 'HR Report: ' || p_report_name;

    -- CWEID 73: Path manipulation - tainted path used in file operations
    v_file_handle := UTL_FILE.FOPEN(
        p_output_path,  -- CWEID 73: Could be '/' or contain directory traversal
        'hr_report_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.txt',
        'W'
    );

    -- Write header
    UTL_FILE.PUT_LINE(v_file_handle, v_report_title);
    UTL_FILE.PUT_LINE(v_file_handle, RPAD('=', 80, '='));
    UTL_FILE.PUT_LINE(v_file_handle, 'Generated: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
    UTL_FILE.PUT_LINE(v_file_handle, 'Department ID: ' || p_department_id);
    UTL_FILE.PUT_LINE(v_file_handle, '');

    -- Write employee details
    UTL_FILE.PUT_LINE(v_file_handle, RPAD('Employee ID', 12) ||
                                      RPAD('Name', 30) ||
                                      RPAD('Salary', 15) ||
                                      'Title');
    UTL_FILE.PUT_LINE(v_file_handle, RPAD('-', 80, '-'));

    -- Query employees by department
    FOR emp_rec IN (
        SELECT emp_id, first_name, last_name, salary, job_title
        FROM EMPLOYEES
        WHERE dept_id = p_department_id
        AND is_active = 'Y'
        ORDER BY last_name, first_name
    ) LOOP
        v_line := RPAD(emp_rec.emp_id, 12) ||
                  RPAD(emp_rec.first_name || ' ' || emp_rec.last_name, 30) ||
                  RPAD(TO_CHAR(emp_rec.salary, '$999,999.99'), 15) ||
                  NVL(emp_rec.job_title, 'N/A');

        UTL_FILE.PUT_LINE(v_file_handle, v_line);

        v_total_salary := v_total_salary + emp_rec.salary;
        v_employee_count := v_employee_count + 1;
    END LOOP;

    -- Write summary
    UTL_FILE.PUT_LINE(v_file_handle, RPAD('-', 80, '-'));
    UTL_FILE.PUT_LINE(v_file_handle, 'Total Employees: ' || v_employee_count);
    UTL_FILE.PUT_LINE(v_file_handle, 'Total Salaries: ' || TO_CHAR(v_total_salary, '$999,999,999.99'));
    UTL_FILE.PUT_LINE(v_file_handle, 'Average Salary: ' || TO_CHAR(v_total_salary / NULLIF(v_employee_count, 0), '$999,999.99'));
    UTL_FILE.PUT_LINE(v_file_handle, '');
    UTL_FILE.PUT_LINE(v_file_handle, 'Report End');

    -- Close file
    UTL_FILE.FCLOSE(v_file_handle);

    -- Log report generation
    INSERT INTO AUDIT_LOG (
        audit_id, table_name, operation, record_id,
        timestamp, user_id, details
    ) VALUES (
        SEQ_AUDIT_LOG_ID.NEXTVAL, 'REPORTS', 'GENERATE',
        p_department_id, SYSDATE, USER,
        'Generated report: ' || p_report_name || ' in ' || p_output_path
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Report generated successfully');

EXCEPTION
    WHEN UTL_FILE.INVALID_PATH THEN
        RAISE_APPLICATION_ERROR(-20300, 'Invalid output path: ' || p_output_path);
    WHEN OTHERS THEN
        IF UTL_FILE.IS_OPEN(v_file_handle) THEN
            UTL_FILE.FCLOSE(v_file_handle);
        END IF;
        RAISE_APPLICATION_ERROR(-20301, 'Error generating report: ' || SQLERRM);
END generate_employee_report;
/

COMMIT;
