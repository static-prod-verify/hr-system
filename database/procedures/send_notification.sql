-- HR System - Send Notification Procedure
-- NOTE: Contains intentional web service proxy vulnerability for scanner testing

CREATE OR REPLACE PROCEDURE send_notification(
    p_employee_id NUMBER,
    p_event_type VARCHAR2,
    p_notification_url VARCHAR2
)
AS
    v_request UTL_HTTP.REQ;
    v_response UTL_HTTP.RESP;
    v_response_text VARCHAR2(4000);
    v_json_payload CLOB;
    v_emp_record EMPLOYEES%ROWTYPE;
BEGIN
    -- Validate event type
    IF p_event_type NOT IN ('HIRE', 'TERMINATE', 'PROMOTION', 'SALARY_CHANGE') THEN
        RAISE_APPLICATION_ERROR(-20400, 'Invalid event type');
    END IF;

    -- Get employee information
    SELECT * INTO v_emp_record
    FROM EMPLOYEES
    WHERE emp_id = p_employee_id;

    -- Build JSON payload
    v_json_payload := '{' ||
        '"event": "' || p_event_type || '",' ||
        '"employee_id": ' || v_emp_record.emp_id || ',' ||
        '"first_name": "' || v_emp_record.first_name || '",' ||
        '"last_name": "' || v_emp_record.last_name || '",' ||
        '"email": "' || v_emp_record.email || '",' ||
        '"timestamp": "' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || '"' ||
    '}';

    -- VULNERABILITY: CWE-441 (Unintended Web Service Proxy)
    -- Notification URL is not validated and used directly
    -- User could redirect to malicious webhook server
    BEGIN
        v_request := UTL_HTTP.BEGIN_REQUEST(
            url => p_notification_url,  -- CWEID 441: Tainted URL
            method => 'POST',
            http_version => 'HTTP/1.1'
        );

        -- Set request headers
        UTL_HTTP.SET_HEADER(v_request, 'Content-Type', 'application/json');
        UTL_HTTP.SET_HEADER(v_request, 'Accept', 'application/json');
        UTL_HTTP.SET_HEADER(v_request, 'User-Agent', 'HR-System/1.0');
        UTL_HTTP.SET_HEADER(v_request, 'Authorization', 'Bearer system-api-token');  -- CWEID 798: Hardcoded token

        -- Write payload
        UTL_HTTP.WRITE_TEXT(v_request, v_json_payload);

        -- Get response
        v_response := UTL_HTTP.GET_RESPONSE(v_request);

        -- Read response
        BEGIN
            LOOP
                UTL_HTTP.READ_TEXT(v_response, v_response_text, 32767);
                DBMS_OUTPUT.PUT_LINE(v_response_text);
            END LOOP;
        EXCEPTION
            WHEN UTL_HTTP.END_OF_BODY THEN
                NULL;
        END;

        -- Check response status
        IF v_response.status_code != 200 AND v_response.status_code != 201 THEN
            RAISE_APPLICATION_ERROR(-20401, 'Webhook returned status ' || v_response.status_code);
        END IF;

        UTL_HTTP.END_RESPONSE(v_response);

        DBMS_OUTPUT.PUT_LINE('Notification sent successfully');

    EXCEPTION
        WHEN UTL_HTTP.REQUEST_FAILED THEN
            RAISE_APPLICATION_ERROR(-20402, 'HTTP request failed: ' || p_notification_url);
        WHEN OTHERS THEN
            IF v_request IS NOT NULL THEN
                UTL_HTTP.END_REQUEST(v_request);
            END IF;
            RAISE;
    END;

    -- Log notification sent
    INSERT INTO AUDIT_LOG (
        audit_id, table_name, operation, record_id,
        timestamp, user_id, details
    ) VALUES (
        SEQ_AUDIT_LOG_ID.NEXTVAL, 'NOTIFICATIONS', 'SEND',
        p_employee_id, SYSDATE, USER,
        'Sent ' || p_event_type || ' notification to ' || p_notification_url
    );

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20403, 'Employee not found');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20404, 'Error sending notification: ' || SQLERRM);
END send_notification;
/

COMMIT;
