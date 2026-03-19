# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# db/seeds.rb

puts "Cleaning existing data..."
AssetAssignmentHistory.delete_all
Asset.delete_all
PerformanceReview.delete_all
Payroll.delete_all
Payslip.delete_all
SalaryStructure.delete_all
EmployeeProject.delete_all
Project.delete_all
Attendance.delete_all
Leave.delete_all
LeaveBalance.delete_all
LeavePolicy.delete_all
EmployeeRoleHistory.delete_all
EmployeeDepartmentHistory.delete_all
Employee.delete_all
Role.delete_all
Department.delete_all
Organization.delete_all

puts "Seeding..."

# ==============================================================================
# ORGANIZATION
# ==============================================================================

org = Organization.create!(
  name:     "TechCorp Solutions",
  industry: "Software",
  ceo:      "Arjun Mehta",
  address:  "101 Silicon Road, Bangalore, Karnataka 560001"
)

# ==============================================================================
# DEPARTMENTS — manager_id left nil for now (circular FK with employees)
# ==============================================================================

dept_eng = Department.create!(
  org_id:                org.org_id,
  name:                  "Engineering",
  manager_id:            nil,
  working_days:          %w[Monday Tuesday Wednesday Thursday Friday],
  overtime_pay_per_hour: 500.00
)

dept_hr = Department.create!(
  org_id:                org.org_id,
  name:                  "Human Resources",
  manager_id:            nil,
  working_days:          %w[Monday Tuesday Wednesday Thursday Friday],
  overtime_pay_per_hour: 400.00
)

dept_sales = Department.create!(
  org_id:                org.org_id,
  name:                  "Sales",
  manager_id:            nil,
  working_days:          %w[Monday Tuesday Wednesday Thursday Friday Saturday],
  overtime_pay_per_hour: 350.00
)

# ==============================================================================
# ROLES
# ==============================================================================

role_senior_dev = Role.create!(
  org_id:      org.org_id,
  dept_id:     dept_eng.dept_id,
  name:        "Senior Developer",
  description: "Leads technical development and code reviews"
)

role_junior_dev = Role.create!(
  org_id:      org.org_id,
  dept_id:     dept_eng.dept_id,
  name:        "Junior Developer",
  description: "Assists in development tasks under senior guidance"
)

role_hr_manager = Role.create!(
  org_id:      org.org_id,
  dept_id:     dept_hr.dept_id,
  name:        "HR Manager",
  description: "Oversees HR operations and employee relations"
)

role_hr_exec = Role.create!(
  org_id:      org.org_id,
  dept_id:     dept_hr.dept_id,
  name:        "HR Executive",
  description: "Handles recruitment and employee onboarding"
)

role_sales_manager = Role.create!(
  org_id:      org.org_id,
  dept_id:     dept_sales.dept_id,
  name:        "Sales Manager",
  description: "Manages sales team and client targets"
)

role_sales_exec = Role.create!(
  org_id:      org.org_id,
  dept_id:     dept_sales.dept_id,
  name:        "Sales Executive",
  description: "Drives sales and client acquisition"
)

# ==============================================================================
# EMPLOYEES
# ==============================================================================

emp_alice = Employee.create!(
  dept_id:           dept_eng.dept_id,
  name:              "Alice Fernandez",
  address:           "12 MG Road, Bangalore",
  phone:             "9876543210",
  email:             "alice@techcorp.com",
  date_of_birth:     "1990-03-15",
  gender:            "female",
  joining_date:      "2020-01-10",
  status:            "active"
)

emp_bob = Employee.create!(
  dept_id:           dept_eng.dept_id,
  name:              "Bob Sharma",
  address:           "45 Indiranagar, Bangalore",
  phone:             "9876543211",
  email:             "bob@techcorp.com",
  date_of_birth:     "1995-07-22",
  gender:            "male",
  joining_date:      "2021-06-01",
  status:            "active"
)

emp_charlie = Employee.create!(
  dept_id:           dept_eng.dept_id,
  name:              "Charlie D'Souza",
  address:           "78 Koramangala, Bangalore",
  phone:             "9876543212",
  email:             "charlie@techcorp.com",
  date_of_birth:     "1997-11-05",
  gender:            "male",
  joining_date:      "2022-03-15",
  status:            "active"
)

