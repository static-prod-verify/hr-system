-- HR System - Table Definitions
-- Sample database schema for an employee HR management system

-- Departments table
CREATE TABLE DEPARTMENTS (
    dept_id NUMBER PRIMARY KEY,
    dept_name VARCHAR2(100) NOT NULL,
    manager_id NUMBER,
    location VARCHAR2(100),
    created_date DATE DEFAULT SYSDATE,
    updated_date DATE DEFAULT SYSDATE
);

-- Employees table
CREATE TABLE EMPLOYEES (
    emp_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    phone VARCHAR2(20),
    hire_date DATE NOT NULL,
    salary NUMBER(10,2) NOT NULL,
    commission_pct NUMBER(3,2),
    dept_id NUMBER REFERENCES DEPARTMENTS(dept_id),
    manager_id NUMBER REFERENCES EMPLOYEES(emp_id),
    job_title VARCHAR2(100),
    is_active CHAR(1) DEFAULT 'Y',
    created_date DATE DEFAULT SYSDATE,
    updated_date DATE DEFAULT SYSDATE
);

-- Salary history tracking
CREATE TABLE SALARY_HISTORY (
    sal_hist_id NUMBER PRIMARY KEY,
    emp_id NUMBER NOT NULL REFERENCES EMPLOYEES(emp_id),
    old_salary NUMBER(10,2),
    new_salary NUMBER(10,2) NOT NULL,
    change_date DATE DEFAULT SYSDATE,
    changed_by VARCHAR2(100),
    change_reason VARCHAR2(500),
    effective_date DATE
);

-- Audit log for compliance
CREATE TABLE AUDIT_LOG (
    audit_id NUMBER PRIMARY KEY,
    table_name VARCHAR2(50) NOT NULL,
    operation VARCHAR2(10) NOT NULL,
    record_id NUMBER,
    timestamp DATE DEFAULT SYSDATE,
    user_id VARCHAR2(100),
    old_values CLOB,
    new_values CLOB,
    ip_address VARCHAR2(50),
    details CLOB
);

-- User sessions for security tracking
CREATE TABLE USER_SESSIONS (
    session_id NUMBER PRIMARY KEY,
    emp_id NUMBER NOT NULL REFERENCES EMPLOYEES(emp_id),
    session_token VARCHAR2(200) NOT NULL UNIQUE,
    login_time DATE DEFAULT SYSDATE,
    logout_time DATE,
    ip_address VARCHAR2(50),
    user_agent VARCHAR2(500),
    is_active CHAR(1) DEFAULT 'Y'
);

-- Performance ratings
CREATE TABLE PERFORMANCE_RATINGS (
    rating_id NUMBER PRIMARY KEY,
    emp_id NUMBER NOT NULL REFERENCES EMPLOYEES(emp_id),
    rating_date DATE DEFAULT SYSDATE,
    rating_year NUMBER,
    rating_value NUMBER(3,2),
    reviewer_id NUMBER REFERENCES EMPLOYEES(emp_id),
    comments CLOB
);

-- Bonus allocation table
CREATE TABLE BONUSES (
    bonus_id NUMBER PRIMARY KEY,
    emp_id NUMBER NOT NULL REFERENCES EMPLOYEES(emp_id),
    bonus_amount NUMBER(10,2),
    bonus_date DATE DEFAULT SYSDATE,
    bonus_type VARCHAR2(50),
    approval_status VARCHAR2(20) DEFAULT 'PENDING'
);

-- System credentials (for demonstrating hardcoded credential vulnerability)
CREATE TABLE SYSTEM_CREDENTIALS (
    cred_id NUMBER PRIMARY KEY,
    service_name VARCHAR2(100) NOT NULL,
    username VARCHAR2(100),
    password VARCHAR2(200),
    encrypted_password RAW(32),
    created_date DATE DEFAULT SYSDATE,
    last_modified DATE DEFAULT SYSDATE
);

COMMIT;
