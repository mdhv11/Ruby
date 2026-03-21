class Attendance < ApplicationRecord
  self.primary_key = :attendance_id

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
end