emp_ivan = Employee.create!(
  dept_id:           dept_eng.dept_id,
  name:              "Ivan Menon",
  address:           "44 Marathahalli, Bangalore",
  phone:             "9876543218",
  email:             "ivan@techcorp.com",
  date_of_birth:     "1992-02-28",
  gender:            "male",
  joining_date:      "2020-09-01",
  status:            "active"
)

emp_diana = Employee.create!(
  dept_id:           dept_hr.dept_id,
  name:              "Diana Kapoor",
  address:           "33 Whitefield, Bangalore",
  phone:             "9876543213",
  email:             "diana@techcorp.com",
  date_of_birth:     "1988-05-30",
  gender:            "female",
  joining_date:      "2019-08-01",
  status:            "active"
)

emp_ethan = Employee.create!(
  dept_id:           dept_hr.dept_id,
  name:              "Ethan Pillai",
  address:           "56 JP Nagar, Bangalore",
  phone:             "9876543214",
  email:             "ethan@techcorp.com",
  date_of_birth:     "1993-09-18",
  gender:            "male",
  joining_date:      "2021-01-15",
  status:            "active"
)

emp_jane = Employee.create!(
  dept_id:           dept_hr.dept_id,
  name:              "Jane Thomas",
  address:           "67 Jayanagar, Bangalore",
  phone:             "9876543219",
  email:             "jane@techcorp.com",
  date_of_birth:     "1989-06-20",
  gender:            "female",
  joining_date:      "2018-04-01",
  status:            "active"
)

emp_fatima = Employee.create!(
  dept_id:           dept_sales.dept_id,
  name:              "Fatima Sheikh",
  address:           "90 HSR Layout, Bangalore",
  phone:             "9876543215",
  email:             "fatima@techcorp.com",
  date_of_birth:     "1991-12-25",
  gender:            "female",
  joining_date:      "2020-05-01",
  status:            "active"
)

emp_george = Employee.create!(
  dept_id:           dept_sales.dept_id,
  name:              "George Nair",
  address:           "11 Bellandur, Bangalore",
  phone:             "9876543216",
  email:             "george@techcorp.com",
  date_of_birth:     "1996-04-10",
  gender:            "male",
  joining_date:      "2022-09-01",
  status:            "active"
)

# Resigned employee — dept transfer history included
emp_hannah = Employee.create!(
  dept_id:           dept_sales.dept_id,
  name:              "Hannah Reddy",
  address:           "22 Electronic City, Bangalore",
  phone:             "9876543217",
  email:             "hannah@techcorp.com",
  date_of_birth:     "1994-08-14",
  gender:            "female",
  joining_date:      "2021-11-01",
  resignation_date:  "2024-03-31",
  status:            "resigned"
)

# ==============================================================================
# ASSIGN DEPARTMENT MANAGERS — now that employees exist
# ==============================================================================

dept_eng.update!(manager_id:   emp_alice.emp_id)
dept_hr.update!(manager_id:    emp_diana.emp_id)
dept_sales.update!(manager_id: emp_fatima.emp_id)

# ==============================================================================
# EMPLOYEE DEPARTMENT HISTORIES
# end_date nil = currently in this department
# ==============================================================================

