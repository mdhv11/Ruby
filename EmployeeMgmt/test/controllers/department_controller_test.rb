require "test_helper"

class DepartmentControllerTest < ActionDispatch::IntegrationTest
  test "update rejects an invalid manager uuid" do
    organization = Organization.create!(
      name: unique_name("Org"),
      industry: "Software",
      ceo: "CEO",
      address: "123 Main Street"
    )

    department = Department.create!(
      org_id: organization.org_id,
      name: unique_name("Engineering"),
      working_days: %w[Monday Tuesday Wednesday Thursday Friday],
      standard_hours: 8.0,
      overtime_pay_per_hour: 200
    )

    patch "/api/v1/organizations/#{organization.org_id}/departments/#{department.dept_id}",
          params: { department: { manager_id: "not-a-uuid" } }

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal "manager_id must be a valid UUID", body["error"]
  end

  test "assign manager rejects an invalid employee uuid" do
    organization = Organization.create!(
      name: unique_name("Org"),
      industry: "Software",
      ceo: "CEO",
      address: "123 Main Street"
    )

    department = Department.create!(
      org_id: organization.org_id,
      name: unique_name("Engineering"),
      working_days: %w[Monday Tuesday Wednesday Thursday Friday],
      standard_hours: 8.0,
      overtime_pay_per_hour: 200
    )

    patch "/api/v1/organizations/#{organization.org_id}/departments/#{department.dept_id}/assign_manager",
          params: { emp_id: "not-a-uuid" }

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal "emp_id must be a valid UUID", body["error"]
  end

  test "assign manager allows an active employee from another department in the same organization" do
    organization = Organization.create!(
      name: unique_name("Org"),
      industry: "Software",
      ceo: "CEO",
      address: "123 Main Street"
    )

    target_department = Department.create!(
      org_id: organization.org_id,
      name: unique_name("Engineering"),
      working_days: %w[Monday Tuesday Wednesday Thursday Friday],
      standard_hours: 8.0,
      overtime_pay_per_hour: 200
    )

    source_department = Department.create!(
      org_id: organization.org_id,
      name: unique_name("Support"),
      working_days: %w[Monday Tuesday Wednesday Thursday Friday],
      standard_hours: 8.0,
      overtime_pay_per_hour: 200
    )

    employee = create_employee(source_department, "manager")
    EmployeeDepartmentHistory.create!(
      emp_id: employee.emp_id,
      dept_id: source_department.dept_id,
      start_date: Date.current.prev_month,
      end_date: nil
    )

    patch "/api/v1/organizations/#{organization.org_id}/departments/#{target_department.dept_id}/assign_manager",
          params: { emp_id: employee.emp_id }

    assert_response :success

    employee.reload
    target_department.reload

    assert_equal employee.emp_id, target_department.manager_id
    assert_equal source_department.dept_id, employee.dept_id
  end

  test "assign manager rejects an employee from another organization" do
    organization = Organization.create!(
      name: unique_name("Org"),
      industry: "Software",
      ceo: "CEO",
      address: "123 Main Street"
    )

    other_organization = Organization.create!(
      name: unique_name("Other Org"),
      industry: "Finance",
      ceo: "Other CEO",
      address: "456 Other Street"
    )

    target_department = Department.create!(
      org_id: organization.org_id,
      name: unique_name("Engineering"),
      working_days: %w[Monday Tuesday Wednesday Thursday Friday],
      standard_hours: 8.0,
      overtime_pay_per_hour: 200
    )

    other_department = Department.create!(
      org_id: other_organization.org_id,
      name: unique_name("Support"),
      working_days: %w[Monday Tuesday Wednesday Thursday Friday],
      standard_hours: 8.0,
      overtime_pay_per_hour: 200
    )

    employee = create_employee(other_department, "manager")

    patch "/api/v1/organizations/#{organization.org_id}/departments/#{target_department.dept_id}/assign_manager",
          params: { emp_id: employee.emp_id }

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "Manager must belong to this organization", body["error"]
  end

  test "monthly salary expense returns only payslips for employees in department at month end" do
    month_start = Date.current.prev_month.beginning_of_month
    month_end = month_start.end_of_month

    organization = Organization.create!(
      name: unique_name("Org"),
      industry: "Software",
      ceo: "CEO",
      address: "123 Main Street"
    )

    engineering = Department.create!(
      org_id: organization.org_id,
      name: unique_name("Engineering"),
      working_days: %w[Monday Tuesday Wednesday Thursday Friday],
      standard_hours: 8.0,
      overtime_pay_per_hour: 200
    )

    sales = Department.create!(
      org_id: organization.org_id,
      name: unique_name("Sales"),
      working_days: %w[Monday Tuesday Wednesday Thursday Friday],
      standard_hours: 8.0,
      overtime_pay_per_hour: 200
    )

    role = Role.create!(
      org_id: organization.org_id,
      dept_id: engineering.dept_id,
      name: unique_name("Engineer")
    )

    structure = SalaryStructure.create!(
      role_id: role.role_id,
      basic_salary: 10_000,
      bonus: 500,
      tax_percent: 10,
      deductions: 300
    )

    staying_employee = create_employee(engineering, "staying")
    transferred_employee = create_employee(engineering, "transferred")

    EmployeeDepartmentHistory.create!(
      emp_id: staying_employee.emp_id,
      dept_id: engineering.dept_id,
      start_date: month_start - 3.months,
      end_date: nil
    )

    EmployeeDepartmentHistory.create!(
      emp_id: transferred_employee.emp_id,
      dept_id: engineering.dept_id,
      start_date: month_start - 3.months,
      end_date: month_end - 1.day
    )

    EmployeeDepartmentHistory.create!(
      emp_id: transferred_employee.emp_id,
      dept_id: sales.dept_id,
      start_date: month_end,
      end_date: nil
    )

    staying_payslip = Payslip.create!(
      emp_id: staying_employee.emp_id,
      structure_id: structure.structure_id,
      month: month_start.month,
      year: month_start.year,
      overtime_bonus: 100,
      unpaid_leave_deduction: 50,
      generated_date: month_end
    )

    transferred_payslip = Payslip.create!(
      emp_id: transferred_employee.emp_id,
      structure_id: structure.structure_id,
      month: month_start.month,
      year: month_start.year,
      overtime_bonus: 80,
      unpaid_leave_deduction: 40,
      generated_date: month_end
    )

    Payroll.create!(
      payslip_id: staying_payslip.payslip_id,
      amount_disbursed: staying_payslip.net_salary,
      date: month_end
    )

    get "/api/v1/organizations/#{organization.org_id}/departments/#{engineering.dept_id}/monthly_salary_expense",
        params: { month: month_start.month, year: month_start.year }

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body["employee_count"]
    assert_equal 1, body["payslip_count"]
    assert_equal staying_payslip.net_salary.to_f, body["total_net_salary"]
    assert_equal 100.0, body["total_overtime_bonus"]
    assert_equal 50.0, body["total_unpaid_leave_deduction"]
    assert_equal staying_payslip.net_salary.to_f, body["total_disbursed"]

    returned_emp_ids = body["payslips"].map { |entry| entry["emp_id"] }
    assert_includes returned_emp_ids, staying_employee.emp_id
    assert_not_includes returned_emp_ids, transferred_employee.emp_id
  end

  private

  def create_employee(department, suffix)
    Employee.create!(
      name: "Employee #{suffix} #{SecureRandom.hex(2)}",
      email: "employee-#{suffix}-#{SecureRandom.hex(3)}@example.com",
      phone: SecureRandom.random_number(10**10).to_s.rjust(10, "0"),
      gender: "male",
      dept_id: department.dept_id,
      joining_date: Date.current.prev_year,
      status: "active"
    )
  end

  def unique_name(prefix)
    "#{prefix} #{SecureRandom.hex(4)}"
  end
end
