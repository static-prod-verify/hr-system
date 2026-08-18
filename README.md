# HR System - Oracle PL/SQL Sample Application

A realistic employee HR management system demonstrating Oracle PL/SQL best practices and security vulnerabilities. This sample project is designed to test the SQL Simple Scanner's ability to detect security issues in Oracle PL/SQL code.

## Overview

The HR system implements core human resources management features with business logic primarily in the database layer:

- **Employee Management**: Hiring, salary management, termination
- **Department Management**: Department structure and hierarchy
- **Salary History**: Track salary changes and adjustments
- **Audit Logging**: Compliance and change tracking
- **Security**: Authentication, authorization, session management
- **Reporting**: Employee reports and data exports
- **Notifications**: Email and webhook notifications

## Quick Start

### Prerequisites

- **Oracle Database**: 12c or later (with PL/SQL compiler)
- **Java**: Java 21 SDK or later
- **Maven**: 3.8 or later
- **Git**: For cloning and version control

### Build Instructions

#### Step 1: Set Up the Database

1. Create an Oracle database user and schema:
```sql
CREATE USER hr_user IDENTIFIED BY your_password;
GRANT CONNECT, RESOURCE, CREATE PROCEDURE, CREATE SEQUENCE TO hr_user;
```

2. Execute the database setup scripts in order:
```bash
sqlplus hr_user/your_password@YOUR_DB <<EOF
@database/schema/01_tables.sql
@database/schema/02_sequences.sql
@database/schema/03_triggers.sql
@database/packages/hr_security_pkg.sql
@database/packages/hr_employee_pkg.sql
@database/packages/hr_audit_pkg.sql
@database/procedures/*.sql
@database/functions/*.sql
EXIT;
EOF
```

#### Step 2: Build the Java Application

1. Navigate to the java-app directory:
```bash
cd java-app
```

2. Update database connection in `src/main/resources/application.yml`:
```yaml
spring:
  datasource:
    url: jdbc:oracle:thin:@localhost:1521:YOUR_DB
    username: hr_user
    password: your_password
    driver-class-name: oracle.jdbc.OracleDriver
```

3. Build with Maven:
```bash
mvn clean package
```

4. Run the application:
```bash
java -jar target/hr-system-1.0.0.jar
```

The API will be available at `https://localhost:8080` with Swagger UI at `https://localhost:8080/swagger-ui.html`

#### Step 3: Verify Installation

Test the API with a simple request:
```bash
curl http://localhost:8080/api/employees
```

## Oracle PL/SQL Architecture

### Database Layer

The system uses Oracle PL/SQL with:

- **Tables**: Employee, department, salary history, audit logs, user sessions
- **Sequences**: Auto-increment ID generation (Oracle-specific feature)
- **Triggers**: Data validation, audit trail, salary change tracking
- **Packages**: Modular business logic organization (PL/SQL-specific)
- **Procedures**: Specialized operations (salary processing, reporting, notifications)
- **Functions**: Calculations and validations (bonus calculation, access control)

### PL/SQL-Specific Features

This sample highlights Oracle PL/SQL language features:

- **Package Organization**: Logical grouping of related functions/procedures
- **REF CURSORS**: Dynamic query result sets
- **Implicit Cursors**: Automatic cursor handling in SELECT INTO statements
- **Sequences**: Server-side auto-increment implementation
- **Triggers**: Row-level and statement-level triggers for business logic
- **Exception Handling**: `EXCEPTION WHEN` blocks for error management
- **String Concatenation**: `||` operator and CONCAT function

### Security Vulnerabilities (Intentional)

The sample includes intentional security vulnerabilities to demonstrate the scanner's capabilities:

#### CWE-89: SQL Injection

- **Location**: `database/packages/hr_security_pkg.sql` - `check_employee_access()` and `validate_session()`
- **Location**: `database/packages/hr_employee_pkg.sql` - `search_employees()` and `search_by_department()`
- **Location**: `database/procedures/process_salary_increase.sql` - dynamic WHERE clause
- **Issue**: User input concatenated directly into SQL queries without parameterization

#### CWE-798: Hardcoded Credentials