[
  { emp_id: emp_alice.emp_id,   dept_id: dept_eng.dept_id,   start_date: "2020-01-10", end_date: nil },
  { emp_id: emp_bob.emp_id,     dept_id: dept_eng.dept_id,   start_date: "2021-06-01", end_date: nil },
  { emp_id: emp_charlie.emp_id, dept_id: dept_eng.dept_id,   start_date: "2022-03-15", end_date: nil },
  # Ivan moved from HR → Engineering
  { emp_id: emp_ivan.emp_id,    dept_id: dept_hr.dept_id,    start_date: "2020-09-01", end_date: "2021-12-31" },
  { emp_id: emp_ivan.emp_id,    dept_id: dept_eng.dept_id,   start_date: "2022-01-01", end_date: nil },
  { emp_id: emp_diana.emp_id,   dept_id: dept_hr.dept_id,    start_date: "2019-08-01", end_date: nil },
  { emp_id: emp_ethan.emp_id,   dept_id: dept_hr.dept_id,    start_date: "2021-01-15", end_date: nil },
  { emp_id: emp_jane.emp_id,    dept_id: dept_hr.dept_id,    start_date: "2018-04-01", end_date: nil },
  { emp_id: emp_fatima.emp_id,  dept_id: dept_sales.dept_id, start_date: "2020-05-01", end_date: nil },
  { emp_id: emp_george.emp_id,  dept_id: dept_sales.dept_id, start_date: "2022-09-01", end_date: nil },
  # Hannah moved from HR → Sales before resigning
  { emp_id: emp_hannah.emp_id,  dept_id: dept_hr.dept_id,    start_date: "2021-11-01", end_date: "2022-10-31" },
  { emp_id: emp_hannah.emp_id,  dept_id: dept_sales.dept_id, start_date: "2022-11-01", end_date: "2024-03-31" },
].each { |r| EmployeeDepartmentHistory.create!(r) }

# ==============================================================================
# EMPLOYEE ROLE HISTORIES
# end_date nil = current role
# ==============================================================================

[
  { emp_id: emp_alice.emp_id,   role_id: role_senior_dev.role_id,   start_date: "2020-01-10", end_date: nil },
  { emp_id: emp_bob.emp_id,     role_id: role_junior_dev.role_id,   start_date: "2021-06-01", end_date: nil },
  { emp_id: emp_charlie.emp_id, role_id: role_junior_dev.role_id,   start_date: "2022-03-15", end_date: nil },
  # Ivan promoted from Junior → Senior
  { emp_id: emp_ivan.emp_id,    role_id: role_junior_dev.role_id,   start_date: "2020-09-01", end_date: "2022-12-31" },
  { emp_id: emp_ivan.emp_id,    role_id: role_senior_dev.role_id,   start_date: "2023-01-01", end_date: nil },
  { emp_id: emp_diana.emp_id,   role_id: role_hr_manager.role_id,   start_date: "2019-08-01", end_date: nil },
  { emp_id: emp_ethan.emp_id,   role_id: role_hr_exec.role_id,      start_date: "2021-01-15", end_date: nil },
  { emp_id: emp_jane.emp_id,    role_id: role_hr_manager.role_id,   start_date: "2018-04-01", end_date: nil },
  { emp_id: emp_fatima.emp_id,  role_id: role_sales_manager.role_id, start_date: "2020-05-01", end_date: nil },
  { emp_id: emp_george.emp_id,  role_id: role_sales_exec.role_id,   start_date: "2022-09-01", end_date: nil },
  # Hannah moved roles with department
  { emp_id: emp_hannah.emp_id,  role_id: role_hr_exec.role_id,      start_date: "2021-11-01", end_date: "2022-10-31" },
  { emp_id: emp_hannah.emp_id,  role_id: role_sales_exec.role_id,   start_date: "2022-11-01", end_date: "2024-03-31" },
].each { |r| EmployeeRoleHistory.create!(r) }

# ==============================================================================
# LEAVE POLICIES (per department)
# ==============================================================================

policy_paid_eng   = LeavePolicy.create!(dept_id: dept_eng.dept_id,   leave_type: "paid",   days_allowed: 18, carry_forward: true)
policy_unpaid_eng = LeavePolicy.create!(dept_id: dept_eng.dept_id,   leave_type: "unpaid", days_allowed: 10, carry_forward: false)
policy_paid_hr    = LeavePolicy.create!(dept_id: dept_hr.dept_id,    leave_type: "paid",   days_allowed: 15, carry_forward: true)
policy_unpaid_hr  = LeavePolicy.create!(dept_id: dept_hr.dept_id,    leave_type: "unpaid", days_allowed: 10, carry_forward: false)
policy_paid_sales = LeavePolicy.create!(dept_id: dept_sales.dept_id, leave_type: "paid",   days_allowed: 12, carry_forward: false)
policy_unpaid_sales = LeavePolicy.create!(dept_id: dept_sales.dept_id, leave_type: "unpaid", days_allowed: 8, carry_forward: false)

