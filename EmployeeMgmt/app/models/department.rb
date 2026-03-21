class Department < ApplicationRecord
  self.primary_key = :dept_id
  UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

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

  validate :manager_id_must_be_valid_uuid, if: -> { manager_id.present? }
  validate :manager_belongs_to_organization, if: -> { manager_id.present? }

  validates :standard_hours, numericality: {
    greater_than: 0,
    less_than_or_equal_to: 24
  }, allow_nil: true

  private

  def manager_id_must_be_valid_uuid
    errors.add(:manager_id, "must be a valid UUID") unless manager_id.to_s.match?(UUID_FORMAT)
  end

  def manager_belongs_to_organization
    return if errors.include?(:manager_id)

    unless Employee.joins(:department).exists?(emp_id: manager_id, departments: { org_id: org_id })
      errors.add(:manager_id, "must be an employee of this organization")
    end
  end
end
