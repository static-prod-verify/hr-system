-- HR System - Security Package
-- Authentication, authorization, and credential management
-- NOTE: Contains intentional security vulnerabilities for scanner testing

CREATE OR REPLACE PACKAGE hr_security_pkg AS
    -- Authentication functions
    FUNCTION authenticate_user(p_username VARCHAR2, p_password VARCHAR2) RETURN BOOLEAN;
    FUNCTION validate_session(p_session_token VARCHAR2) RETURN NUMBER;

    -- Authorization functions
    FUNCTION check_employee_access(p_emp_id NUMBER, p_resource VARCHAR2) RETURN BOOLEAN;
    FUNCTION get_employee_permissions(p_emp_id NUMBER) RETURN VARCHAR2;

    -- Session management
    PROCEDURE create_user_session(p_emp_id NUMBER, p_ip_address VARCHAR2);
    PROCEDURE terminate_session(p_session_token VARCHAR2);

    -- Credential management
    PROCEDURE store_system_credentials(p_service_name VARCHAR2, p_username VARCHAR2, p_password VARCHAR2);
    PROCEDURE update_api_key(p_emp_id NUMBER, p_new_key VARCHAR2);

END hr_security_pkg;
/

CREATE OR REPLACE PACKAGE BODY hr_security_pkg AS

    -- VULNERABILITY: CWE-798 (Hardcoded Credentials)
    -- Hardcoded default credentials in code
    FUNCTION authenticate_user(p_username VARCHAR2, p_password VARCHAR2) RETURN BOOLEAN
    IS
        v_result BOOLEAN := FALSE;
        v_count NUMBER;
    BEGIN
        -- CWEID 798: Hardcoded credential - admin account
        IF p_username = 'admin' AND p_password = 'Admin@123' THEN
            RETURN TRUE;
        END IF;

        -- CWEID 798: Hardcoded credential - service account
        IF p_username = 'svc_account' AND p_password = 'ServicePass_2025' THEN
            RETURN TRUE;
        END IF;

        -- Normal user authentication (also vulnerable)
        BEGIN
            SELECT COUNT(*) INTO v_count
            FROM SYSTEM_CREDENTIALS
            WHERE username = p_username
            AND password = p_password;  -- CWEID 798: Unencrypted password comparison

            IF v_count > 0 THEN
                v_result := TRUE;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                v_result := FALSE;
        END;

        RETURN v_result;
    END authenticate_user;

    -- VULNERABILITY: CWE-89 (SQL Injection)
    -- Dynamic query without proper parameterization
    FUNCTION validate_session(p_session_token VARCHAR2) RETURN NUMBER
    IS
        v_emp_id NUMBER;
        v_query VARCHAR2(500);
    BEGIN
        -- CWEID 89: SQL Injection - no parameterization
        v_query := 'SELECT emp_id FROM USER_SESSIONS WHERE session_token = ''' || p_session_token || ''' AND is_active = ''Y''';
        EXECUTE IMMEDIATE v_query INTO v_emp_id;
        RETURN v_emp_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END validate_session;

    -- VULNERABILITY: CWE-89 (SQL Injection) with taint propagation
    -- Dynamic query using concatenation through multiple functions
    FUNCTION check_employee_access(p_emp_id NUMBER, p_resource VARCHAR2) RETURN BOOLEAN
    IS
        v_has_access BOOLEAN := FALSE;
        v_resource_upper VARCHAR2(200);
        v_query VARCHAR2(1000);
        v_count NUMBER;
    BEGIN
        -- Resource name is uppercased but still tainted
        v_resource_upper := UPPER(p_resource);

        -- CWEID 89: SQL Injection - taint flows through UPPER() and concatenation
        v_query := 'SELECT COUNT(*) FROM (
            SELECT 1 FROM EMPLOYEES e
            WHERE e.emp_id = ' || p_emp_id || '
            AND e.job_title LIKE ''%' || v_resource_upper || '%''
        )';

        EXECUTE IMMEDIATE v_query INTO v_count;

        IF v_count > 0 THEN
            v_has_access := TRUE;
        END IF;

        RETURN v_has_access;
    END check_employee_access;

    -- SAFE IMPLEMENTATION - No SQL Injection
    -- This function demonstrates proper parameterization
    FUNCTION get_employee_permissions(p_emp_id NUMBER) RETURN VARCHAR2
    IS
        v_permissions VARCHAR2(500) := '';
        v_emp_record EMPLOYEES%ROWTYPE;
    BEGIN
        -- Safe: Using direct SELECT with no concatenation
        SELECT * INTO v_emp_record
        FROM EMPLOYEES
        WHERE emp_id = p_emp_id;

        -- Build permissions based on job title
        CASE v_emp_record.job_title
            WHEN 'MANAGER' THEN
                v_permissions := 'READ,WRITE,APPROVE';
            WHEN 'HR_SPECIALIST' THEN
                v_permissions := 'READ,WRITE,AUDIT';
            ELSE
                v_permissions := 'READ';
        END CASE;

        RETURN v_permissions;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'NONE';
    END get_employee_permissions;

    -- SAFE IMPLEMENTATION - Session management
    PROCEDURE create_user_session(p_emp_id NUMBER, p_ip_address VARCHAR2)
    IS
        v_session_token VARCHAR2(200);
    BEGIN
        -- Generate secure token (in real system)
        v_session_token := DBMS_CRYPTO.HASH(
            UTL_RAW.CAST_TO_RAW(p_emp_id || SYSDATE || DBMS_RANDOM.VALUE),
            DBMS_CRYPTO.HASH_SH256
        );

        INSERT INTO USER_SESSIONS (
            session_id, emp_id, session_token,
            login_time, ip_address, is_active
        ) VALUES (
            SEQ_SESSION_ID.NEXTVAL, p_emp_id, v_session_token,
            SYSDATE, p_ip_address, 'Y'
        );

        COMMIT;
    END create_user_session;

    -- SAFE IMPLEMENTATION - Session termination
    PROCEDURE terminate_session(p_session_token VARCHAR2)
    IS
    BEGIN
        UPDATE USER_SESSIONS
        SET is_active = 'N', logout_time = SYSDATE
        WHERE session_token = p_session_token;

        COMMIT;
    END terminate_session;

    -- VULNERABILITY: CWE-798 (Hardcoded Credentials in Code)
    PROCEDURE store_system_credentials(p_service_name VARCHAR2, p_username VARCHAR2, p_password VARCHAR2)
    IS
    BEGIN
        -- CWEID 798: Storing credentials in database without encryption
        INSERT INTO SYSTEM_CREDENTIALS (
            cred_id, service_name, username,
            password,  -- CWEID 798: Plain text password
            created_date
        ) VALUES (
            SEQ_CREDENTIAL_ID.NEXTVAL, p_service_name,
            p_username, p_password, SYSDATE
        );

        COMMIT;
    END store_system_credentials;

    -- VULNERABILITY: CWE-798 (Hardcoded API Key)
    PROCEDURE update_api_key(p_emp_id NUMBER, p_new_key VARCHAR2)
    IS
        v_master_key VARCHAR2(100) := 'master_key_2025_secret_xyz';  -- CWEID 798: Hardcoded key
        v_encrypted_key RAW(32);
    BEGIN
        -- Encrypt using weak method
        v_encrypted_key := DBMS_CRYPTO.ENCRYPT(
            UTL_RAW.CAST_TO_RAW(p_new_key),
            DBMS_CRYPTO.ENCRYPT_DES,  -- CWEID 321: Weak encryption algorithm
            UTL_RAW.CAST_TO_RAW(v_master_key)
        );

        UPDATE EMPLOYEES
        SET email = email || '|encrypted_api_key=' || v_encrypted_key
        WHERE emp_id = p_emp_id;

        COMMIT;
    END update_api_key;

END hr_security_pkg;
/

COMMIT;