# ==============================================================================
# LEAVE BALANCES (current year)
# ==============================================================================

year = Date.today.year

[
  { emp_id: emp_alice.emp_id,   policy_id: policy_paid_eng.policy_id,    year: year, total_allowed: 18, used: 3,  remaining: 15 },
  { emp_id: emp_alice.emp_id,   policy_id: policy_unpaid_eng.policy_id,  year: year, total_allowed: 10, used: 0,  remaining: 10 },
  { emp_id: emp_bob.emp_id,     policy_id: policy_paid_eng.policy_id,    year: year, total_allowed: 18, used: 5,  remaining: 13 },
  { emp_id: emp_bob.emp_id,     policy_id: policy_unpaid_eng.policy_id,  year: year, total_allowed: 10, used: 2,  remaining: 8  },
  { emp_id: emp_charlie.emp_id, policy_id: policy_paid_eng.policy_id,    year: year, total_allowed: 18, used: 1,  remaining: 17 },
  { emp_id: emp_ivan.emp_id,    policy_id: policy_paid_eng.policy_id,    year: year, total_allowed: 18, used: 7,  remaining: 11 },
  { emp_id: emp_diana.emp_id,   policy_id: policy_paid_hr.policy_id,     year: year, total_allowed: 15, used: 4,  remaining: 11 },
  { emp_id: emp_ethan.emp_id,   policy_id: policy_paid_hr.policy_id,     year: year, total_allowed: 15, used: 2,  remaining: 13 },
  { emp_id: emp_jane.emp_id,    policy_id: policy_paid_hr.policy_id,     year: year, total_allowed: 15, used: 3,  remaining: 12 },
  { emp_id: emp_fatima.emp_id,  policy_id: policy_paid_sales.policy_id,  year: year, total_allowed: 12, used: 6,  remaining: 6  },
  { emp_id: emp_george.emp_id,  policy_id: policy_paid_sales.policy_id,  year: year, total_allowed: 12, used: 1,  remaining: 11 },
].each { |r| LeaveBalance.create!(r) }

# ==============================================================================
# LEAVES
# ==============================================================================

[
  { emp_id: emp_alice.emp_id,   policy_id: policy_paid_eng.policy_id,    start_date: "2025-01-06", end_date: "2025-01-08", reason: "Personal work",      status: "approved", approved_by: emp_diana.emp_id },
  { emp_id: emp_bob.emp_id,     policy_id: policy_paid_eng.policy_id,    start_date: "2025-02-10", end_date: "2025-02-12", reason: "Medical",             status: "approved", approved_by: emp_diana.emp_id },
  { emp_id: emp_bob.emp_id,     policy_id: policy_unpaid_eng.policy_id,  start_date: "2025-03-01", end_date: "2025-03-02", reason: "Family event",        status: "approved", approved_by: emp_diana.emp_id },
  { emp_id: emp_charlie.emp_id, policy_id: policy_paid_eng.policy_id,    start_date: "2025-03-10", end_date: "2025-03-10", reason: "Sick",                status: "pending",  approved_by: nil },
  { emp_id: emp_diana.emp_id,   policy_id: policy_paid_hr.policy_id,     start_date: "2025-01-20", end_date: "2025-01-23", reason: "Vacation",            status: "approved", approved_by: emp_jane.emp_id },
  { emp_id: emp_ethan.emp_id,   policy_id: policy_unpaid_hr.policy_id,   start_date: "2025-02-17", end_date: "2025-02-18", reason: "Personal emergency",  status: "approved", approved_by: emp_diana.emp_id },
  { emp_id: emp_ivan.emp_id,    policy_id: policy_paid_eng.policy_id,    start_date: "2025-03-15", end_date: "2025-03-20", reason: "Medical procedure",   status: "approved", approved_by: emp_diana.emp_id },
  { emp_id: emp_fatima.emp_id,  policy_id: policy_paid_sales.policy_id,  start_date: "2025-02-05", end_date: "2025-02-10", reason: "Travel",              status: "approved", approved_by: emp_diana.emp_id },
  { emp_id: emp_george.emp_id,  policy_id: policy_paid_sales.policy_id,  start_date: "2025-03-25", end_date: "2025-03-25", reason: "Personal",            status: "rejected", approved_by: emp_fatima.emp_id },
].each { |r| Leave.create!(r) }

