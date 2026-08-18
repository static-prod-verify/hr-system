package com.example.hr.controller;

import com.example.hr.model.Employee;
import com.example.hr.service.EmployeeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * REST Controller for employee management endpoints
 *
 * Provides API endpoints for CRUD operations on employees,
 * delegating to service layer which calls PL/SQL backend.
 */
@Slf4j
@RestController
@RequestMapping("/employees")
@RequiredArgsConstructor
public class EmployeeController {

    private final EmployeeService employeeService;

    /**
     * GET /api/employees
     * Retrieve all active employees
     */
    @GetMapping
    public ResponseEntity<List<Employee>> getAllEmployees() {
        log.info("GET /employees");
        List<Employee> employees = employeeService.getAllEmployees();
        return ResponseEntity.ok(employees);
    }

    /**
     * GET /api/employees/{id}
     * Retrieve employee by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<Employee> getEmployeeById(@PathVariable Long id) {
        log.info("GET /employees/{}", id);
        return employeeService.getEmployeeById(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /**
     * GET /api/employees/department/{deptId}
     * Retrieve employees by department
     */
    @GetMapping("/department/{deptId}")
    public ResponseEntity<List<Employee>> getEmployeesByDepartment(@PathVariable Long deptId) {
        log.info("GET /employees/department/{}", deptId);
        List<Employee> employees = employeeService.getEmployeesByDepartment(deptId);
        return ResponseEntity.ok(employees);
    }

    /**
     * POST /api/employees
     * Create new employee
     */
    @PostMapping
    public ResponseEntity<Void> createEmployee(@RequestBody Employee employee) {
        log.info("POST /employees - creating employee: {}", employee.getFullName());
        try {
            employeeService.createEmployee(employee);
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (Exception e) {
            log.error("Error creating employee", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * PUT /api/employees/{id}/salary
     * Update employee salary
     */
    @PutMapping("/{id}/salary")
    public ResponseEntity<Void> updateSalary(
            @PathVariable Long id,
            @RequestParam BigDecimal newSalary,
            @RequestParam(required = false) String reason) {
        log.info("PUT /employees/{}/salary - new salary: {}", id, newSalary);
        try {
            employeeService.updateSalary(id, newSalary, reason != null ? reason : "Salary adjustment");
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Error updating salary", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * DELETE /api/employees/{id}
     * Terminate employee
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> terminateEmployee(@PathVariable Long id) {
        log.info("DELETE /employees/{}", id);
        try {
            employeeService.terminateEmployee(id);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Error terminating employee", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/employees/{id}/bonus
     * Calculate bonus for employee
     */
    @GetMapping("/{id}/bonus")
    public ResponseEntity<BigDecimal> calculateBonus(
            @PathVariable Long id,
            @RequestParam BigDecimal performanceRating,
            @RequestParam BigDecimal yearsOfService) {
        log.info("GET /employees/{}/bonus", id);
        try {
            BigDecimal bonus = employeeService.calculateBonus(id, performanceRating, yearsOfService);
            return ResponseEntity.ok(bonus);
        } catch (Exception e) {
            log.error("Error calculating bonus", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/employees/search
     * VULNERABLE: Search employees with dynamic criteria
     * This endpoint demonstrates SQL injection vulnerability
     */
    @GetMapping("/search")
    public ResponseEntity<Void> searchEmployees(@RequestParam String criteria) {
        log.warn("GET /employees/search?criteria={} - VULNERABLE TO SQL INJECTION", criteria);
        try {
            // VULNERABLE: Criteria passed directly to PL/SQL dynamic query
            // CWE-89: SQL Injection
            employeeService.searchEmployeesVulnerable(criteria);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Error searching employees", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

}
