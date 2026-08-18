package com.example.hr.service;

import com.example.hr.model.Employee;
import com.example.hr.repository.EmployeeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Types;
import java.util.List;
import java.util.Optional;

/**
 * Service for employee management operations
 *
 * This service calls both SQL queries and PL/SQL procedures/functions
 * from the Oracle database backend.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final JdbcTemplate jdbcTemplate;

    /**
     * Get all active employees
     */
    public List<Employee> getAllEmployees() {
        log.info("Fetching all active employees");
        return employeeRepository.findAllActive();
    }

    /**
     * Get employee by ID
     */
    public Optional<Employee> getEmployeeById(Long empId) {
        log.info("Fetching employee with ID: {}", empId);
        return employeeRepository.findById(empId);
    }

    /**
     * Get employees by department
     */
    public List<Employee> getEmployeesByDepartment(Long deptId) {
        log.info("Fetching employees in department: {}", deptId);
        return employeeRepository.findByDepartment(deptId);
    }

    /**
     * Create new employee
     * Calls PL/SQL procedure: hr_employee_pkg.create_employee()
     */
    public void createEmployee(Employee employee) {
        log.info("Creating new employee: {} {}", employee.getFirstName(), employee.getLastName());

        String sql = "BEGIN hr_employee_pkg.create_employee(?, ?, ?, ?, ?); END;";

        try {
            jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                cs.setString(1, employee.getFirstName());
                cs.setString(2, employee.getLastName());
                cs.setString(3, employee.getEmail());
                cs.setBigDecimal(4, employee.getSalary());
                cs.setLong(5, employee.getDeptId());
                cs.execute();
                return null;
            });
            log.info("Employee created successfully");
        } catch (Exception e) {
            log.error("Error creating employee", e);
            throw new RuntimeException("Failed to create employee", e);
        }
    }

    /**
     * Update employee salary
     * Calls PL/SQL procedure: hr_employee_pkg.update_employee_salary()
     */
    public void updateSalary(Long empId, BigDecimal newSalary, String reason) {
        log.info("Updating salary for employee {}: {}", empId, newSalary);

        String sql = "BEGIN hr_employee_pkg.update_employee_salary(?, ?, ?); END;";

        try {
            jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                cs.setLong(1, empId);
                cs.setBigDecimal(2, newSalary);
                cs.setString(3, reason);
                cs.execute();
                return null;
            });
            log.info("Salary updated successfully");
        } catch (Exception e) {
            log.error("Error updating salary for employee {}", empId, e);
            throw new RuntimeException("Failed to update salary", e);
        }
    }

    /**
     * Terminate employee
     * Calls PL/SQL procedure: hr_employee_pkg.terminate_employee()
     */
    public void terminateEmployee(Long empId) {
        log.info("Terminating employee: {}", empId);

        String sql = "BEGIN hr_employee_pkg.terminate_employee(?, SYSDATE); END;";

        try {
            jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                cs.setLong(1, empId);
                cs.execute();
                return null;
            });
            log.info("Employee terminated successfully");
        } catch (Exception e) {
            log.error("Error terminating employee {}", empId, e);
            throw new RuntimeException("Failed to terminate employee", e);
        }
    }

    /**
     * Calculate bonus for employee
     * Calls PL/SQL function: calculate_bonus()
     */
    public BigDecimal calculateBonus(Long empId, BigDecimal performanceRating, BigDecimal yearsOfService) {
        log.info("Calculating bonus for employee {}", empId);

        String sql = "{ ? = call calculate_bonus(?, ?, ?) }";

        try {
            return jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                cs.registerOutParameter(1, Types.NUMERIC);
                cs.setLong(2, empId);
                cs.setBigDecimal(3, performanceRating);
                cs.setBigDecimal(4, yearsOfService);
                cs.execute();
                return cs.getBigDecimal(1);
            });
        } catch (Exception e) {
            log.error("Error calculating bonus for employee {}", empId, e);
            throw new RuntimeException("Failed to calculate bonus", e);
        }
    }

    /**
     * Search employees by criteria
     * VULNERABLE: Calls PL/SQL procedure with dynamic SQL
     * This demonstrates CWE-89 SQL Injection
     */
    public void searchEmployeesVulnerable(String searchCriteria) {
        log.warn("Searching employees with criteria: {} (VULNERABLE TO SQL INJECTION)", searchCriteria);

        String sql = "BEGIN hr_employee_pkg.search_employees(?, ?); END;";

        try {
            jdbcTemplate.execute(sql, (CallableStatement cs) -> {
                // VULNERABLE: searchCriteria is passed directly to dynamic SQL in PL/SQL
                // CWE-89: SQL Injection
                cs.setString(1, searchCriteria);
                cs.registerOutParameter(2, Types.OTHER);
                cs.execute();
                return null;
            });
        } catch (Exception e) {
            log.error("Error searching employees", e);
            throw new RuntimeException("Search failed", e);
        }
    }

}