# ==============================================================================
# ATTENDANCE — weekdays for March 2025
# ==============================================================================

active_employees = [emp_alice, emp_bob, emp_charlie, emp_ivan, emp_diana, emp_ethan, emp_jane, emp_fatima, emp_george]

(Date.new(2025, 3, 1)..Date.new(2025, 3, 31)).each do |date|
  next if date.saturday? || date.sunday?

  active_employees.each do |emp|
    # Simulate occasional absences
    if rand < 0.05
      Attendance.create!(
        emp_id:         emp.emp_id,
        date:           date,
        check_in_time:  nil,
        check_out_time: nil,
        status:         "absent",
        total_hours:    0,
        overtime_hours: 0
      )
    else
      check_in  = Time.parse("#{date} 09:00:00") + rand(0..20).minutes
      check_out = Time.parse("#{date} 18:00:00") + rand(0..120).minutes
      total     = ((check_out - check_in) / 3600.0).round(2)
      overtime  = [total - 8.0, 0.0].max.round(2)

      Attendance.create!(
        emp_id:         emp.emp_id,
        date:           date,
        check_in_time:  check_in,
        check_out_time: check_out,
        status:         total >= 4.0 ? "present" : "half_day",
        total_hours:    total,
        overtime_hours: overtime
      )
    end
  end
end

# ==============================================================================
# PROJECTS
# ==============================================================================

project_alpha = Project.create!(
  dept_id:         dept_eng.dept_id,
  project_name:    "Project Alpha",
  project_manager: emp_alice.emp_id,
  start_date:      "2025-01-01",
  end_date:        "2025-06-30",
  status:          "in_progress"
)

project_beta = Project.create!(
  dept_id:         dept_sales.dept_id,
  project_name:    "Project Beta",
  project_manager: emp_fatima.emp_id,
  start_date:      "2025-02-01",
  end_date:        "2025-08-31",
  status:          "in_progress"
)

project_gamma = Project.create!(
  dept_id:         dept_eng.dept_id,
  project_name:    "Project Gamma",
  project_manager: emp_ivan.emp_id,
  start_date:      "2024-06-01",
  end_date:        "2024-12-31",
  status:          "completed"
)

# ==============================================================================
# EMPLOYEE PROJECTS
# ==============================================================================

[
  { emp_id: emp_alice.emp_id,   project_id: project_alpha.project_id, project_role: "Tech Lead",          assigned_date: "2025-01-01" },
  { emp_id: emp_bob.emp_id,     project_id: project_alpha.project_id, project_role: "Backend Developer",   assigned_date: "2025-01-01" },
  { emp_id: emp_charlie.emp_id, project_id: project_alpha.project_id, project_role: "Frontend Developer",  assigned_date: "2025-01-15" },
  { emp_id: emp_ivan.emp_id,    project_id: project_alpha.project_id, project_role: "DevOps",              assigned_date: "2025-01-01" },
  { emp_id: emp_fatima.emp_id,  project_id: project_beta.project_id,  project_role: "Sales Lead",          assigned_date: "2025-02-01" },
  { emp_id: emp_george.emp_id,  project_id: project_beta.project_id,  project_role: "Sales Executive",     assigned_date: "2025-02-01" },
  # Gamma (completed) — same people, different point in time
  { emp_id: emp_alice.emp_id,   project_id: project_gamma.project_id, project_role: "Tech Lead",          assigned_date: "2024-06-01" },
  { emp_id: emp_ivan.emp_id,    project_id: project_gamma.project_id, project_role: "Senior Developer",    assigned_date: "2024-06-01" },
  { emp_id: emp_bob.emp_id,     project_id: project_gamma.project_id, project_role: "Junior Developer",    assigned_date: "2024-06-01" },
].each { |r| EmployeeProject.create!(r) }

