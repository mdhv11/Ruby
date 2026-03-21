class EmployeeRoleHistory < ApplicationRecord
  self.primary_key = nil

  belongs_to :employee, foreign_key: :emp_id,   primary_key: :emp_id
  belongs_to :role,     foreign_key: :role_id,  primary_key: :role_id

  validates :emp_id, :role_id, :start_date, presence: true

  validate :end_date_after_start_date, if: -> { start_date.present? && end_date.present? }
  validate :only_one_open_role_history, if: -> { end_date.nil? }
  validate :role_matches_employee_department

  private

  def end_date_after_start_date
    errors.add(:end_date, "must be after or equal to start date") if end_date < start_date
  end

  def only_one_open_role_history
    open_roles = EmployeeRoleHistory.where(emp_id: emp_id, end_date: nil)
    open_roles = open_roles.where.not(role_id: role_id, start_date: start_date) if persisted?

    errors.add(:emp_id, "already has an active role") if open_roles.exists?
  end

  def role_matches_employee_department
    return unless employee.present? && role.present?
    return if employee.dept_id == role.dept_id

    errors.add(:role_id, "must belong to the employee's department")
  end
end
