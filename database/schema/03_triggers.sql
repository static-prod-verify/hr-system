-- HR System - Trigger Definitions
-- Business logic and audit triggers

-- Trigger: Update employee updated_date on modification
CREATE OR REPLACE TRIGGER TRG_EMPLOYEE_UPDATE
BEFORE UPDATE ON EMPLOYEES
FOR EACH ROW
BEGIN
    :new.updated_date := SYSDATE;
END;
/

-- Trigger: Log employee changes to audit log
CREATE OR REPLACE TRIGGER TRG_EMPLOYEE_AUDIT
AFTER INSERT OR UPDATE OR DELETE ON EMPLOYEES
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_old_values CLOB;
    v_new_values CLOB;
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_new_values := 'emp_id=' || :new.emp_id || ', name=' || :new.first_name || ' ' || :new.last_name;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_values := 'salary=' || :old.salary || ', dept_id=' || :old.dept_id;
        v_new_values := 'salary=' || :new.salary || ', dept_id=' || :new.dept_id;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_values := 'emp_id=' || :old.emp_id || ', name=' || :old.first_name;
    END IF;

    INSERT INTO AUDIT_LOG (
        audit_id, table_name, operation, record_id,
        timestamp, user_id, old_values, new_values
    ) VALUES (
        SEQ_AUDIT_LOG_ID.NEXTVAL, 'EMPLOYEES', v_operation,
        NVL(:new.emp_id, :old.emp_id),
        SYSDATE, USER, v_old_values, v_new_values
    );
    COMMIT;
END;
/

-- Trigger: Track salary changes
CREATE OR REPLACE TRIGGER TRG_SALARY_CHANGE
BEFORE UPDATE ON EMPLOYEES
FOR EACH ROW
BEGIN
    IF :old.salary != :new.salary THEN
        INSERT INTO SALARY_HISTORY (
            sal_hist_id, emp_id, old_salary, new_salary,
            change_date, changed_by, effective_date
        ) VALUES (
            SEQ_SALARY_HISTORY_ID.NEXTVAL, :new.emp_id,
            :old.salary, :new.salary,
            SYSDATE, USER, SYSDATE
        );
    END IF;
END;
/

-- Trigger: Validate department updates
CREATE OR REPLACE TRIGGER TRG_DEPARTMENT_UPDATE
BEFORE UPDATE ON DEPARTMENTS
FOR EACH ROW
BEGIN
    IF :new.manager_id IS NOT NULL THEN
        -- Verify manager exists in employees
        BEGIN
            SELECT 1 INTO :new.manager_id
            FROM EMPLOYEES
            WHERE emp_id = :new.manager_id
            AND is_active = 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001, 'Invalid manager ID');
        END;
    END IF;

    :new.updated_date := SYSDATE;
END;
/

-- Trigger: Maintain department updated_date
CREATE OR REPLACE TRIGGER TRG_DEPARTMENT_AUDIT
AFTER INSERT OR UPDATE OR DELETE ON DEPARTMENTS
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (
        audit_id, table_name, operation, record_id,
        timestamp, user_id
    ) VALUES (
        SEQ_AUDIT_LOG_ID.NEXTVAL, 'DEPARTMENTS',
        CASE WHEN INSERTING THEN 'INSERT'
             WHEN UPDATING THEN 'UPDATE'
             ELSE 'DELETE' END,
        NVL(:new.dept_id, :old.dept_id),
        SYSDATE, USER
    );
END;
/

COMMIT;