# ==============================================================================
# SALARY STRUCTURES
# ==============================================================================

ss_senior_dev    = SalaryStructure.create!(role_id: role_senior_dev.role_id,    basic_salary: 80_000, bonus: 10_000, tax_percent: 10.0, deductions: 2_000)
ss_junior_dev    = SalaryStructure.create!(role_id: role_junior_dev.role_id,    basic_salary: 50_000, bonus:  5_000, tax_percent:  8.0, deductions: 1_500)
ss_hr_manager    = SalaryStructure.create!(role_id: role_hr_manager.role_id,    basic_salary: 70_000, bonus:  8_000, tax_percent: 10.0, deductions: 2_000)
ss_hr_exec       = SalaryStructure.create!(role_id: role_hr_exec.role_id,       basic_salary: 45_000, bonus:  3_000, tax_percent:  8.0, deductions: 1_000)
ss_sales_manager = SalaryStructure.create!(role_id: role_sales_manager.role_id, basic_salary: 75_000, bonus: 12_000, tax_percent: 10.0, deductions: 2_000)
ss_sales_exec    = SalaryStructure.create!(role_id: role_sales_exec.role_id,    basic_salary: 40_000, bonus:  5_000, tax_percent:  8.0, deductions: 1_000)

# ==============================================================================
# PAYSLIPS + PAYROLLS — Jan & Feb 2025
# ==============================================================================

def net_salary(structure, overtime_bonus: 0, unpaid_days: 0)
  daily_rate        = structure.basic_salary / 22.0
  unpaid_deduction  = (daily_rate * unpaid_days).round(2)
  gross             = structure.basic_salary + structure.bonus + overtime_bonus
  tax               = (gross * structure.tax_percent / 100.0).round(2)
  net               = (gross - tax - structure.deductions - unpaid_deduction).round(2)
  { net: net, unpaid_deduction: unpaid_deduction, overtime_bonus: overtime_bonus.round(2) }
end

payslip_inputs = [
  { emp: emp_alice,   structure: ss_senior_dev    },
  { emp: emp_bob,     structure: ss_junior_dev    },
  { emp: emp_charlie, structure: ss_junior_dev    },
  { emp: emp_ivan,    structure: ss_senior_dev    },
  { emp: emp_diana,   structure: ss_hr_manager    },
  { emp: emp_ethan,   structure: ss_hr_exec       },
  { emp: emp_jane,    structure: ss_hr_manager    },
  { emp: emp_fatima,  structure: ss_sales_manager },
  { emp: emp_george,  structure: ss_sales_exec    },
]

[{ month: 1, year: 2025 }, { month: 2, year: 2025 }].each do |period|
  payslip_inputs.each do |pi|
    calc = net_salary(pi[:structure], overtime_bonus: rand(500.0..2000.0))

    ps = Payslip.create!(
      emp_id:                 pi[:emp].emp_id,
      structure_id:           pi[:structure].structure_id,
      month:                  period[:month],
      year:                   period[:year],
      unpaid_leave_deduction: calc[:unpaid_deduction],
      overtime_bonus:         calc[:overtime_bonus],
      net_salary:             calc[:net],
      generated_date:         Date.new(period[:year], period[:month], 28)
    )

    Payroll.create!(
      payslip_id:    ps.payslip_id,
      salary:        ps.net_salary,
      date:          ps.generated_date + 2
    )
  end
end

# ==============================================================================
# PERFORMANCE REVIEWS
# ==============================================================================

