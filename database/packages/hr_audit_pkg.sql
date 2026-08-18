-- HR System - Audit Package
-- Auditing, logging, and external notifications
-- NOTE: Contains intentional security vulnerabilities for scanner testing

CREATE OR REPLACE PACKAGE hr_audit_pkg AS
    -- Audit logging
    PROCEDURE log_action(
        p_table_name VARCHAR2,
        p_action VARCHAR2,
        p_record_id NUMBER,
        p_details CLOB
    );

    PROCEDURE generate_audit_report(
        p_start_date DATE,
        p_end_date DATE,
        p_results OUT SYS_REFCURSOR
    );

    -- Email notifications
    PROCEDURE send_audit_email(
        p_recipient VARCHAR2,
        p_subject VARCHAR2,
        p_body CLOB
    );

    PROCEDURE notify_salary_change(
        p_emp_id NUMBER,
        p_old_salary NUMBER,
        p_new_salary NUMBER
    );

    -- File export
    PROCEDURE export_audit_log(
        p_file_path VARCHAR2,
        p_date_from DATE,
        p_date_to DATE
    );

    -- External notifications
    PROCEDURE send_webhook_notification(
        p_webhook_url VARCHAR2,
        p_event_type VARCHAR2,
        p_payload CLOB
    );

END hr_audit_pkg;
/

