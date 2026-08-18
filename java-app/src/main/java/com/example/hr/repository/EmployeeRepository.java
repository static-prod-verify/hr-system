package com.example.hr.repository;

import com.example.hr.model.Employee;
import org.springframework.data.jdbc.repository.query.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for Employee database operations
 *
 * This repository provides JDBC-based access to employee data,
 * calling PL/SQL functions and procedures in the database.
 */
@Repository
public interface EmployeeRepository extends CrudRepository<Employee, Long> {

    /**
     * Find all active employees
     */
    @Query("SELECT * FROM EMPLOYEES WHERE is_active = 'Y' ORDER BY last_name, first_name")
    List<Employee> findAllActive();

    /**
     * Find employees by department
     */
    @Query("SELECT * FROM EMPLOYEES WHERE dept_id = :deptId AND is_active = 'Y'")
    List<Employee> findByDepartment(@Param("deptId") Long deptId);

    /**
     * Find employee by email
     */
    @Query("SELECT * FROM EMPLOYEES WHERE email = :email")
    Optional<Employee> findByEmail(@Param("email") String email);

    /**
     * Find employees by job title
     */
    @Query("SELECT * FROM EMPLOYEES WHERE job_title LIKE :jobTitle AND is_active = 'Y'")
    List<Employee> findByJobTitle(@Param("jobTitle") String jobTitle);

}
