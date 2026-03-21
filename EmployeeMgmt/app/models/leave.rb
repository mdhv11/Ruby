class Leave < ApplicationRecord
  self.primary_key = :leave_id

  attr_accessor :skip_start_date_not_in_past_validation

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

  def duration_days
    (end_date - start_date).to_i + 1
  end

  def approve_with_balance(approver_id:)
    with_lock do
      return add_status_error("Only pending leaves can be approved") unless status_pending?

      transaction do
        deduct_leave_balance!
        update!(status: "approved", approved_by: approver_id)
      end
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def reject_with_balance_restore!(approver_id: nil)
    with_lock do
      return true if status_rejected?

      transaction do
        restore_leave_balance! if status_approved?
        update!(status: "rejected", approved_by: approver_id)
      end
    end
  end

  private

  def end_date_after_start_date
    return unless start_date.present? && end_date.present?
    errors.add(:end_date, "must be after or equal to start date") if end_date < start_date
  end

  def start_date_not_in_past
    return if skip_start_date_not_in_past_validation
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
    policy = leave_policy || LeavePolicy.find_by(policy_id: policy_id)
    return if policy&.leave_type_unpaid?

    add_insufficient_balance_error(balance) if balance.nil? || balance.remaining < duration_days
  end

  def no_overlapping_leaves
    return unless emp_id.present? && start_date.present? && end_date.present?

    overlap = Leave.where(emp_id: emp_id)
                   .where.not(status: "rejected")
                   .where("start_date <= ? AND end_date >= ?", end_date, start_date)

    errors.add(:base, "Leave dates overlap with an existing leave request") if overlap.exists?
  end

  def deduct_leave_balance!
    policy = leave_policy || LeavePolicy.find_by(policy_id: policy_id)
    return if policy&.leave_type_unpaid?

    balance = LeaveBalance.lock.find_by(emp_id: emp_id, policy_id: policy_id, year: start_date.year)
    if balance.nil? || balance.remaining < duration_days
      add_insufficient_balance_error(balance)
      raise ActiveRecord::RecordInvalid, self
    end

    balance.update_counts!(
      used: balance.used + duration_days,
      remaining: balance.remaining - duration_days
    )
  end

  def restore_leave_balance!
    policy = leave_policy || LeavePolicy.find_by(policy_id: policy_id)
    return if policy&.leave_type_unpaid?

    balance = LeaveBalance.lock.find_by(emp_id: emp_id, policy_id: policy_id, year: start_date.year)
    return unless balance

    balance.update_counts!(
      used: [balance.used - duration_days, 0].max,
      remaining: balance.remaining + duration_days
    )
  end

  def add_insufficient_balance_error(balance)
    errors.add(:base, "Insufficient leave balance. Available: #{balance&.remaining || 0} days, Requested: #{duration_days} days")
  end

  def add_status_error(message)
    errors.add(:status, message)
    false
  end
end