- **Location**: `database/packages/hr_security_pkg.sql` - `authenticate_user()`
- **Location**: `database/procedures/send_notification.sql` - Bearer token
- **Issue**: Hardcoded passwords and API tokens in code

#### CWE-321/327: Weak Cryptography

- **Location**: `database/packages/hr_security_pkg.sql` - `update_api_key()`
- **Issue**: Use of weak DES encryption algorithm

#### CWE-73: Path Manipulation

- **Location**: `database/packages/hr_audit_pkg.sql` - `export_audit_log()`
- **Location**: `database/procedures/generate_employee_report.sql` - file path handling
- **Issue**: File paths used without validation, potential for directory traversal

#### CWE-441: Unintended Web Service Proxy

- **Location**: `database/packages/hr_audit_pkg.sql` - `send_webhook_notification()`
- **Location**: `database/procedures/send_notification.sql` - HTTP requests to tainted URLs
- **Issue**: Unvalidated webhook URLs could redirect to malicious servers

#### CWE-88: Argument Injection

- **Location**: `database/packages/hr_audit_pkg.sql` - `send_audit_email()`
- **Location**: `database/packages/hr_audit_pkg.sql` - `notify_salary_change()`
- **Issue**: Email parameters used without encoding, potential for header injection

## Project Structure

```shell
samples/hr-system/
├── database/
│   ├── schema/
│   │   ├── 01_tables.sql          # Table definitions
│   │   ├── 02_sequences.sql       # Sequence definitions
│   │   └── 03_triggers.sql        # Trigger definitions
│   ├── packages/
│   │   ├── hr_security_pkg.sql    # Auth, authorization (CWE-89, CWE-798, CWE-321)
│   │   ├── hr_employee_pkg.sql    # Employee management (CWE-89)
│   │   └── hr_audit_pkg.sql       # Auditing, notifications (CWE-73, CWE-441, CWE-88)
│   ├── procedures/
│   │   ├── process_salary_increase.sql     # Salary processing (CWE-89)
│   │   ├── generate_employee_report.sql    # Report generation (CWE-73)
│   │   └── send_notification.sql           # HTTP notifications (CWE-441, CWE-798)
│   └── functions/
│       ├── calculate_bonus.sql             # Safe: Bonus calculation
│       └── validate_employee_access.sql    # Mixed: Access control (CWE-89)
└── README.md
```

## Safe vs Vulnerable Patterns

### Safe Implementation Example

**Safe Direct Query** (hr_employee_pkg.sql - `get_employee_details()`):

```sql
FUNCTION get_employee_details(p_emp_id NUMBER) RETURN VARCHAR2
IS
    v_details VARCHAR2(500);
BEGIN
    -- Safe: Direct SELECT with no concatenation
    SELECT 'ID: ' || emp_id || ', Name: ' || first_name || ' ' || last_name
    INTO v_details
    FROM EMPLOYEES
    WHERE emp_id = p_emp_id;  -- No SQL injection risk

    RETURN v_details;
END;
```

### Vulnerable Implementation Example

**SQL Injection via Concatenation** (hr_employee_pkg.sql - `search_employees()`):

```sql
PROCEDURE search_employees(
    p_search_criteria VARCHAR2,
    p_results OUT SYS_REFCURSOR
)
IS
    v_query VARCHAR2(2000);
BEGIN
    -- VULNERABLE: Direct concatenation - CWE-89
    v_query := 'SELECT * FROM EMPLOYEES WHERE (' || p_search_criteria || ')';

    OPEN p_results FOR v_query;
    -- User can inject: "emp_id=1 UNION SELECT * FROM CREDENTIALS--"
END;
```

## Running the SQL Scanner

### Prerequisites

- Oracle PL/SQL compiler or compatible environment
- SQL Scanner built (see main README)
- Java 21 or later

### Scan Individual Files

