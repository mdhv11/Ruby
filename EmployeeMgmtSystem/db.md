Entities

1. Organisation
Organisation (
    org_id PK,
    name,
    field,
    ceo
)

One Organisation → Many Departments

2. Address
Address (
    address_id PK,
    house_no,
    street,
    city,
    state,
    zip_code
)

3. Department
Department (
    dept_id PK,
    org_id FK,
    name,
    head_emp_id FK
)

Relationships

Department → belongs to Organisation

Department Head → Employee

4. Job_Position
Job_Position (
    position_id PK,
    title,
    description,
    min_salary,
    max_salary
)

5. Employee
Employee (
    emp_id PK,
    dept_id FK,
    position_id FK,
    address_id FK,
    name,
    phone,
    email,
    hire_date
)

Relationships

Employee → belongs to Department

Employee → assigned a Job Position

Employee → has an Address

6. Payroll
Payroll (
    payroll_id PK,
    emp_id FK,
    basic_salary,
    bonus,
    tax,
    deductions,
    net_salary,
    pay_date
)

Relationship

One Employee → Many Payroll Records

7. Leave
Leave (
    leave_id PK,
    emp_id FK,
    leave_type,
    start_date,
    end_date,
    reason,
    status,
    approved_by FK
)
Relationships

Leave → belongs to Employee

Leave approved by → Employee (self relationship)

8. Attendance
Attendance (
    attendance_id PK,
    emp_id FK,
    date,
    check_in_time,
    check_out_time,
    status
)

9. Project
Project (
    project_id PK,
    dept_id FK,
    project_name,
    start_date,
    end_date,
    budget
)


10.  Employee_Project
Employee_Project (
    emp_id FK,
    project_id FK,
    role,
    assigned_date,
    PRIMARY KEY (emp_id, project_id)
)

Relationships

One Employee → Many Projects

One Project → Many Employees

11.  Performance_Review
Performance_Review (
    review_id PK,
    emp_id FK,
    reviewer_id FK,
    review_date,
    rating,
    feedback
)

Relationships

Employee → reviewed by another Employee
