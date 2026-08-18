package com.example.hr.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Employee entity representing a company employee
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Employee {

    @Id
    private Long empId;

    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private LocalDate hireDate;
    private BigDecimal salary;
    private BigDecimal commissionPct;
    private Long deptId;
    private Long managerId;
    private String jobTitle;
    private String isActive;

    public String getFullName() {
        return firstName + " " + lastName;
    }

}
