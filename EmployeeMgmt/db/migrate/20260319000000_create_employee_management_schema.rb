class CreateEmployeeManagementSchema < ActiveRecord::Migration[8.1]
  def change

    create_table :organizations, primary_key: :org_id, id: :uuid do |t|
      t.string :name
      t.string :industry
      t.string :ceo
      t.text :address
    end

    create_table :departments, primary_key: :dept_id, id: :uuid do |t|
      t.uuid :org_id
      t.string :name
      t.uuid :manager_id
      t.string :working_days, array: true, default: []
      t.decimal :overtime_pay_per_hour, precision: 10, scale: 2
    end

    create_table :roles, primary_key: :role_id, id: :uuid do |t|
      t.uuid :org_id
      t.uuid :dept_id
      t.string :name
      t.text :description
    end

    create_table :employees, primary_key: :emp_id, id: :uuid do |t|
      t.uuid :dept_id
      t.string :name
      t.text :address
      t.string :phone
      t.string :email
      t.date :date_of_birth
      t.string :gender
      t.date :joining_date
      t.date :resignation_date
      t.string :status
      t.text :termination_reason
    end

    create_table :employee_department_histories, id: false do |t|
      t.uuid :emp_id
      t.uuid :dept_id
      t.date :start_date
      t.date :end_date
    end

    create_table :employee_role_histories, id: false do |t|
      t.uuid :emp_id
      t.uuid :role_id
      t.date :start_date
      t.date :end_date
    end

    create_table :leave_policies, primary_key: :policy_id, id: :uuid do |t|
      t.uuid :dept_id
      t.string :leave_type
      t.integer :days_allowed
      t.boolean :carry_forward
    end

    create_table :leave_balances, id: false do |t|
      t.uuid :emp_id
      t.uuid :policy_id
      t.integer :year
      t.integer :total_allowed
      t.integer :used
      t.integer :remaining
    end

    create_table :leaves, primary_key: :leave_id, id: :uuid do |t|
      t.uuid :emp_id
      t.uuid :policy_id
      t.date :start_date
      t.date :end_date
      t.text :reason
      t.string :status
      t.uuid :approved_by
    end

    create_table :attendances, primary_key: :attendance_id, id: :uuid do |t|
      t.uuid :emp_id
      t.date :date
      t.datetime :check_in_time
      t.datetime :check_out_time
      t.string :status
      t.decimal :total_hours, precision: 6, scale: 2
      t.decimal :overtime_hours, precision: 6, scale: 2
    end

    create_table :projects, primary_key: :project_id, id: :uuid do |t|
      t.uuid :dept_id
      t.string :project_name
      t.uuid :project_manager
      t.date :start_date
      t.date :end_date
      t.string :status
    end

    create_table :employee_projects, id: false do |t|
      t.uuid :emp_id
      t.uuid :project_id
      t.string :project_role
      t.date :assigned_date
    end

    create_table :salary_structures, primary_key: :structure_id, id: :uuid do |t|
      t.uuid :role_id
      t.decimal :basic_salary, precision: 12, scale: 2
      t.decimal :bonus, precision: 12, scale: 2
      t.decimal :tax_percent, precision: 5, scale: 2
      t.decimal :deductions, precision: 12, scale: 2
    end

    create_table :payslips, primary_key: :payslip_id, id: :uuid do |t|
      t.uuid :emp_id
      t.uuid :structure_id
      t.integer :month
      t.integer :year
      t.decimal :unpaid_leave_deduction, precision: 12, scale: 2
      t.decimal :overtime_bonus, precision: 12, scale: 2
      t.decimal :net_salary, precision: 12, scale: 2
      t.date :generated_date
    end

    create_table :payrolls, primary_key: :payroll_id, id: :uuid do |t|
      t.uuid :payslip_id
      t.decimal :salary, precision: 12, scale: 2
      t.date :date
    end

    create_table :performance_reviews, primary_key: :review_id, id: :uuid do |t|
      t.uuid :emp_id
      t.uuid :reviewer_id
      t.date :review_date
      t.integer :rating
      t.text :feedback
    end

    create_table :assets, primary_key: :asset_id, id: :uuid do |t|
      t.string :asset_name
      t.string :asset_type
      t.date :purchase_date
      t.string :status
    end

    create_table :asset_assignment_histories, id: false do |t|
      t.uuid :asset_id
      t.uuid :emp_id
      t.date :assigned_date
      t.date :returned_date
    end

    add_index :departments, :org_id
    add_index :departments, :manager_id
    add_index :roles, :org_id
    add_index :roles, :dept_id
    add_index :employees, :dept_id
    add_index :employee_department_histories, :emp_id
    add_index :employee_department_histories, :dept_id
    add_index :employee_role_histories, :emp_id
    add_index :employee_role_histories, :role_id
    add_index :attendances, [:emp_id, :date], unique: true
    add_index :leave_policies, :dept_id
    add_index :leave_balances, :emp_id
    add_index :leave_balances, :policy_id
    add_index :leave_balances, [:emp_id, :policy_id, :year], unique: true
    add_index :leaves, :emp_id
    add_index :leaves, :policy_id
    add_index :leaves, :approved_by
    add_index :projects, :dept_id
    add_index :projects, :project_manager
    add_index :employee_projects, :emp_id
    add_index :employee_projects, :project_id
    add_index :employee_projects, [:emp_id, :project_id, :assigned_date], unique: true
    add_index :salary_structures, :role_id
    add_index :payslips, [:emp_id, :month, :year], unique: true
    add_index :payslips, :structure_id
    add_index :payrolls, :payslip_id, unique: true
    add_index :performance_reviews, :emp_id
    add_index :performance_reviews, :reviewer_id
    add_index :asset_assignment_histories, :asset_id
    add_index :asset_assignment_histories, :emp_id
    add_index :asset_assignment_histories, [:asset_id, :emp_id, :assigned_date], name: "idx_asset_assignments_unique", unique: true

    add_foreign_key :departments, :organizations, column: :org_id, primary_key: :org_id
    add_foreign_key :roles, :organizations, column: :org_id, primary_key: :org_id
    add_foreign_key :roles, :departments, column: :dept_id, primary_key: :dept_id
    add_foreign_key :departments, :employees, column: :manager_id, primary_key: :emp_id
    add_foreign_key :employees, :departments, column: :dept_id, primary_key: :dept_id
    add_foreign_key :employee_department_histories, :employees, column: :emp_id, primary_key: :emp_id
    add_foreign_key :employee_department_histories, :departments, column: :dept_id, primary_key: :dept_id
    add_foreign_key :employee_role_histories, :employees, column: :emp_id, primary_key: :emp_id
    add_foreign_key :employee_role_histories, :roles, column: :role_id, primary_key: :role_id
    add_foreign_key :leave_policies, :departments, column: :dept_id, primary_key: :dept_id
    add_foreign_key :leave_balances, :employees, column: :emp_id, primary_key: :emp_id
    add_foreign_key :leave_balances, :leave_policies, column: :policy_id, primary_key: :policy_id
    add_foreign_key :leaves, :employees, column: :emp_id, primary_key: :emp_id
    add_foreign_key :leaves, :leave_policies, column: :policy_id, primary_key: :policy_id
    add_foreign_key :leaves, :employees, column: :approved_by, primary_key: :emp_id
    add_foreign_key :attendances, :employees, column: :emp_id, primary_key: :emp_id
    add_foreign_key :projects, :departments, column: :dept_id, primary_key: :dept_id
    add_foreign_key :projects, :employees, column: :project_manager, primary_key: :emp_id
    add_foreign_key :employee_projects, :employees, column: :emp_id, primary_key: :emp_id
    add_foreign_key :employee_projects, :projects, column: :project_id, primary_key: :project_id
    add_foreign_key :salary_structures, :roles, column: :role_id, primary_key: :role_id
    add_foreign_key :payslips, :employees, column: :emp_id, primary_key: :emp_id
    add_foreign_key :payslips, :salary_structures, column: :structure_id, primary_key: :structure_id
    add_foreign_key :payrolls, :payslips, column: :payslip_id, primary_key: :payslip_id
    add_foreign_key :performance_reviews, :employees, column: :emp_id, primary_key: :emp_id
    add_foreign_key :performance_reviews, :employees, column: :reviewer_id, primary_key: :emp_id
    add_foreign_key :asset_assignment_histories, :assets, column: :asset_id, primary_key: :asset_id
    add_foreign_key :asset_assignment_histories, :employees, column: :emp_id, primary_key: :emp_id
  end
end
