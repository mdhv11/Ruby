require "test_helper"

class EmployeesControllerTest < ActionDispatch::IntegrationTest
  test "manager performance separates department and project team ratings" do
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

    manager = create_employee(department, "manager")
    teammate = create_employee(department, "teammate")
    outsider_department = Department.create!(
      org_id: organization.org_id,
      name: unique_name("Support"),
      working_days: %w[Monday Tuesday Wednesday Thursday Friday],
      standard_hours: 8.0,
      overtime_pay_per_hour: 200
    )
    project_teammate = create_employee(outsider_department, "project-teammate")
    outsider = create_employee(outsider_department, "outsider")

    department.update!(manager_id: manager.emp_id)

    project = create_project(department, "Managed", "in_progress")
    project.update!(project_manager: manager.emp_id)
    EmployeeProject.create!(
      emp_id: project_teammate.emp_id,
      project_id: project.project_id,
      project_role: "Developer",
      assigned_date: Date.current
    )

    PerformanceReview.create!(
      emp_id: manager.emp_id,
      reviewer_id: teammate.emp_id,
      review_date: Date.current.prev_month,
      rating: 5,
      feedback: "Strong leadership"
    )

    PerformanceReview.create!(
      emp_id: manager.emp_id,
      reviewer_id: project_teammate.emp_id,
      review_date: Date.current.prev_month,
      rating: 4,
      feedback: "Good delivery support"
    )

    PerformanceReview.create!(
      emp_id: manager.emp_id,
      reviewer_id: outsider.emp_id,
      review_date: Date.current.prev_month,
      rating: 1,
      feedback: "Should not be counted"
    )

    get "/api/v1/employees/#{manager.emp_id}/manager_performance", params: { year: Date.current.year }

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal manager.emp_id, body["manager"]["emp_id"]
    assert_equal 2, body["team_member_count"]
    assert_equal 2, body["review_count"]
    assert_equal 4.5, body["average_rating"]
    assert_equal 2, body["reviews"].length
    assert_equal 2, body["overall"]["team_member_count"]
    assert_equal 2, body["overall"]["review_count"]
    assert_equal 4.5, body["overall"]["average_rating"]
    assert_equal 1, body["department_team"]["team_member_count"]
    assert_equal 1, body["department_team"]["review_count"]
    assert_equal 5.0, body["department_team"]["average_rating"]
    assert_equal 1, body["project_team"]["team_member_count"]
    assert_equal 1, body["project_team"]["review_count"]
    assert_equal 4.0, body["project_team"]["average_rating"]

    reviewer_ids = body["reviews"].map { |review| review["reviewer"]["emp_id"] }
    assert_includes reviewer_ids, teammate.emp_id
    assert_includes reviewer_ids, project_teammate.emp_id
    assert_not_includes reviewer_ids, outsider.emp_id
  end

  test "project overload detection returns employees over the active project threshold" do
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

    overloaded_employee = create_employee(department, "overloaded")
    balanced_employee = create_employee(department, "balanced")

    project_one = create_project(department, "Alpha", "assigned")
    project_two = create_project(department, "Beta", "in_progress")
    completed_project = create_project(department, "Gamma", "completed")

    EmployeeProject.create!(emp_id: overloaded_employee.emp_id, project_id: project_one.project_id, project_role: "Developer", assigned_date: Date.current)
    EmployeeProject.create!(emp_id: overloaded_employee.emp_id, project_id: project_two.project_id, project_role: "Developer", assigned_date: Date.current)
    EmployeeProject.create!(emp_id: overloaded_employee.emp_id, project_id: completed_project.project_id, project_role: "Developer", assigned_date: Date.current)
    EmployeeProject.create!(emp_id: balanced_employee.emp_id, project_id: project_one.project_id, project_role: "QA", assigned_date: Date.current)

    get "/api/v1/employees/project_overload_detection", params: { max_projects: 1 }

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body["count"]

    employee = body["employees"].first
    assert_equal overloaded_employee.emp_id, employee["emp_id"]
    assert_equal 2, employee["active_project_count"]
    project_names = employee["projects"].map { |project| project["project_name"] }
    assert_includes project_names, project_one.project_name
    assert_includes project_names, project_two.project_name
    assert_not_includes project_names, completed_project.project_name
  end

  test "salary reduction candidates includes employee with unpaid half day settlement and low attendance" do
    employee = build_employee_with_leave_policies(paid_remaining: 0, unpaid_days_allowed: 10)
    first_date, second_date = two_working_dates

    create_half_day_attendance(employee, first_date)
    create_half_day_attendance(employee, second_date)

    get "/api/v1/employees/salary_reduction_candidates", params: {
      month: working_month.month,
      year: working_month.year,
      attendance_below: 95
    }

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body["count"]

    candidate = body["employees"].find { |entry| entry["emp_id"] == employee.emp_id }
    assert candidate.present?
    assert_equal 1, candidate["unpaid_leave_days"]
    assert_equal 1, candidate["half_day_absence_equivalent"]
    assert_includes candidate["reasons"], "unpaid_leave"
    assert_includes candidate["reasons"], "low_attendance"
    assert_includes candidate["reasons"], "half_day_adjustment"
  end

  private

  def build_employee_with_leave_policies(paid_remaining:, unpaid_days_allowed:)
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

    employee = Employee.create!(
      name: unique_name("Employee"),
      email: unique_email,
      phone: unique_phone,
      gender: "male",
      dept_id: department.dept_id,
      joining_date: Date.current.prev_year,
      status: "active"
    )

    paid_policy = LeavePolicy.create!(
      dept_id: department.dept_id,
      leave_type: "paid",
      days_allowed: 12,
      carry_forward: false
    )

    LeavePolicy.create!(
      dept_id: department.dept_id,
      leave_type: "unpaid",
      days_allowed: unpaid_days_allowed,
      carry_forward: false
    )

    LeaveBalance.create!(
      emp_id: employee.emp_id,
      policy_id: paid_policy.policy_id,
      year: working_month.year,
      total_allowed: 12,
      used: 12 - paid_remaining,
      remaining: paid_remaining
    )

    employee
  end

  def create_employee(department, suffix)
    Employee.create!(
      name: "Employee #{suffix} #{SecureRandom.hex(2)}",
      email: "employee-#{suffix}-#{SecureRandom.hex(3)}@example.com",
      phone: unique_phone,
      gender: "male",
      dept_id: department.dept_id,
      joining_date: Date.current.prev_year,
      status: "active"
    )
  end

  def create_project(department, suffix, status)
    Project.create!(
      dept_id: department.dept_id,
      project_name: unique_name("Project #{suffix}"),
      start_date: Date.current.prev_month,
      status: status
    )
  end

  def create_half_day_attendance(employee, attendance_date)
    Attendance.create!(
      emp_id: employee.emp_id,
      date: attendance_date,
      check_in_time: time_for(attendance_date, 9),
      check_out_time: time_for(attendance_date, 13)
    )
  end

  def time_for(date, hour)
    Time.zone.local(date.year, date.month, date.day, hour, 0, 0)
  end

  def two_working_dates
    working_dates = working_month.all_month.select { |date| (1..5).cover?(date.wday) }
    [working_dates.first, working_dates.second]
  end

  def working_month
    @working_month ||= Date.current.prev_month.beginning_of_month
  end

  def unique_name(prefix)
    "#{prefix} #{SecureRandom.hex(4)}"
  end

  def unique_email
    "employee-#{SecureRandom.hex(4)}@example.com"
  end

  def unique_phone
    SecureRandom.random_number(10**10).to_s.rjust(10, "0")
  end
end
