package com.example.hr.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.CallableStatement;
import java.sql.Types;

/**
 * Service for security operations
 *
 * Handles authentication, authorization, and session management
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SecurityService {

    private final JdbcTemplate jdbcTemplate;

    /**
     * Authenticate user against database
     * Calls PL/SQL function: hr_security_pkg.authenticate_user()
     * VULNERABLE: This function has hardcoded credentials and SQL injection issues
     */
    public boolean authenticateUser(String username, String password) {
        log.info("Authenticating user: {}", username);

        String sql = "{ ? = call hr_security_pkg.authenticate_user(?, ?) }";

        try {
            Boolean result = jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                cs.registerOutParameter(1, Types.BOOLEAN);
                cs.setString(2, username);
                // VULNERABLE: Password passed in plain text
                // CWE-798: Hardcoded credentials and weak authentication
                cs.setString(3, password);
                cs.execute();
                return cs.getBoolean(1);
            });

            if (result != null && result) {
                log.info("User authenticated successfully");
            } else {
                log.warn("Authentication failed for user: {}", username);
            }
            return result != null && result;
        } catch (Exception e) {
            log.error("Error authenticating user", e);
            return false;
        }
    }

    /**
     * Check employee access to resource
     * Calls PL/SQL function: hr_security_pkg.check_employee_access()
     * VULNERABLE: Dynamic SQL injection in PL/SQL
     */
    public boolean checkAccess(Long empId, String resource) {
        log.info("Checking access for employee {} to resource: {}", empId, resource);

        String sql = "{ ? = call hr_security_pkg.check_employee_access(?, ?) }";

        try {
            Boolean result = jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                cs.registerOutParameter(1, Types.BOOLEAN);
                cs.setLong(2, empId);
                // VULNERABLE: Resource parameter used in dynamic SQL in PL/SQL
                // CWE-89: SQL Injection
                cs.setString(3, resource);
                cs.execute();
                return cs.getBoolean(1);
            });

            return result != null && result;
        } catch (Exception e) {
            log.error("Error checking access", e);
            return false;
        }
    }

    /**
     * Create user session
     * Calls PL/SQL procedure: hr_security_pkg.create_user_session()
     */
    public void createSession(Long empId, String ipAddress) {
        log.info("Creating session for employee: {} from IP: {}", empId, ipAddress);

        String sql = "BEGIN hr_security_pkg.create_user_session(?, ?); END;";

        try {
            jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                cs.setLong(1, empId);
                cs.setString(2, ipAddress);
                cs.execute();
                return null;
            });
            log.info("Session created successfully");
        } catch (Exception e) {
            log.error("Error creating session", e);
            throw new RuntimeException("Failed to create session", e);
        }
    }

    /**
     * Get employee permissions
     * Calls PL/SQL function: hr_security_pkg.get_employee_permissions()
     */
    public String getEmployeePermissions(Long empId) {
        log.info("Retrieving permissions for employee: {}", empId);

        String sql = "{ ? = call hr_security_pkg.get_employee_permissions(?) }";

        try {
            return jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                cs.registerOutParameter(1, Types.VARCHAR);
                cs.setLong(2, empId);
                cs.execute();
                return cs.getString(1);
            });
        } catch (Exception e) {
            log.error("Error retrieving permissions", e);
            return "";
        }
    }

}
