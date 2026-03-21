class Attendance < ApplicationRecord
  self.primary_key = :attendance_id
  AUTO_PAID_ABSENCE_REASON = "absent: adjusted against remaining paid leave".freeze
  AUTO_UNPAID_ABSENCE_REASON = "absent: exceeded the allowed no of paid leave".freeze
  AUTO_PAID_HALF_DAY_REASON = "half_day: adjusted against remaining paid leave".freeze
  AUTO_UNPAID_HALF_DAY_REASON = "half_day: exceeded the allowed no of paid leave".freeze

  enum :status, {
    present:  "present",
    absent:   "absent",
    half_day: "half_day"
  }, prefix: true

  belongs_to :employee, foreign_key: :emp_id, primary_key: :emp_id

  validates :emp_id, presence: true
  validates :date,   presence: true
  validates :date,   uniqueness: { scope: :emp_id, message: "attendance already recorded for this employee on this date" }

  validate :check_out_after_check_in, if: -> { check_in_time.present? && check_out_time.present? }
  validate :not_a_future_date

  before_save :calculate_hours
  before_save :derive_status
  after_save :sync_auto_leave_for_absence
  after_save :sync_half_day_leave_adjustments

  scope :for_month,    ->(month, year) { where(date: Date.new(year, month, 1)..Date.new(year, month, -1)) }
  scope :for_employee, ->(emp_id)      { where(emp_id: emp_id) }

  private

  def standard_hours
    employee.department&.standard_hours&.to_f || 8.0
  end

  def half_day_minimum
    standard_hours / 2.0
  end

  def calculate_hours
    if check_in_time.present? && check_out_time.present?
      self.total_hours    = ((check_out_time - check_in_time) / 3600.0).round(2)
      self.overtime_hours = [total_hours - standard_hours, 0.0].max.round(2)
    else
      self.total_hours    = 0.0
      self.overtime_hours = 0.0
    end
  end

  def derive_status
    if check_in_time.blank? && check_out_time.blank?
      self.status = :absent
    elsif total_hours >= standard_hours
      self.status = :present
    elsif total_hours >= half_day_minimum
      self.status = :half_day
    else
      self.status = :absent
    end
  end

  def check_out_after_check_in
    if check_out_time <= check_in_time
      errors.add(:check_out_time, "must be after check-in time")
    end
  end

  def not_a_future_date
    if date.present? && date > Date.today
      errors.add(:date, "cannot be a future date")
    end
  end

  def sync_auto_leave_for_absence
    return unless employee.present? && date.present?

    paid_policy = LeavePolicy.find_by(dept_id: employee.dept_id, leave_type: "paid")
    unpaid_policy = LeavePolicy.find_by(dept_id: employee.dept_id, leave_type: "unpaid")
    auto_paid_leave = auto_generated_leave_for(policy: paid_policy, reason: AUTO_PAID_ABSENCE_REASON)
    auto_unpaid_leave = auto_generated_leave_for(policy: unpaid_policy, reason: AUTO_UNPAID_ABSENCE_REASON)

    unless status_absent? && working_day_for_department?
      reject_auto_generated_leave(auto_paid_leave)
      reject_auto_generated_leave(auto_unpaid_leave)
      return
    end

    return if overlapping_non_rejected_leave_exists?(excluding: [auto_paid_leave, auto_unpaid_leave])

    if paid_leave_available?(paid_policy)
      ensure_paid_auto_leave!(paid_policy, auto_paid_leave, auto_unpaid_leave)
    else
      ensure_unpaid_auto_leave!(unpaid_policy, auto_paid_leave, auto_unpaid_leave)
    end
  end

  def auto_generated_leave_for(policy:, reason:)
    return nil unless policy

    employee.leaves.find_by(
      policy_id: policy.policy_id,
      start_date: date,
      end_date: date,
      reason: reason
    )
  end

  def working_day_for_department?
    working_days = employee.department&.working_days.to_a.reject(&:blank?)
    return true if working_days.blank?

    working_days.include?(date.strftime("%A"))
  end

  def paid_leave_available?(paid_policy)
    return false unless paid_policy

    balance = LeaveBalance.find_by(emp_id: employee.emp_id, policy_id: paid_policy.policy_id, year: date.year)
    balance.present? && balance.remaining.to_i.positive?
  end

  def overlapping_non_rejected_leave_exists?(excluding:)
    leaves = employee.leaves.where.not(status: "rejected")
    Array(excluding).compact.each do |leave|
      leaves = leaves.where.not(
        policy_id: leave.policy_id,
        start_date: leave.start_date,
        end_date: leave.end_date,
        reason: leave.reason
      )
    end

    leaves.where("start_date <= ? AND end_date >= ?", date, date).exists?
  end

  def ensure_paid_auto_leave!(paid_policy, auto_paid_leave, auto_unpaid_leave)
    reject_auto_generated_leave(auto_unpaid_leave)
    return if auto_paid_leave&.status_approved?
    return unless paid_policy

    auto_paid_leave ||= employee.leaves.new(
      policy_id: paid_policy.policy_id,
      start_date: date,
      end_date: date,
      reason: AUTO_PAID_ABSENCE_REASON,
      status: "pending"
    )

    auto_paid_leave.skip_start_date_not_in_past_validation = true
    auto_paid_leave.save! if auto_paid_leave.new_record?
    auto_paid_leave.approve_with_balance(approver_id: nil) || raise(ActiveRecord::RecordInvalid, auto_paid_leave)
  end

  def ensure_unpaid_auto_leave!(unpaid_policy, auto_paid_leave, auto_unpaid_leave)
    reject_auto_generated_leave(auto_paid_leave)
    return if auto_unpaid_leave&.status_approved?
    return unless unpaid_policy

    auto_unpaid_leave ||= employee.leaves.new(
      policy_id: unpaid_policy.policy_id,
      start_date: date,
      end_date: date,
      reason: AUTO_UNPAID_ABSENCE_REASON
    )

    auto_unpaid_leave.skip_start_date_not_in_past_validation = true
    auto_unpaid_leave.status = "approved"
    auto_unpaid_leave.approved_by = nil
    auto_unpaid_leave.save!
  end

  def reject_auto_generated_leave(leave)
    return unless leave && !leave.status_rejected?

    leave.reject_with_balance_restore!(approver_id: nil)
  end

  def sync_half_day_leave_adjustments
    return unless employee.present? && date.present?

    month_start = date.beginning_of_month
    month_end = date.end_of_month
    paid_policy = LeavePolicy.find_by(dept_id: employee.dept_id, leave_type: "paid")
    unpaid_policy = LeavePolicy.find_by(dept_id: employee.dept_id, leave_type: "unpaid")

    existing_paid_leaves = auto_generated_half_day_leaves_for(month_start, month_end, policy: paid_policy, reason: AUTO_PAID_HALF_DAY_REASON)
    existing_unpaid_leaves = auto_generated_half_day_leaves_for(month_start, month_end, policy: unpaid_policy, reason: AUTO_UNPAID_HALF_DAY_REASON)
    target_dates = half_day_adjustment_dates_for_month(month_start, month_end)
    desired_paid_dates, desired_unpaid_dates = desired_half_day_settlement_dates(target_dates, existing_paid_leaves)

    reconcile_half_day_auto_leaves(existing_paid_leaves, desired_paid_dates, paid_policy, AUTO_PAID_HALF_DAY_REASON, paid: true)
    reconcile_half_day_auto_leaves(existing_unpaid_leaves, desired_unpaid_dates, unpaid_policy, AUTO_UNPAID_HALF_DAY_REASON, paid: false)
  end

  def auto_generated_half_day_leaves_for(month_start, month_end, policy:, reason:)
    return Leave.none unless policy

    employee.leaves.where(
      policy_id: policy.policy_id,
      reason: reason,
      start_date: month_start..month_end,
      end_date: month_start..month_end
    )
  end

  def half_day_adjustment_dates_for_month(month_start, month_end)
    half_day_dates = employee.attendances
                             .for_month(month_start.month, month_start.year)
                             .status_half_day
                             .order(:date)
                             .pluck(:date)
                             .select { |attendance_date| working_day_for_date?(attendance_date) }

    half_day_dates.each_slice(2).filter_map do |pair|
      next unless pair.size == 2
      next if external_non_rejected_leave_exists_on?(pair.last)

      pair.last
    end
  end

  def desired_half_day_settlement_dates(target_dates, existing_paid_leaves)
    currently_reserved_paid_days = existing_paid_leaves.where(status: "approved").count
    paid_balance = paid_leave_balance
    available_paid_days = paid_balance.to_i + currently_reserved_paid_days
    paid_dates = target_dates.first([target_dates.count, available_paid_days].min)
    unpaid_dates = target_dates - paid_dates

    [paid_dates, unpaid_dates]
  end

  def paid_leave_balance
    paid_policy = LeavePolicy.find_by(dept_id: employee.dept_id, leave_type: "paid")
    return 0 unless paid_policy

    LeaveBalance.find_by(emp_id: employee.emp_id, policy_id: paid_policy.policy_id, year: date.year)&.remaining.to_i
  end

  def reconcile_half_day_auto_leaves(existing_leaves, desired_dates, policy, reason, paid:)
    existing_by_date = existing_leaves.index_by(&:start_date)

    existing_by_date.each do |leave_date, leave|
      reject_auto_generated_leave(leave) unless desired_dates.include?(leave_date)
    end

    desired_dates.each do |leave_date|
      leave = existing_by_date[leave_date]
      next if leave&.status_approved?

      if paid
        ensure_paid_half_day_leave!(policy, leave_date, leave)
      else
        ensure_unpaid_half_day_leave!(policy, leave_date, leave)
      end
    end
  end

  def ensure_paid_half_day_leave!(policy, leave_date, leave)
    return unless policy

    leave ||= employee.leaves.new(
      policy_id: policy.policy_id,
      start_date: leave_date,
      end_date: leave_date,
      reason: AUTO_PAID_HALF_DAY_REASON,
      status: "pending"
    )

    leave.skip_start_date_not_in_past_validation = true
    unless leave.new_record?
      leave.status = "pending"
      leave.approved_by = nil
    end

    leave.save!
    leave.approve_with_balance(approver_id: nil) || raise(ActiveRecord::RecordInvalid, leave)
  end

  def ensure_unpaid_half_day_leave!(policy, leave_date, leave)
    return unless policy

    leave ||= employee.leaves.new(
      policy_id: policy.policy_id,
      start_date: leave_date,
      end_date: leave_date,
      reason: AUTO_UNPAID_HALF_DAY_REASON
    )

    leave.skip_start_date_not_in_past_validation = true
    leave.status = "approved"
    leave.approved_by = nil
    leave.save!
  end

  def working_day_for_date?(attendance_date)
    working_days = employee.department&.working_days.to_a.reject(&:blank?)
    return true if working_days.blank?

    working_days.include?(attendance_date.strftime("%A"))
  end

  def external_non_rejected_leave_exists_on?(leave_date)
    employee.leaves
            .where.not(status: "rejected")
            .where("start_date <= ? AND end_date >= ?", leave_date, leave_date)
            .where.not(reason: [
              AUTO_PAID_HALF_DAY_REASON,
              AUTO_UNPAID_HALF_DAY_REASON
            ])
            .exists?
  end
end
