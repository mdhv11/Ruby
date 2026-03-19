# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_19_204238) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "asset_assignment_histories", id: false, force: :cascade do |t|
    t.uuid "asset_id"
    t.date "assigned_date"
    t.uuid "emp_id"
    t.date "returned_date"
    t.index ["asset_id", "emp_id", "assigned_date"], name: "idx_asset_assignments_unique", unique: true
    t.index ["asset_id"], name: "index_asset_assignment_histories_on_asset_id"
    t.index ["emp_id"], name: "index_asset_assignment_histories_on_emp_id"
  end

  create_table "assets", primary_key: "asset_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "asset_name"
    t.string "asset_type"
    t.date "purchase_date"
    t.string "status"
  end

  create_table "attendances", primary_key: "attendance_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "check_in_time"
    t.datetime "check_out_time"
    t.date "date"
    t.uuid "emp_id"
    t.decimal "overtime_hours", precision: 6, scale: 2
    t.string "status"
    t.decimal "total_hours", precision: 6, scale: 2
    t.index ["emp_id", "date"], name: "index_attendances_on_emp_id_and_date", unique: true
  end

  create_table "departments", primary_key: "dept_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "manager_id"
    t.string "name"
    t.uuid "org_id"
    t.decimal "overtime_pay_per_hour", precision: 10, scale: 2
    t.decimal "standard_hours", precision: 4, scale: 1
    t.string "working_days", default: [], array: true
    t.index ["manager_id"], name: "index_departments_on_manager_id"
    t.index ["org_id"], name: "index_departments_on_org_id"
  end

  create_table "employee_department_histories", id: false, force: :cascade do |t|
    t.uuid "dept_id"
    t.uuid "emp_id"
    t.date "end_date"
    t.date "start_date"
    t.index ["dept_id"], name: "index_employee_department_histories_on_dept_id"
    t.index ["emp_id"], name: "index_employee_department_histories_on_emp_id"
  end

  create_table "employee_projects", id: false, force: :cascade do |t|
    t.date "assigned_date"
    t.uuid "emp_id"
    t.uuid "project_id"
    t.string "project_role"
    t.index ["emp_id", "project_id", "assigned_date"], name: "idx_on_emp_id_project_id_assigned_date_1b22d035ff", unique: true
    t.index ["emp_id"], name: "index_employee_projects_on_emp_id"
    t.index ["project_id"], name: "index_employee_projects_on_project_id"
  end

  create_table "employee_role_histories", id: false, force: :cascade do |t|
    t.uuid "emp_id"
    t.date "end_date"
    t.uuid "role_id"
    t.date "start_date"
    t.index ["emp_id"], name: "index_employee_role_histories_on_emp_id"
    t.index ["role_id"], name: "index_employee_role_histories_on_role_id"
  end

  create_table "employees", primary_key: "emp_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "address"
    t.date "date_of_birth"
    t.uuid "dept_id"
    t.string "email"
    t.string "gender"
    t.date "joining_date"
    t.string "name"
    t.string "phone"
    t.date "resignation_date"
    t.string "status"
    t.text "termination_reason"
    t.index ["dept_id"], name: "index_employees_on_dept_id"
  end

  create_table "leave_balances", id: false, force: :cascade do |t|
    t.uuid "emp_id"
    t.uuid "policy_id"
    t.integer "remaining"
    t.integer "total_allowed"
    t.integer "used"
    t.integer "year"
    t.index ["emp_id", "policy_id", "year"], name: "index_leave_balances_on_emp_id_and_policy_id_and_year", unique: true
    t.index ["emp_id"], name: "index_leave_balances_on_emp_id"
    t.index ["policy_id"], name: "index_leave_balances_on_policy_id"
  end

  create_table "leave_policies", primary_key: "policy_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "carry_forward"
    t.integer "days_allowed"
    t.uuid "dept_id"
    t.string "leave_type"
    t.index ["dept_id"], name: "index_leave_policies_on_dept_id"
  end

  create_table "leaves", primary_key: "leave_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "approved_by"
    t.uuid "emp_id"
    t.date "end_date"
    t.uuid "policy_id"
    t.text "reason"
    t.date "start_date"
    t.string "status"
    t.index ["approved_by"], name: "index_leaves_on_approved_by"
    t.index ["emp_id"], name: "index_leaves_on_emp_id"
    t.index ["policy_id"], name: "index_leaves_on_policy_id"
  end

  create_table "organizations", primary_key: "org_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "address"
    t.string "ceo"
    t.string "industry"
    t.string "name"
  end

  create_table "payrolls", primary_key: "payroll_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "date"
    t.uuid "payslip_id"
    t.decimal "salary", precision: 12, scale: 2
    t.index ["payslip_id"], name: "index_payrolls_on_payslip_id", unique: true
  end

  create_table "payslips", primary_key: "payslip_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "emp_id"
    t.date "generated_date"
    t.integer "month"
    t.decimal "net_salary", precision: 12, scale: 2
    t.decimal "overtime_bonus", precision: 12, scale: 2
    t.uuid "structure_id"
    t.decimal "unpaid_leave_deduction", precision: 12, scale: 2
    t.integer "year"
    t.index ["emp_id", "month", "year"], name: "index_payslips_on_emp_id_and_month_and_year", unique: true
    t.index ["structure_id"], name: "index_payslips_on_structure_id"
  end

  create_table "performance_reviews", primary_key: "review_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "emp_id"
    t.text "feedback"
    t.integer "rating"
    t.date "review_date"
    t.uuid "reviewer_id"
    t.index ["emp_id"], name: "index_performance_reviews_on_emp_id"
    t.index ["reviewer_id"], name: "index_performance_reviews_on_reviewer_id"
  end

  create_table "projects", primary_key: "project_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "dept_id"
    t.date "end_date"
    t.uuid "project_manager"
    t.string "project_name"
    t.date "start_date"
    t.string "status"
    t.index ["dept_id"], name: "index_projects_on_dept_id"
    t.index ["project_manager"], name: "index_projects_on_project_manager"
  end

  create_table "roles", primary_key: "role_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "dept_id"
    t.text "description"
    t.string "name"
    t.uuid "org_id"
    t.index ["dept_id"], name: "index_roles_on_dept_id"
    t.index ["org_id"], name: "index_roles_on_org_id"
  end

  create_table "salary_structures", primary_key: "structure_id", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "basic_salary", precision: 12, scale: 2
    t.decimal "bonus", precision: 12, scale: 2
    t.decimal "deductions", precision: 12, scale: 2
    t.uuid "role_id"
    t.decimal "tax_percent", precision: 5, scale: 2
    t.index ["role_id"], name: "index_salary_structures_on_role_id"
  end

  add_foreign_key "asset_assignment_histories", "assets", primary_key: "asset_id"
  add_foreign_key "asset_assignment_histories", "employees", column: "emp_id", primary_key: "emp_id"
  add_foreign_key "attendances", "employees", column: "emp_id", primary_key: "emp_id"
  add_foreign_key "departments", "employees", column: "manager_id", primary_key: "emp_id"
  add_foreign_key "departments", "organizations", column: "org_id", primary_key: "org_id"
  add_foreign_key "employee_department_histories", "departments", column: "dept_id", primary_key: "dept_id"
  add_foreign_key "employee_department_histories", "employees", column: "emp_id", primary_key: "emp_id"
  add_foreign_key "employee_projects", "employees", column: "emp_id", primary_key: "emp_id"
  add_foreign_key "employee_projects", "projects", primary_key: "project_id"
  add_foreign_key "employee_role_histories", "employees", column: "emp_id", primary_key: "emp_id"
  add_foreign_key "employee_role_histories", "roles", primary_key: "role_id"
  add_foreign_key "employees", "departments", column: "dept_id", primary_key: "dept_id"
  add_foreign_key "leave_balances", "employees", column: "emp_id", primary_key: "emp_id"
  add_foreign_key "leave_balances", "leave_policies", column: "policy_id", primary_key: "policy_id"
  add_foreign_key "leave_policies", "departments", column: "dept_id", primary_key: "dept_id"
  add_foreign_key "leaves", "employees", column: "approved_by", primary_key: "emp_id"
  add_foreign_key "leaves", "employees", column: "emp_id", primary_key: "emp_id"
  add_foreign_key "leaves", "leave_policies", column: "policy_id", primary_key: "policy_id"
  add_foreign_key "payrolls", "payslips", primary_key: "payslip_id"
  add_foreign_key "payslips", "employees", column: "emp_id", primary_key: "emp_id"
  add_foreign_key "payslips", "salary_structures", column: "structure_id", primary_key: "structure_id"
  add_foreign_key "performance_reviews", "employees", column: "emp_id", primary_key: "emp_id"
  add_foreign_key "performance_reviews", "employees", column: "reviewer_id", primary_key: "emp_id"
  add_foreign_key "projects", "departments", column: "dept_id", primary_key: "dept_id"
  add_foreign_key "projects", "employees", column: "project_manager", primary_key: "emp_id"
  add_foreign_key "roles", "departments", column: "dept_id", primary_key: "dept_id"
  add_foreign_key "roles", "organizations", column: "org_id", primary_key: "org_id"
  add_foreign_key "salary_structures", "roles", primary_key: "role_id"
end
