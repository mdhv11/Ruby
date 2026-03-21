require "test_helper"

class OrganizationsControllerTest < ActionDispatch::IntegrationTest
  test "managers lists organization managers and their departments" do
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

    support = Department.create!(
      org_id: organization.org_id,
      name: unique_name("Support"),
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

    engineering_manager = create_employee(engineering, "engineering-manager")
    support_manager = create_employee(support, "support-manager")
    sales_manager = create_employee(sales, "sales-manager")

    engineering.update!(manager_id: engineering_manager.emp_id)
    support.update!(manager_id: support_manager.emp_id)
    sales.update!(manager_id: sales_manager.emp_id)

    get "/api/v1/organizations/#{organization.org_id}/managers"

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal organization.org_id, body["org_id"]
    assert_equal organization.name, body["name"]
    assert_equal 3, body["manager_count"]

    grouped = body["managers"].index_by { |entry| entry["manager"]["emp_id"] }

    assert_equal 1, grouped[engineering_manager.emp_id]["department_count"]
    assert_equal 1, grouped[support_manager.emp_id]["department_count"]
    assert_equal 1, grouped[sales_manager.emp_id]["department_count"]

    assert_equal [engineering.dept_id], grouped[engineering_manager.emp_id]["departments"].map { |department| department["dept_id"] }
    assert_equal [support.dept_id], grouped[support_manager.emp_id]["departments"].map { |department| department["dept_id"] }
    assert_equal [sales.dept_id], grouped[sales_manager.emp_id]["departments"].map { |department| department["dept_id"] }
  end

  test "managers groups multiple departments under the same manager" do
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

    support = Department.create!(
      org_id: organization.org_id,
      name: unique_name("Support"),
      working_days: %w[Monday Tuesday Wednesday Thursday Friday],
      standard_hours: 8.0,
      overtime_pay_per_hour: 200
    )

    shared_manager = create_employee(engineering, "shared-manager")

    engineering.update!(manager_id: shared_manager.emp_id)
    support.update!(manager_id: shared_manager.emp_id)

    get "/api/v1/organizations/#{organization.org_id}/managers"

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body["manager_count"]
    assert_equal 1, body["managers"].length
    assert_equal 2, body["managers"].first["department_count"]

    department_ids = body["managers"].first["departments"].map { |department| department["dept_id"] }
    assert_includes department_ids, engineering.dept_id
    assert_includes department_ids, support.dept_id
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
end
