package com.example.hr.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;

import java.time.LocalDateTime;

/**
 * Audit log entity for tracking database changes
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditLog {

    @Id
    private Long auditId;

    private String tableName;
    private String operation;
    private Long recordId;
    private LocalDateTime timestamp;
    private String userId;
    private String oldValues;
    private String newValues;
    private String ipAddress;
    private String details;

}