CREATE OR REPLACE PACKAGE BODY hr_audit_pkg AS

    -- SAFE IMPLEMENTATION - Audit logging
    PROCEDURE log_action(
        p_table_name VARCHAR2,
        p_action VARCHAR2,
        p_record_id NUMBER,
        p_details CLOB
    )
    IS
    BEGIN
        INSERT INTO AUDIT_LOG (
            audit_id, table_name, operation, record_id,
            timestamp, user_id, details, ip_address
        ) VALUES (
            SEQ_AUDIT_LOG_ID.NEXTVAL, p_table_name, p_action,
            p_record_id, SYSDATE, USER, p_details,
            SYS_CONTEXT('USERENV', 'IP_ADDRESS')
        );

        COMMIT;
    END log_action;

    -- SAFE IMPLEMENTATION - Audit report
    PROCEDURE generate_audit_report(
        p_start_date DATE,
        p_end_date DATE,
        p_results OUT SYS_REFCURSOR
    )
    IS
    BEGIN
        OPEN p_results FOR
            SELECT audit_id, table_name, operation, record_id,
                   timestamp, user_id, details
            FROM AUDIT_LOG
            WHERE timestamp >= p_start_date
            AND timestamp <= p_end_date
            ORDER BY timestamp DESC;
    END generate_audit_report;

    -- VULNERABILITY: CWE-88 (Argument Injection) in email
    -- Email parameters are used without proper encoding
    PROCEDURE send_audit_email(
        p_recipient VARCHAR2,
        p_subject VARCHAR2,
        p_body CLOB
    )
    IS
        v_smtp_host VARCHAR2(100) := 'mail.company.com';
        v_smtp_port NUMBER := 25;
    BEGIN
        -- CWEID 88: Argument injection - tainted email parameters used directly
        -- Recipient could contain additional email headers/parameters
        UTL_MAIL.SEND(
            sender => 'audit@company.com',
            recipients => p_recipient,  -- CWEID 88: Tainted parameter
            cc => NULL,
            subject => p_subject,  -- CWEID 88: Could inject headers
            message => p_body,
            mime_type => 'text/plain; charset=us-ascii'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Email failed: ' || SQLERRM);
    END send_audit_email;

    -- VULNERABILITY: CWE-88 (Argument Injection)
    PROCEDURE notify_salary_change(
        p_emp_id NUMBER,
        p_old_salary NUMBER,
        p_new_salary NUMBER
    )
    IS
        v_emp_name VARCHAR2(200);
        v_manager_email VARCHAR2(100);
        v_email_subject VARCHAR2(500);
        v_email_body CLOB;
    BEGIN
        -- Get employee info
        SELECT CONCAT(first_name, CONCAT(' ', last_name)), email
        INTO v_emp_name, v_manager_email
        FROM EMPLOYEES
        WHERE emp_id = p_emp_id;

        -- Build email - tainted employee name could inject headers
        v_email_subject := 'Salary Change Notification for ' || v_emp_name;  -- CWEID 88
        v_email_body := 'Employee: ' || v_emp_name ||
                       CHR(10) || 'Old Salary: ' || p_old_salary ||
                       CHR(10) || 'New Salary: ' || p_new_salary;

        -- Send notification
        send_audit_email(v_manager_email, v_email_subject, v_email_body);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Employee not found');
    END notify_salary_change;

    -- VULNERABILITY: CWE-73 (Path Manipulation)
    -- File path is constructed using user input without validation
    PROCEDURE export_audit_log(
        p_file_path VARCHAR2,
        p_date_from DATE,
        p_date_to DATE
    )
    IS
        v_file_handle UTL_FILE.FILE_TYPE;
        v_cursor SYS_REFCURSOR;
        v_audit_id NUMBER;
        v_table_name VARCHAR2(50);
        v_operation VARCHAR2(10);
        v_timestamp DATE;
        v_full_path VARCHAR2(500);
        v_file_name VARCHAR2(200);
    BEGIN
        -- CWEID 73: Path manipulation - no validation of file path
        -- User could use ../ or other path traversal sequences
        v_file_name := SUBSTR(p_file_path, INSTR(p_file_path, '/', -1) + 1);
        v_full_path := '/export/audit_logs/' || v_file_name;  -- CWEID 73: Unsafe concatenation

        v_file_handle := UTL_FILE.FOPEN(
            '/export/audit_logs',
            v_file_name,  -- CWEID 73: Tainted filename
            'W'
        );

        -- Query audit logs
        OPEN v_cursor FOR
            SELECT audit_id, table_name, operation, timestamp
            FROM AUDIT_LOG
            WHERE timestamp >= p_date_from
            AND timestamp <= p_date_to;

        -- Write to file
        LOOP
            FETCH v_cursor INTO v_audit_id, v_table_name, v_operation, v_timestamp;
            EXIT WHEN v_cursor%NOTFOUND;

            UTL_FILE.PUT_LINE(v_file_handle,
                v_audit_id || ',' || v_table_name || ',' ||
                v_operation || ',' || v_timestamp
            );
        END LOOP;

        CLOSE v_cursor;
        UTL_FILE.FCLOSE(v_file_handle);

        INSERT INTO AUDIT_LOG (
            audit_id, table_name, operation, record_id,
            timestamp, user_id, details
        ) VALUES (
            SEQ_AUDIT_LOG_ID.NEXTVAL, 'AUDIT_LOG', 'EXPORT',
            NULL, SYSDATE, USER, 'Exported to ' || v_full_path
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            IF UTL_FILE.IS_OPEN(v_file_handle) THEN
                UTL_FILE.FCLOSE(v_file_handle);
            END IF;
            RAISE;
    END export_audit_log;

    -- VULNERABILITY: CWE-441 (Unintended Web Service Proxy)
    -- URL is tainted and used directly in HTTP request
    PROCEDURE send_webhook_notification(
        p_webhook_url VARCHAR2,
        p_event_type VARCHAR2,
        p_payload CLOB
    )
    IS
        v_request UTL_HTTP.REQ;
        v_response UTL_HTTP.RESP;
        v_response_text VARCHAR2(4000);
    BEGIN
        -- CWEID 441: Unintended web service proxy - URL not validated
        -- User could redirect to malicious server
        v_request := UTL_HTTP.BEGIN_REQUEST(
            url => p_webhook_url,  -- CWEID 441: Tainted URL
            method => 'POST',
            http_version => 'HTTP/1.1'
        );

        -- Set headers
        UTL_HTTP.SET_HEADER(v_request, 'Content-Type', 'application/json');
        UTL_HTTP.SET_HEADER(v_request, 'X-Event-Type', p_event_type);

        -- Send payload
        UTL_HTTP.WRITE_TEXT(v_request, p_payload);

        -- Get response
        v_response := UTL_HTTP.GET_RESPONSE(v_request);

        -- Read response
        BEGIN
            LOOP
                UTL_HTTP.READ_TEXT(v_response, v_response_text, 32767);
            END LOOP;
        EXCEPTION
            WHEN UTL_HTTP.END_OF_BODY THEN
                NULL;
        END;

        UTL_HTTP.END_RESPONSE(v_response);

        -- Log notification
        INSERT INTO AUDIT_LOG (
            audit_id, table_name, operation, record_id,
            timestamp, user_id, details
        ) VALUES (
            SEQ_AUDIT_LOG_ID.NEXTVAL, 'WEBHOOK', 'SEND',
            NULL, SYSDATE, USER, 'Sent to ' || p_webhook_url
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Webhook failed: ' || SQLERRM);
    END send_webhook_notification;

END hr_audit_pkg;
/

COMMIT;
