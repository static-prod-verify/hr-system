package com.example.hr.controller;

import com.example.hr.service.SecurityService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller for security operations
 *
 * Provides API endpoints for authentication and authorization
 */
@Slf4j
@RestController
@RequestMapping("/security")
@RequiredArgsConstructor
public class SecurityController {

    private final SecurityService securityService;

    /**
     * POST /api/security/login
     * Authenticate user
     * VULNERABLE: Calls PL/SQL with hardcoded credentials and weak authentication
     */
    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestParam String username, @RequestParam String password) {
        log.info("POST /security/login - user: {}", username);
        try {
            // VULNERABLE: Passwords sent in plain text
            // CWE-798: Hardcoded credentials in PL/SQL
            boolean authenticated = securityService.authenticateUser(username, password);
            if (authenticated) {
                return ResponseEntity.ok("Authentication successful");
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication failed");
            }
        } catch (Exception e) {
            log.error("Error authenticating user", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Authentication error");
        }
    }

    /**
     * GET /api/security/access
     * Check employee access to resource
     * VULNERABLE: Dynamic SQL in PL/SQL backend
     */
    @GetMapping("/access")
    public ResponseEntity<Boolean> checkAccess(
            @RequestParam Long empId,
            @RequestParam String resource) {
        log.warn("GET /security/access?empId={}&resource={} - VULNERABLE TO SQL INJECTION", empId, resource);
        try {
            // VULNERABLE: Resource parameter used in dynamic SQL
            // CWE-89: SQL Injection in PL/SQL
            boolean hasAccess = securityService.checkAccess(empId, resource);
            return ResponseEntity.ok(hasAccess);
        } catch (Exception e) {
            log.error("Error checking access", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * POST /api/security/session
     * Create user session
     */
    @PostMapping("/session")
    public ResponseEntity<Void> createSession(
            @RequestParam Long empId,
            @RequestParam String ipAddress) {
        log.info("POST /security/session - employee: {}, IP: {}", empId, ipAddress);
        try {
            securityService.createSession(empId, ipAddress);
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (Exception e) {
            log.error("Error creating session", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/security/permissions
     * Get employee permissions
     */
    @GetMapping("/permissions")
    public ResponseEntity<String> getPermissions(@RequestParam Long empId) {
        log.info("GET /security/permissions - employee: {}", empId);
        try {
            String permissions = securityService.getEmployeePermissions(empId);
            return ResponseEntity.ok(permissions);
        } catch (Exception e) {
            log.error("Error retrieving permissions", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

}
