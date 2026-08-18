-- HR System - Employee Package
-- Employee management operations
-- NOTE: Contains intentional security vulnerabilities for scanner testing

CREATE OR REPLACE PACKAGE hr_employee_pkg AS
    -- Employee search operations
    PROCEDURE search_employees(
        p_search_criteria VARCHAR2,
        p_results OUT SYS_REFCURSOR
    );

    PROCEDURE search_by_department(
        p_dept_criteria VARCHAR2,
        p_results OUT SYS_REFCURSOR
    );

    -- Employee data retrieval
    FUNCTION get_employee_details(p_emp_id NUMBER) RETURN VARCHAR2;
    FUNCTION get_employee_name(p_emp_id NUMBER) RETURN VARCHAR2;

    -- Employee management
    PROCEDURE create_employee(
        p_first_name VARCHAR2,
        p_last_name VARCHAR2,
        p_email VARCHAR2,
        p_salary NUMBER,
        p_dept_id NUMBER
    );

    PROCEDURE update_employee_salary(
        p_emp_id NUMBER,
        p_new_salary NUMBER,
        p_reason VARCHAR2
    );

    PROCEDURE terminate_employee(
        p_emp_id NUMBER,
        p_termination_date DATE
    );

END hr_employee_pkg;
/

CREATE OR REPLACE PACKAGE BODY hr_employee_pkg AS

    -- VULNERABILITY: CWE-89 (SQL Injection)
    -- Dynamic WHERE clause using concatenation
    PROCEDURE search_employees(
        p_search_criteria VARCHAR2,
        p_results OUT SYS_REFCURSOR
    )
    IS
        v_query VARCHAR2(2000);
    BEGIN
        -- CWEID 89: SQL Injection - no parameterization of search_criteria
        -- User can inject SQL through p_search_criteria parameter
        v_query := 'SELECT emp_id, first_name, last_name, email, salary, dept_id
                    FROM EMPLOYEES
                    WHERE is_active = ''Y''
                    AND (' || p_search_criteria || ')
                    ORDER BY last_name, first_name';

        OPEN p_results FOR v_query;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Search failed: ' || SQLERRM);
    END search_employees;

    -- VULNERABILITY: CWE-89 (SQL Injection) with LIKE operator
    PROCEDURE search_by_department(
        p_dept_criteria VARCHAR2,
        p_results OUT SYS_REFCURSOR
    )
    IS
        v_dept_search VARCHAR2(500);
        v_query VARCHAR2(2000);
    BEGIN
        -- CWEID 89: Department name is concatenated directly
        -- No escaping of special LIKE characters
        v_dept_search := 'dept_name LIKE ''%' || p_dept_criteria || '%''';

        v_query := 'SELECT e.emp_id, e.first_name, e.last_name, e.salary, d.dept_name
                    FROM EMPLOYEES e
                    JOIN DEPARTMENTS d ON e.dept_id = d.dept_id
                    WHERE ' || v_dept_search ||
                    ' AND e.is_active = ''Y''';

        OPEN p_results FOR v_query;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END search_by_department;

    -- SAFE IMPLEMENTATION - Proper parameterization
    FUNCTION get_employee_details(p_emp_id NUMBER) RETURN VARCHAR2
    IS
        v_details VARCHAR2(500);
    BEGIN
        -- Safe: Direct SELECT with no concatenation
        SELECT 'ID: ' || emp_id || ', Name: ' || first_name || ' ' || last_name ||
               ', Email: ' || email || ', Salary: ' || salary
        INTO v_details
        FROM EMPLOYEES
        WHERE emp_id = p_emp_id;

        RETURN v_details;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Employee not found';
    END get_employee_details;

    -- SAFE IMPLEMENTATION
    FUNCTION get_employee_name(p_emp_id NUMBER) RETURN VARCHAR2
    IS
        v_name VARCHAR2(200);
    BEGIN
        SELECT first_name || ' ' || last_name
        INTO v_name
        FROM EMPLOYEES
        WHERE emp_id = p_emp_id
        AND is_active = 'Y';

        RETURN v_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Unknown';
    END get_employee_name;

    -- SAFE IMPLEMENTATION - Employee creation with validation
    PROCEDURE create_employee(
        p_first_name VARCHAR2,
        p_last_name VARCHAR2,
        p_email VARCHAR2,
        p_salary NUMBER,
        p_dept_id NUMBER
    )
    IS
        v_emp_id NUMBER;
        v_dept_exists NUMBER;
    BEGIN
        -- Validate department exists
        SELECT COUNT(*) INTO v_dept_exists
        FROM DEPARTMENTS
        WHERE dept_id = p_dept_id;

        IF v_dept_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Department does not exist');
        END IF;

        -- Get next ID safely
        v_emp_id := SEQ_EMPLOYEE_ID.NEXTVAL;

        -- Insert employee with parameterized statement (implicit)
        INSERT INTO EMPLOYEES (
            emp_id, first_name, last_name, email,
            salary, dept_id, hire_date, is_active, created_date
        ) VALUES (
            v_emp_id, p_first_name, p_last_name, p_email,
            p_salary, p_dept_id, SYSDATE, 'Y', SYSDATE
        );

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Employee created: ' || v_emp_id);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20101, 'Email already exists');
    END create_employee;

    -- SAFE IMPLEMENTATION - Salary update with audit trail
    PROCEDURE update_employee_salary(
        p_emp_id NUMBER,
        p_new_salary NUMBER,
        p_reason VARCHAR2
    )
    IS
        v_old_salary NUMBER;
    BEGIN
        -- Validate salary is positive
        IF p_new_salary <= 0 THEN
            RAISE_APPLICATION_ERROR(-20102, 'Salary must be positive');
        END IF;

        -- Get current salary
        SELECT salary INTO v_old_salary
        FROM EMPLOYEES
        WHERE emp_id = p_emp_id;

        -- Update employee
        UPDATE EMPLOYEES
        SET salary = p_new_salary, updated_date = SYSDATE
        WHERE emp_id = p_emp_id;

        -- Trigger will automatically create salary history entry
        -- Update audit log with reason
        INSERT INTO SALARY_HISTORY (
            sal_hist_id, emp_id, old_salary, new_salary,
            change_date, changed_by, change_reason
        ) VALUES (
            SEQ_SALARY_HISTORY_ID.NEXTVAL, p_emp_id,
            v_old_salary, p_new_salary, SYSDATE, USER, p_reason
        );

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Salary updated for employee ' || p_emp_id);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20103, 'Employee not found');
    END update_employee_salary;

    -- SAFE IMPLEMENTATION - Employee termination
    PROCEDURE terminate_employee(
        p_emp_id NUMBER,
        p_termination_date DATE
    )
    IS
    BEGIN
        -- Validate termination date is not in past (usually)
        IF p_termination_date < TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20104, 'Termination date cannot be in past');
        END IF;

        -- Mark employee as inactive
        UPDATE EMPLOYEES
        SET is_active = 'N', updated_date = SYSDATE
        WHERE emp_id = p_emp_id;

        -- Log termination
        INSERT INTO AUDIT_LOG (
            audit_id, table_name, operation, record_id,
            timestamp, user_id, details
        ) VALUES (
            SEQ_AUDIT_LOG_ID.NEXTVAL, 'EMPLOYEES', 'TERMINATE',
            p_emp_id, SYSDATE, USER,
            'Terminated on ' || TO_CHAR(p_termination_date, 'YYYY-MM-DD')
        );

        COMMIT;
    END terminate_employee;

END hr_employee_pkg;
/

COMMIT;