[
  { emp_id: emp_bob.emp_id,     reviewer_id: emp_alice.emp_id,  review_date: "2025-01-15", rating: 4, feedback: "Good progress on Project Alpha. Should improve documentation habits." },
  { emp_id: emp_charlie.emp_id, reviewer_id: emp_alice.emp_id,  review_date: "2025-01-15", rating: 3, feedback: "Developing well. Focus on code quality and test coverage." },
  { emp_id: emp_ivan.emp_id,    reviewer_id: emp_alice.emp_id,  review_date: "2025-02-01", rating: 5, feedback: "Outstanding delivery on Project Gamma. Rightfully promoted to Senior Dev." },
  { emp_id: emp_ethan.emp_id,   reviewer_id: emp_diana.emp_id,  review_date: "2025-01-20", rating: 5, feedback: "Excellent performance in recruitment drives this quarter." },
  { emp_id: emp_george.emp_id,  reviewer_id: emp_fatima.emp_id, review_date: "2025-01-22", rating: 4, feedback: "Consistently met targets. Strong client relationships." },
  { emp_id: emp_alice.emp_id,   reviewer_id: emp_jane.emp_id,   review_date: "2025-02-05", rating: 5, feedback: "Exceptional technical leadership and team mentoring." },
  { emp_id: emp_diana.emp_id,   reviewer_id: emp_jane.emp_id,   review_date: "2025-02-05", rating: 4, feedback: "Solid HR operations management. Could improve onboarding timelines." },
].each { |r| PerformanceReview.create!(r) }

# ==============================================================================
# ASSETS
# ==============================================================================

asset_laptop_alice  = Asset.create!(asset_name: "Dell XPS 15",          asset_type: "Laptop",    purchase_date: "2020-01-01", status: "assigned")
asset_laptop_bob    = Asset.create!(asset_name: "MacBook Pro 14",        asset_type: "Laptop",    purchase_date: "2021-05-15", status: "assigned")
asset_laptop_ivan   = Asset.create!(asset_name: "ThinkPad X1 Carbon",   asset_type: "Laptop",    purchase_date: "2022-01-10", status: "assigned")
asset_monitor       = Asset.create!(asset_name: "LG 27\" 4K Monitor",   asset_type: "Monitor",   purchase_date: "2021-06-01", status: "assigned")
asset_phone         = Asset.create!(asset_name: "iPhone 14 Pro",         asset_type: "Phone",     purchase_date: "2022-11-01", status: "assigned")
asset_laptop_old    = Asset.create!(asset_name: "HP EliteBook 840",      asset_type: "Laptop",    purchase_date: "2019-03-01", status: "in_repair")
asset_chair         = Asset.create!(asset_name: "Ergonomic Chair A1",    asset_type: "Furniture", purchase_date: "2020-07-01", status: "idle")

# ==============================================================================
# ASSET ASSIGNMENT HISTORIES
# returned_date nil = currently assigned
# ==============================================================================

[
  { asset_id: asset_laptop_alice.asset_id, emp_id: emp_alice.emp_id,  assigned_date: "2020-01-10", returned_date: nil },
  { asset_id: asset_laptop_bob.asset_id,   emp_id: emp_bob.emp_id,    assigned_date: "2021-06-01", returned_date: nil },
  { asset_id: asset_laptop_ivan.asset_id,  emp_id: emp_ivan.emp_id,   assigned_date: "2022-01-10", returned_date: nil },
  { asset_id: asset_monitor.asset_id,      emp_id: emp_charlie.emp_id, assigned_date: "2022-03-15", returned_date: nil },
  { asset_id: asset_phone.asset_id,        emp_id: emp_fatima.emp_id, assigned_date: "2022-11-05", returned_date: nil },
  # Hannah returned the old laptop when she resigned
  { asset_id: asset_laptop_old.asset_id,   emp_id: emp_hannah.emp_id, assigned_date: "2021-11-01", returned_date: "2024-03-31" },
].each { |r| AssetAssignmentHistory.create!(r) }

# ==============================================================================
# SUMMARY
# ==============================================================================

puts ""
puts "Seeding complete!"
puts "  Organizations   : #{Organization.count}"
puts "  Departments     : #{Department.count}"
puts "  Roles           : #{Role.count}"
puts "  Employees       : #{Employee.count} (#{Employee.where(status: 'active').count} active, #{Employee.where(status: 'resigned').count} resigned)"
puts "  Attendance      : #{Attendance.count} records"
puts "  Leaves          : #{Leave.count}"
puts "  Payslips        : #{Payslip.count}"
puts "  Payrolls        : #{Payroll.count}"
puts "  Projects        : #{Project.count}"
puts "  Assets          : #{Asset.count}"
