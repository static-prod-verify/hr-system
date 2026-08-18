package com.example.hr.service;

import com.example.hr.model.AuditLog;
import com.example.hr.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.CallableStatement;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Service for audit operations
 *
 * Handles audit logging and compliance reporting
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository auditLogRepository;
    private final JdbcTemplate jdbcTemplate;

    /**
     * Get audit logs by table name
     */
    public List<AuditLog> getAuditLogsByTable(String tableName) {
        log.info("Fetching audit logs for table: {}", tableName);
        return auditLogRepository.findByTableName(tableName);
    }

    /**
     * Get audit logs by operation
     */
    public List<AuditLog> getAuditLogsByOperation(String operation) {
        log.info("Fetching audit logs for operation: {}", operation);
        return auditLogRepository.findByOperation(operation);
    }

    /**
     * Log an action to the audit table
     * Calls PL/SQL procedure: hr_audit_pkg.log_action()
     */
    public void logAction(String tableName, String action, Long recordId, String details) {
        log.info("Logging action: {} on {} (ID: {})", action, tableName, recordId);

        String sql = "BEGIN hr_audit_pkg.log_action(?, ?, ?, ?); END;";

        try {
            jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                cs.setString(1, tableName);
                cs.setString(2, action);
                cs.setLong(3, recordId);
                cs.setString(4, details);
                cs.execute();
                return null;
            });
        } catch (Exception e) {
            log.error("Error logging action", e);
            throw new RuntimeException("Failed to log action", e);
        }
    }

    /**
     * Export audit log to file
     * VULNERABLE: Calls PL/SQL procedure with unvalidated file path
     * This demonstrates CWE-73 Path Manipulation
     */
    public void exportAuditLogVulnerable(String filePath, LocalDateTime dateFrom, LocalDateTime dateTo) {
        log.warn("Exporting audit log to: {} (VULNERABLE TO PATH MANIPULATION)", filePath);

        String sql = "BEGIN hr_audit_pkg.export_audit_log(?, ?, ?); END;";

        try {
            jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                // VULNERABLE: filePath is passed directly to UTL_FILE operations
                // CWE-73: Path Manipulation / Directory Traversal
                cs.setString(1, filePath);
                cs.setObject(2, dateFrom);
                cs.setObject(3, dateTo);
                cs.execute();
                return null;
            });
            log.info("Audit log exported successfully");
        } catch (Exception e) {
            log.error("Error exporting audit log", e);
            throw new RuntimeException("Failed to export audit log", e);
        }
    }

    /**
     * Send audit email notification
     * VULNERABLE: Calls PL/SQL procedure with tainted email parameters
     * This demonstrates CWE-88 Argument Injection
     */
    public void sendAuditEmailVulnerable(String recipient, String subject, String body) {
        log.warn("Sending audit email to: {} (VULNERABLE TO ARGUMENT INJECTION)", recipient);

        String sql = "BEGIN hr_audit_pkg.send_audit_email(?, ?, ?); END;";

        try {
            jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                // VULNERABLE: Email parameters used without encoding
                // CWE-88: Argument Injection - could inject email headers
                cs.setString(1, recipient);
                cs.setString(2, subject);
                cs.setString(3, body);
                cs.execute();
                return null;
            });
            log.info("Audit email sent successfully");
        } catch (Exception e) {
            log.error("Error sending audit email", e);
            throw new RuntimeException("Failed to send audit email", e);
        }
    }

}
