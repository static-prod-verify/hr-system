package com.example.hr.repository;

import com.example.hr.model.AuditLog;
import org.springframework.data.jdbc.repository.query.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repository for Audit Log database operations
 */
@Repository
public interface AuditLogRepository extends CrudRepository<AuditLog, Long> {

    /**
     * Find audit logs by table name
     */
    @Query("SELECT * FROM AUDIT_LOG WHERE table_name = :tableName ORDER BY timestamp DESC")
    List<AuditLog> findByTableName(@Param("tableName") String tableName);

    /**
     * Find audit logs by operation type
     */
    @Query("SELECT * FROM AUDIT_LOG WHERE operation = :operation ORDER BY timestamp DESC")
    List<AuditLog> findByOperation(@Param("operation") String operation);

    /**
     * Find audit logs by record ID and table
     */
    @Query("SELECT * FROM AUDIT_LOG WHERE record_id = :recordId AND table_name = :tableName ORDER BY timestamp DESC")
    List<AuditLog> findByRecordIdAndTable(@Param("recordId") Long recordId, @Param("tableName") String tableName);

}
