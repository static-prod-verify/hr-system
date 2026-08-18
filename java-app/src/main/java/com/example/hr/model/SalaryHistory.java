package com.example.hr.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Salary history tracking entity
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SalaryHistory {

    @Id
    private Long salHistId;

    private Long empId;
    private BigDecimal oldSalary;
    private BigDecimal newSalary;
    private LocalDate changeDate;
    private String changedBy;
    private String changeReason;
    private LocalDate effectiveDate;

}
