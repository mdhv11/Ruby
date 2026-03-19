class Department < ApplicationRecord
  self.primary_key = :dept_id

  belongs_to :organization, foreign_key: :org_id,     primary_key: :org_id
  belongs_to :manager,      foreign_key: :manager_id, primary_key: :emp_id,
             class_name: "Employee", optional: true

  has_many :roles,         foreign_key: :dept_id, primary_key: :dept_id, dependent: :restrict_with_error
  has_many :employees,     foreign_key: :dept_id, primary_key: :dept_id, dependent: :restrict_with_error
  has_many :projects,      foreign_key: :dept_id, primary_key: :dept_id, dependent: :restrict_with_error
  has_many :leave_policies, foreign_key: :dept_id, primary_key: :dept_id, dependent: :restrict_with_error

  has_many :employee_department_histories, foreign_key: :dept_id, primary_key: :dept_id

  validates :name,                 presence: true
  validates :org_id,               presence: true
  validates :overtime_pay_per_hour, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :name,                 uniqueness: { scope: :org_id, case_sensitive: false,
                                                 message: "already exists in this organization" }

  validate :manager_belongs_to_department, if: -> { manager_id.present? }

  validates :standard_hours, numericality: {
    greater_than: 0,
    less_than_or_equal_to: 24
  }, allow_nil: true

  private

  def manager_belongs_to_department
    unless Employee.exists?(emp_id: manager_id, dept_id: dept_id)
      errors.add(:manager_id, "must be an employee of this department")
    end
  end
end