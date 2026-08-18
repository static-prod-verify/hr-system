-- HR System - Process Salary Increase Procedure
-- NOTE: Contains intentional SQL injection vulnerability for scanner testing

CREATE OR REPLACE PROCEDURE process_salary_increase(
    p_filter_criteria VARCHAR2,
    p_increase_percentage NUMBER,
    p_reason VARCHAR2
)
AS
    v_query VARCHAR2(2000);
    v_emp_id NUMBER;
    v_current_salary NUMBER;
    v_new_salary NUMBER;
    v_update_count NUMBER := 0;
BEGIN
    IF p_increase_percentage < 0 OR p_increase_percentage > 50 THEN
        RAISE_APPLICATION_ERROR(-20200, 'Invalid increase percentage');
    END IF;

    -- VULNERABILITY: CWE-89 (SQL Injection)
    -- Filter criteria is concatenated directly into query
    -- Taint propagates through UPPER() function
    v_query := 'SELECT emp_id, salary FROM EMPLOYEES WHERE is_active = ''Y'' ' ||
               'AND (' || UPPER(p_filter_criteria) || ')';

    DBMS_OUTPUT.PUT_LINE('Executing salary update for employees matching: ' || p_filter_criteria);

    -- Use cursor to fetch matching employees
    FOR emp_rec IN (
        EXECUTE IMMEDIATE v_query
    ) LOOP
        v_emp_id := emp_rec.emp_id;
        v_current_salary := emp_rec.salary;
        v_new_salary := ROUND(v_current_salary * (1 + (p_increase_percentage / 100)), 2);

        BEGIN
            -- Update employee salary (safe because we're using bind variable for emp_id)
            UPDATE EMPLOYEES
            SET salary = v_new_salary, updated_date = SYSDATE
            WHERE emp_id = v_emp_id;

            -- Log salary change
            INSERT INTO SALARY_HISTORY (
                sal_hist_id, emp_id, old_salary, new_salary,
                change_date, changed_by, change_reason
            ) VALUES (
                SEQ_SALARY_HISTORY_ID.NEXTVAL, v_emp_id,
                v_current_salary, v_new_salary,
                SYSDATE, USER, p_reason || ' - ' || p_increase_percentage || '% increase'
            );

            v_update_count := v_update_count + 1;

        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error updating employee ' || v_emp_id || ': ' || SQLERRM);
        END;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(v_update_count || ' employees updated');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20201, 'Error processing salary increase: ' || SQLERRM);
END process_salary_increase;
/

COMMIT;
