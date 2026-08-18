-- HR System - Calculate Bonus Function
-- SAFE IMPLEMENTATION - Demonstrates proper PL/SQL patterns

CREATE OR REPLACE FUNCTION calculate_bonus(
    p_emp_id NUMBER,
    p_performance_rating NUMBER,
    p_years_of_service NUMBER
) RETURN NUMBER
AS
    v_base_salary NUMBER;
    v_bonus_amount NUMBER := 0;
    v_bonus_percentage NUMBER := 0;
    v_tenure_multiplier NUMBER := 1.0;
    v_performance_multiplier NUMBER := 1.0;
BEGIN
    -- Validate input parameters
    IF p_emp_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20500, 'Employee ID cannot be null');
    END IF;

    IF p_performance_rating < 1 OR p_performance_rating > 5 THEN
        RAISE_APPLICATION_ERROR(-20501, 'Performance rating must be between 1 and 5');
    END IF;

    IF p_years_of_service < 0 THEN
        RAISE_APPLICATION_ERROR(-20502, 'Years of service cannot be negative');
    END IF;

    -- Get base salary (safe query)
    SELECT salary INTO v_base_salary
    FROM EMPLOYEES
    WHERE emp_id = p_emp_id
    AND is_active = 'Y';

    -- Calculate performance multiplier
    -- Using CASE statement (safe, no injection risk)
    v_performance_multiplier := CASE
        WHEN p_performance_rating = 5 THEN 1.5
        WHEN p_performance_rating = 4 THEN 1.25
        WHEN p_performance_rating = 3 THEN 1.0
        WHEN p_performance_rating = 2 THEN 0.75
        WHEN p_performance_rating = 1 THEN 0.5
        ELSE 1.0
    END;

    -- Calculate tenure multiplier (years of service)
    v_tenure_multiplier := CASE
        WHEN p_years_of_service >= 10 THEN 1.3
        WHEN p_years_of_service >= 5 THEN 1.2
        WHEN p_years_of_service >= 2 THEN 1.1
        ELSE 1.0
    END;

    -- Base bonus is 5% of salary
    v_bonus_percentage := 0.05;

    -- Apply multipliers
    v_bonus_amount := v_base_salary *
                     v_bonus_percentage *
                     v_performance_multiplier *
                     v_tenure_multiplier;

    -- Cap bonus at 50% of salary
    IF v_bonus_amount > (v_base_salary * 0.5) THEN
        v_bonus_amount := v_base_salary * 0.5;
    END IF;

    -- Round to 2 decimal places
    v_bonus_amount := ROUND(v_bonus_amount, 2);

    RETURN v_bonus_amount;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;  -- Return 0 if employee not found
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20503, 'Error calculating bonus: ' || SQLERRM);
END calculate_bonus;
/

COMMIT;
