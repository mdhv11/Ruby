require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  test "two half days consume one paid leave day when balance is available" do
    employee, paid_policy, = build_employee_with_leave_policies(paid_remaining: 2, unpaid_days_allowed: 10)
    first_date, second_date = two_working_dates

    create_half_day_attendance(employee, first_date)
    create_half_day_attendance(employee, second_date)

    paid_leave = Leave.find_by(
      emp_id: employee.emp_id,
      policy_id: paid_policy.policy_id,
      start_date: second_date,
      end_date: second_date,
      reason: Attendance::AUTO_PAID_HALF_DAY_REASON
    )

    assert paid_leave.present?
    assert_equal "approved", paid_leave.status

    balance = LeaveBalance.find_by(emp_id: employee.emp_id, policy_id: paid_policy.policy_id, year: second_date.year)
    assert_equal 11, balance.used
    assert_equal 1, balance.remaining
  end

  test "two half days become unpaid leave when paid leave is exhausted" do
    employee, paid_policy, unpaid_policy = build_employee_with_leave_policies(paid_remaining: 0, unpaid_days_allowed: 10)
    first_date, second_date = two_working_dates

    create_half_day_attendance(employee, first_date)
    create_half_day_attendance(employee, second_date)

    unpaid_leave = Leave.find_by(
      emp_id: employee.emp_id,
      policy_id: unpaid_policy.policy_id,
      start_date: second_date,
      end_date: second_date,
      reason: Attendance::AUTO_UNPAID_HALF_DAY_REASON
    )

    assert unpaid_leave.present?
    assert_equal "approved", unpaid_leave.status

    paid_balance = LeaveBalance.find_by(emp_id: employee.emp_id, policy_id: paid_policy.policy_id, year: second_date.year)
    assert_equal 12, paid_balance.used
    assert_equal 0, paid_balance.remaining
  end

  test "correcting a half day back to present rejects auto paid leave and restores balance" do
    employee, paid_policy, = build_employee_with_leave_policies(paid_remaining: 1, unpaid_days_allowed: 10)
    first_date, second_date = two_working_dates

    create_half_day_attendance(employee, first_date)
    attendance = create_half_day_attendance(employee, second_date)

    paid_leave = Leave.find_by!(
      emp_id: employee.emp_id,
      policy_id: paid_policy.policy_id,
      start_date: second_date,
      end_date: second_date,
      reason: Attendance::AUTO_PAID_HALF_DAY_REASON
    )
    assert_equal "approved", paid_leave.status

    attendance.update!(
      check_in_time: time_for(second_date, 9),
      check_out_time: time_for(second_date, 18)
    )

    assert_equal "rejected", paid_leave.reload.status

    balance = LeaveBalance.find_by(emp_id: employee.emp_id, policy_id: paid_policy.policy_id, year: second_date.year)
    assert_equal 11, balance.used
    assert_equal 1, balance.remaining
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

    unpaid_policy = LeavePolicy.create!(
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

    [employee, paid_policy, unpaid_policy]
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
