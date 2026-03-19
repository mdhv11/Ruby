# Employee Management System — Database Schema

---

## Organization
| Column   | Notes                  |
|----------|------------------------|
| org_id   | PK                     |
| name     |                        |
| industry |                        |
| ceo      |                        |
| address  |                        |

---

## Department
| Column           | Notes                          |
|------------------|--------------------------------|
| dept_id          | PK                             |
| org_id           | FK → Organization              |
| name             |                                |
| manager          | FK → Employee                  |
| working_days     | array of days                  |
| overtime_pay_per_hour |                           |

---

## Role
| Column      | Notes                          |
|-------------|--------------------------------|
| role_id     | PK                             |
| org_id      | FK → Organization              |
| dept_id     | FK → Department                |
| name        |                                |
| description |                                |

---

## Employee
| Column             | Notes                                       |
|--------------------|---------------------------------------------|
| emp_id             | PK                                          |
| dept_id            | FK → Department (current dept)              |
| role_id            | FK → Role (current role)                    |
| name               |                                             |
| address            |                                             |
| phone              |                                             |
| email              |                                             |
| date_of_birth      |                                             |
| gender             | enum: male / female                         |
| salary                                                          |
| joining_date       |                                             |
| resignation_date   |                                             |
| status             | enum: active / on_leave / terminated / resigned |
| termination_reason |                                             |

---

## Employee_Department_History
| Column     | Notes             |
|------------|-------------------|
| emp_id     | FK → Employee     |
| dept_id    | FK → Department   |
| start_date |                   |
| end_date   | null = current    |

---

## Employee_Role_History
| Column     | Notes         |
|------------|---------------|
| emp_id     | FK → Employee |
| role_id    | FK → Role     |
| start_date |               |
| end_date   | null = current|

---

## Leave_Policy
| Column       | Notes                              |
|--------------|------------------------------------|
| policy_id    | PK                                 |
| dept_id      | FK → Department (null = org-wide)  |
| leave_type   | enum: paid / unpaid                |
| days_allowed |                                    |
| carry_forward| bool                               |

---

## Leave_Balance
| Column        | Notes                    |
|---------------|--------------------------|
| emp_id        | FK → Employee            |
| policy_id     | FK → Leave_Policy        |
| year          |                          |
| total_allowed |                          |
| used          |                          |
| remaining     | derived: total - used    |

---

## Leaves
| Column      | Notes                                  |
|-------------|----------------------------------------|
| leave_id    | PK                                     |
| emp_id      | FK → Employee                          |
| policy_id   | FK → Leave_Policy                      |
| start_date  |                                        |
| end_date    |                                        |
| reason      |                                        |
| status      | enum: pending / approved / rejected    |
| approved_by | FK → Employee                          |

---

## Attendance
| Column         | Notes                                  |
|----------------|----------------------------------------|
| attendance_id  | PK                                     |
| emp_id         | FK → Employee                          |
| date           |                                        |
| check_in_time  |                                        |
| check_out_time |                                        |
| status         | enum: present / absent / half_day      |
| total_hours    | derived from check-in/out              |
| overtime_hours | hours beyond standard shift            |

---

## Project
| Column          | Notes                                      |
|-----------------|--------------------------------------------|
| project_id      | PK                                         |
| dept_id         | FK → Department                            |
| project_name    |                                            |
| project_manager | FK → Employee                              |
| start_date      |                                            |
| end_date        |                                            |
| status          | enum: assigned / in_progress / completed   |

---

## Employee_Project
| Column        | Notes              |
|---------------|--------------------|
| emp_id        | FK → Employee      |
| project_id    | FK → Project       |
| project_role  | varchar (e.g. "Tech Lead", "QA") |
| assigned_date |                    |

---

## SalaryStructure  *(blueprint, per Role)*
| Column       | Notes          |
|--------------|----------------|
| structure_id | PK             |
| role_id      | FK → Role      |
| basic_salary |                |
| bonus        |                |
| tax_percent  |                |
| deductions   |                |

---

## Payslip  *(monthly record per Employee)*
| Column                  | Notes                   |
|-------------------------|-------------------------|
| payslip_id              | PK                      |
| emp_id                  | FK → Employee           |
| structure_id            | FK → SalaryStructure    |
| month                   |                         |
| year                    |                         |
| unpaid_leave_deduction  |                         |
| overtime_bonus          | from Attendance         |
| net_salary              |                         |
| generated_date          |                         |

---

## Payroll  *(actual disbursement record)*
| Column          | Notes              |
|-----------------|--------------------|
| payroll_id      | PK                 |
| payslip_id      | FK → Payslip (1:1) |
| amount_disbursed|                    |
| date            |                    |

---

## Performance_Review
| Column      | Notes             |
|-------------|-------------------|
| review_id   | PK                |
| emp_id      | FK → Employee     |
| reviewer_id | FK → Employee     |
| review_date |                   |
| rating      | int               |
| feedback    |                   |

---

## Asset
| Column        | Notes                                          |
|---------------|------------------------------------------------|
| asset_id      | PK                                             |
| asset_name    |                                                |
| type          |                                                |
| purchase_date |                                                |
| status        | enum: assigned / idle / in_repair / sold       |

---

## Asset_Assignment_History
| Column        | Notes                        |
|---------------|------------------------------|
| asset_id      | FK → Asset                   |
| emp_id        | FK → Employee                |
| assigned_date |                              |
| returned_date | null = currently assigned    |