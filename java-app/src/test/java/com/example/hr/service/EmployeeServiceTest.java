package com.example.hr.service;

import com.example.hr.model.Employee;
import com.example.hr.repository.EmployeeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for EmployeeService
 */
@ExtendWith(MockitoExtension.class)
class EmployeeServiceTest {

    @Mock
    private EmployeeRepository employeeRepository;

    @Mock
    private JdbcTemplate jdbcTemplate;

    private EmployeeService employeeService;

    @BeforeEach
    void setUp() {
        employeeService = new EmployeeService(employeeRepository, jdbcTemplate);
    }

    @Test
    void testGetAllEmployees() {
        // Arrange
        List<Employee> expectedEmployees = new ArrayList<>();
        expectedEmployees.add(Employee.builder()
                .empId(1000L)
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@example.com")
                .salary(new BigDecimal("75000"))
                .build());

        when(employeeRepository.findAllActive()).thenReturn(expectedEmployees);

        // Act
        List<Employee> result = employeeService.getAllEmployees();

        // Assert
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("John", result.get(0).getFirstName());
        verify(employeeRepository, times(1)).findAllActive();
    }

    @Test
    void testGetEmployeeById() {
        // Arrange
        Employee expectedEmployee = Employee.builder()
                .empId(1000L)
                .firstName("Jane")
                .lastName("Smith")
                .email("jane.smith@example.com")
                .salary(new BigDecimal("85000"))
                .build();

        when(employeeRepository.findById(1000L)).thenReturn(Optional.of(expectedEmployee));

        // Act
        Optional<Employee> result = employeeService.getEmployeeById(1000L);

        // Assert
        assertTrue(result.isPresent());
        assertEquals("Jane", result.get().getFirstName());
        verify(employeeRepository, times(1)).findById(1000L);
    }

    @Test
    void testGetEmployeesByDepartment() {
        // Arrange
        List<Employee> expectedEmployees = new ArrayList<>();
        expectedEmployees.add(Employee.builder()
                .empId(1001L)
                .firstName("Bob")
                .lastName("Johnson")
                .deptId(100L)
                .build());

        when(employeeRepository.findByDepartment(100L)).thenReturn(expectedEmployees);

        // Act
        List<Employee> result = employeeService.getEmployeesByDepartment(100L);

        // Assert
        assertEquals(1, result.size());
        assertEquals("Bob", result.get(0).getFirstName());
        verify(employeeRepository, times(1)).findByDepartment(100L);
    }

}
