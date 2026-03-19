class Leave < ApplicationRecord
  self.primary_key = :leave_id

  enum :status, {
    pending:  "pending",
    approved: "approved",
    rejected: "rejected"
  }, prefix: true

  normalize_enum_attributes :status

  belongs_to :employee,     foreign_key: :emp_id,    primary_key: :emp_id
  belongs_to :leave_policy, foreign_key: :policy_id, primary_key: :policy_id
  belongs_to :approver,     foreign_key: :approved_by, primary_key: :emp_id,
             class_name: "Employee", optional: true

  validates :emp_id,     presence: true
  validates :policy_id,  presence: true
  validates :start_date, presence: true
  validates :end_date,   presence: true
  validates :reason,     presence: true
  validates :status,     presence: true

  validate :end_date_after_start_date
  validate :start_date_not_in_past,     on: :create
  validate :policy_belongs_to_employee_department
  validate :sufficient_leave_balance,   on: :create
  validate :no_overlapping_leaves,      on: :create

  after_update :sync_leave_balance, if: -> { saved_change_to_status? }

  def duration_days
    (end_date - start_date).to_i + 1
  end

  private

  def end_date_after_start_date
    return unless start_date.present? && end_date.present?
    errors.add(:end_date, "must be after or equal to start date") if end_date < start_date
  end

  def start_date_not_in_past
    return unless start_date.present?
    errors.add(:start_date, "cannot be in the past") if start_date < Date.today
  end

  def policy_belongs_to_employee_department
    return unless emp_id.present? && policy_id.present?
    emp_dept_id = Employee.find_by(emp_id: emp_id)&.dept_id
    unless LeavePolicy.exists?(policy_id: policy_id, dept_id: emp_dept_id)
      errors.add(:policy_id, "does not belong to the employee's department")
    end
  end

  def sufficient_leave_balance
    return unless emp_id.present? && policy_id.present? && start_date.present? && end_date.present?

    balance = LeaveBalance.find_by(emp_id: emp_id, policy_id: policy_id, year: start_date.year)

    policy = LeavePolicy.find_by(policy_id: policy_id)
    return if policy&.leave_type_unpaid?

    if balance.nil? || balance.remaining < duration_days
      errors.add(:base, "Insufficient leave balance. Available: #{balance&.remaining || 0} days, Requested: #{duration_days} days")
    end
  end

  def no_overlapping_leaves
    return unless emp_id.present? && start_date.present? && end_date.present?

    overlap = Leave.where(emp_id: emp_id)
                   .where.not(status: "rejected")
                   .where("start_date <= ? AND end_date >= ?", end_date, start_date)

    errors.add(:base, "Leave dates overlap with an existing leave request") if overlap.exists?
  end

  def sync_leave_balance
    policy = leave_policy
    return if policy.leave_type_unpaid?

    balance = LeaveBalance.find_by(emp_id: emp_id, policy_id: policy_id, year: start_date.year)
    return unless balance

    if status_approved?
      balance.update!(
        used:      balance.used + duration_days,
        remaining: balance.remaining - duration_days
      )
    elsif status_rejected? && status_before_last_save == "approved"
      balance.update!(
        used:      [balance.used - duration_days, 0].max,
        remaining: balance.remaining + duration_days
      )
    end
  end
end