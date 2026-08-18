package com.example.hr;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * HR System Spring Boot Application
 *
 * Main entry point for the HR management system that integrates
 * with Oracle PL/SQL backend for employee, salary, and audit operations.
 */
@SpringBootApplication
public class HrSystemApplication {

    public static void main(String[] args) {
        SpringApplication.run(HrSystemApplication.class, args);
    }

}