```bash
# Build the scanner
cd /Users/rlayzell/dev/static/simple-code-scanners/plsqlsimplescanner
./gradlew shadowJar

# Scan a specific package
java -jar build/libs/SqlScanner-all.jar \
    --inputFile samples/hr-system/database/packages/hr_security_pkg.sql \
    --resultsFile samples/hr-system/hr_security_pkg_results.xml

# Scan employee package
java -jar build/libs/SqlScanner-all.jar \
    --inputFile samples/hr-system/database/packages/hr_employee_pkg.sql \
    --resultsFile samples/hr-system/hr_employee_pkg_results.xml

# Scan all packages
java -jar build/libs/SqlScanner-all.jar \
    --inputFile samples/hr-system/database/packages/ \
    --resultsFile samples/hr-system/packages_results.xml
```

### Expected Findings

When running the scanner on this sample, you should expect to find:

| File | Vulnerability | CWE | Count |
| ------ | --- | --- | --- |
| hr_security_pkg.sql | SQL Injection | CWE-89 | 2 |
| hr_security_pkg.sql | Hardcoded Credentials | CWE-798 | 3 |
| hr_security_pkg.sql | Weak Encryption | CWE-321 | 1 |
| hr_employee_pkg.sql | SQL Injection | CWE-89 | 2 |
| hr_audit_pkg.sql | Path Manipulation | CWE-73 | 1 |
| hr_audit_pkg.sql | Unintended Web Service Proxy | CWE-441 | 1 |
| hr_audit_pkg.sql | Argument Injection | CWE-88 | 1 |
| process_salary_increase.sql | SQL Injection | CWE-89 | 1 |
| generate_employee_report.sql | Path Manipulation | CWE-73 | 1 |
| send_notification.sql | Unintended Web Service Proxy | CWE-441 | 1 |
| send_notification.sql | Hardcoded Credentials | CWE-798 | 1 |

### Safe Files (No Vulnerabilities Expected)

- `calculate_bonus.sql` - Uses safe CASE statements and parameters
- `validate_employee_access.sql` - Mostly safe with clear CASE statements
- Schema files (`01_tables.sql`, `02_sequences.sql`, `03_triggers.sql`) - No issues expected

## Interpreting Results

The scanner outputs results in XML format showing:

- **Issue ID**: Unique identifier
- **CWE**: Common Weakness Enumeration ID
- **Severity**: Issue severity level
- **Line Number**: Location of vulnerability
- **Description**: Details about the vulnerability
- **Remediation**: Suggestions for fixing the issue

## Remediation Guidance

### Fixing SQL Injection (CWE-89)

**Before (Vulnerable)**:

```sql
v_query := 'SELECT * FROM EMPLOYEES WHERE name LIKE ''%' || p_name || '%''';
```

**After (Safe)**:

```sql
-- Use LIKE with proper escaping or parameterized queries
SELECT * FROM EMPLOYEES WHERE name LIKE '%' || REPLACE(p_name, '''', '''''') || '%';

-- Or better: Use direct comparison when possible
SELECT * FROM EMPLOYEES WHERE LOWER(name) = LOWER(p_name);
```

### Fixing Hardcoded Credentials (CWE-798)

**Before (Vulnerable)**:

```sql
IF p_username = 'admin' AND p_password = 'Admin@123' THEN
```

**After (Safe)**:

```sql
-- Store credentials securely in encrypted database fields or external secret management
-- Never hardcode in application code
```

### Fixing Path Manipulation (CWE-73)

**Before (Vulnerable)**:

```sql
v_file_handle := UTL_FILE.FOPEN(p_directory_path, filename, 'W');
```

**After (Safe)**:

```sql
-- Validate and whitelist directory paths
-- Use only known safe directories
IF p_directory_path NOT IN ('/approved/export/dir1', '/approved/export/dir2') THEN
    RAISE_APPLICATION_ERROR(-20001, 'Invalid directory');
END IF;
v_file_handle := UTL_FILE.FOPEN(p_directory_path, filename, 'W');
```

## Further Information

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE List](https://cwe.mitre.org/data/definitions/index.html)
- [Oracle PL/SQL Security Best Practices](https://docs.oracle.com/en/database/oracle/oracle-database/latest/)
- [SQL Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)

## Notes

- This is a sample project for **testing purposes only**
- The vulnerabilities are intentional for demonstrating scanner capabilities
- Never use these patterns in production code
- Always follow security best practices when developing PL/SQL code
- Regularly scan your database code for security vulnerabilities
