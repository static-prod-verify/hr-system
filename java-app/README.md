# HR System - Java/Spring Application

Spring Boot REST API for HR management system that integrates with Oracle PL/SQL backend.

## Overview

This is a basic Spring Boot application that provides REST endpoints for HR operations:

- Employee management (CRUD)
- Salary processing
- Audit logging
- Security and authentication
- Access control

The application calls PL/SQL stored procedures, functions, and packages in the Oracle database.

## Project Structure

```shell
java-app/
├── src/
│   ├── main/
│   │   ├── java/com/example/hr/
│   │   │   ├── HrSystemApplication.java     - Spring Boot entry point
│   │   │   ├── controller/
│   │   │   │   ├── EmployeeController.java  - Employee endpoints
│   │   │   │   ├── AuditController.java     - Audit endpoints
│   │   │   │   └── SecurityController.java  - Security endpoints
│   │   │   ├── service/
│   │   │   │   ├── EmployeeService.java     - Employee business logic
│   │   │   │   ├── AuditService.java        - Audit operations
│   │   │   │   └── SecurityService.java     - Security operations
│   │   │   ├── repository/
│   │   │   │   ├── EmployeeRepository.java  - Employee data access
│   │   │   │   └── AuditLogRepository.java  - Audit log data access
│   │   │   ├── model/
│   │   │   │   ├── Employee.java            - Employee entity
│   │   │   │   ├── SalaryHistory.java       - Salary history entity
│   │   │   │   └── AuditLog.java            - Audit log entity
│   │   │   └── config/
│   │   │       └── JdbcConfig.java          - Spring configuration
│   │   └── resources/
│   │       └── application.yml               - Application properties
│   └── test/
│       └── java/com/example/hr/service/
│           └── EmployeeServiceTest.java     - Service tests
├── pom.xml
├── .gitignore
└── README.md
```

## Key Components

### Controllers

- **EmployeeController**: REST endpoints for employee operations
- **AuditController**: REST endpoints for audit logging
- **SecurityController**: REST endpoints for authentication and access control

### Services

- **EmployeeService**: Calls PL/SQL procedures for employee management
- **AuditService**: Manages audit logging and compliance reporting
- **SecurityService**: Handles authentication and authorization

### Repositories

- **EmployeeRepository**: JDBC repository for employee data
- **AuditLogRepository**: JDBC repository for audit logs

### Models

- **Employee**: Employee entity with salary and department info
- **SalaryHistory**: Salary change tracking
- **AuditLog**: Audit trail entity

## Vulnerabilities in Java Code

The Java application demonstrates several security vulnerabilities that mirror the PL/SQL issues:

### CWE-89: SQL Injection

- `EmployeeController.searchEmployees()` - Passes criteria directly to PL/SQL dynamic query
- `SecurityController.checkAccess()` - Resource parameter used in PL/SQL dynamic SQL

### CWE-798: Hardcoded Credentials & Plain Text Passwords

- `SecurityController.login()` - Passwords sent in plain text to PL/SQL
- `SecurityService.authenticateUser()` - No password hashing

### CWE-73: Path Manipulation

- `AuditController.exportAuditLog()` - Unvalidated file paths passed to PL/SQL

### CWE-88: Argument Injection

- `AuditController.sendAuditEmail()` - Email parameters without encoding

### Code Annotations

Each vulnerable method includes warning comments like:

```java
// VULNERABLE: Criteria passed directly to PL/SQL dynamic query
// CWE-89: SQL Injection
```

## REST API Endpoints

### Employee Endpoints

```shell
GET    /api/employees               - Get all employees
GET    /api/employees/{id}          - Get employee by ID
GET    /api/employees/department/{deptId}  - Get by department
POST   /api/employees               - Create employee
PUT    /api/employees/{id}/salary   - Update salary
DELETE /api/employees/{id}          - Terminate employee
GET    /api/employees/{id}/bonus    - Calculate bonus
GET    /api/employees/search        - Search (VULNERABLE)
```

### Audit Endpoints

```shell
GET    /api/audit/table/{tableName}  - Get audit logs by table
GET    /api/audit/operation/{operation} - Get by operation
POST   /api/audit/log               - Log action
POST   /api/audit/export            - Export (VULNERABLE)
POST   /api/audit/email             - Send email (VULNERABLE)
```

### Security Endpoints

```shell
POST   /api/security/login          - Login (VULNERABLE)
GET    /api/security/access         - Check access (VULNERABLE)
POST   /api/security/session        - Create session
GET    /api/security/permissions    - Get permissions
```

## Building

### Prerequisites

- Java 21
- Maven 3.8+
- Oracle Database (for running)

### Build

```bash
mvn clean package
```

### Run

```bash
# Set database credentials
export DB_USERNAME=hr_user
export DB_PASSWORD=hr_password

mvn spring-boot:run
```

## Testing

Run unit tests:

```bash
mvn test
```

## Dependencies

- Spring Boot 3.2.3
- Spring Data JDBC
- Oracle JDBC Driver (ojdbc11)
- Lombok
- JUnit 5

## Database Connection

Default connection properties (override in `application.yml` or environment):

```shell
URL:      jdbc:oracle:thin:@localhost:1521:ORCL
Username: hr_user
Password: hr_password
```

## Scanning for Vulnerabilities

This Java code can be scanned by various security analysis tools:

### Static Analysis

- SonarQube
- Checkmarx
- Fortify
- SpotBugs

### Dynamic Analysis

- OWASP ZAP
- Burp Suite
- Acunetix

### Code Review

- Manual code review using the annotations as guides
- Focus on vulnerable methods marked with comments

## Safe Implementation Examples

The codebase includes both vulnerable and safe patterns:

**Safe**: `EmployeeService.getEmployeeById()` - Uses repository with parameterized queries

**Vulnerable**: `EmployeeService.searchEmployeesVulnerable()` - Concatenates user input

## Security Best Practices

To remediate the vulnerabilities:

1. **SQL Injection**: Use parameterized queries/prepared statements
2. **Hardcoded Credentials**: Use external configuration and password managers
3. **Path Manipulation**: Validate and whitelist file paths
4. **Argument Injection**: Encode/escape parameters appropriately

## Further Information

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Spring Security](https://spring.io/projects/spring-security)
- [JDBC Best Practices](https://docs.oracle.com/en/database/oracle/oracle-database/latest/)

## Notes

- This is a sample project for **testing and learning purposes**
- Vulnerabilities are intentional for demonstrating security scanning
- Never use these patterns in production
- This application requires the PL/SQL database schema to be deployed first
