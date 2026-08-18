package com.example.hr.controller;

import com.example.hr.model.AuditLog;
import com.example.hr.service.AuditService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * REST Controller for audit operations
 *
 * Provides API endpoints for audit logging and compliance reporting
 */
@Slf4j
@RestController
@RequestMapping("/audit")
@RequiredArgsConstructor
public class AuditController {

    private final AuditService auditService;

    /**
     * GET /api/audit/table/{tableName}
     * Retrieve audit logs for specific table
     */
    @GetMapping("/table/{tableName}")
    public ResponseEntity<List<AuditLog>> getAuditLogsByTable(@PathVariable String tableName) {
        log.info("GET /audit/table/{}", tableName);
        List<AuditLog> logs = auditService.getAuditLogsByTable(tableName);
        return ResponseEntity.ok(logs);
    }

    /**
     * GET /api/audit/operation/{operation}
     * Retrieve audit logs by operation type
     */
    @GetMapping("/operation/{operation}")
    public ResponseEntity<List<AuditLog>> getAuditLogsByOperation(@PathVariable String operation) {
        log.info("GET /audit/operation/{}", operation);
        List<AuditLog> logs = auditService.getAuditLogsByOperation(operation);
        return ResponseEntity.ok(logs);
    }

    /**
     * POST /api/audit/log
     * Log an action to the audit table
     */
    @PostMapping("/log")
    public ResponseEntity<Void> logAction(
            @RequestParam String tableName,
            @RequestParam String action,
            @RequestParam Long recordId,
            @RequestParam(required = false) String details) {
        log.info("POST /audit/log - {} on {} (ID: {})", action, tableName, recordId);
        try {
            auditService.logAction(tableName, action, recordId, details != null ? details : "");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (Exception e) {
            log.error("Error logging action", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * POST /api/audit/export
     * VULNERABLE: Export audit logs to file with unvalidated path
     * This endpoint demonstrates path manipulation vulnerability
     */
    @PostMapping("/export")
    public ResponseEntity<Void> exportAuditLog(
            @RequestParam String filePath,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateFrom,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateTo) {
        log.warn("POST /audit/export?filePath={} - VULNERABLE TO PATH MANIPULATION", filePath);
        try {
            // VULNERABLE: filePath passed directly to PL/SQL file operations
            // CWE-73: Path Manipulation / Directory Traversal
            auditService.exportAuditLogVulnerable(filePath, dateFrom, dateTo);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Error exporting audit log", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * POST /api/audit/email
     * VULNERABLE: Send audit email with unvalidated parameters
     * This endpoint demonstrates argument injection vulnerability
     */
    @PostMapping("/email")
    public ResponseEntity<Void> sendAuditEmail(
            @RequestParam String recipient,
            @RequestParam String subject,
            @RequestParam String body) {
        log.warn("POST /audit/email?recipient={} - VULNERABLE TO ARGUMENT INJECTION", recipient);
        try {
            // VULNERABLE: Email parameters could be used to inject headers
            // CWE-88: Argument Injection
            auditService.sendAuditEmailVulnerable(recipient, subject, body);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Error sending audit email", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

}
