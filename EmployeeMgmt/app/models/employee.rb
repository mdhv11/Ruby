class Employee < ApplicationRecord
  self.primary_key = :emp_id

  enum :gender, { male: "male", female: "female" }, prefix: true
  enum :status, {
  onboarding:  "onboarding",
  active:      "active",
  on_leave:    "on_leave",
  terminated:  "terminated",
  resigned:    "resigned"
}, prefix: true

  normalize_enum_attributes :gender, :status

  belongs_to :department, foreign_key: :dept_id, primary_key: :dept_id, optional: true

  has_many :employee_department_histories, foreign_key: :emp_id, primary_key: :emp_id
  has_many :employee_role_histories,       foreign_key: :emp_id, primary_key: :emp_id

  has_many :leave_balances,              foreign_key: :emp_id, primary_key: :emp_id
  has_many :leaves,                      foreign_key: :emp_id, primary_key: :emp_id, class_name: "Leave"
  has_many :attendances,                 foreign_key: :emp_id, primary_key: :emp_id
  has_many :employee_projects,           foreign_key: :emp_id, primary_key: :emp_id
  has_many :projects, through:           :employee_projects
  has_many :payslips,                    foreign_key: :emp_id, primary_key: :emp_id
  has_many :asset_assignment_histories,  foreign_key: :emp_id, primary_key: :emp_id

  has_many :performance_reviews,         foreign_key: :emp_id,        primary_key: :emp_id  # reviews this employee received
  has_many :given_reviews,               foreign_key: :reviewer_id,   primary_key: :emp_id, class_name: "PerformanceReview"  # reviews this employee gave
  has_many :approved_leaves,             foreign_key: :approved_by,   primary_key: :emp_id, class_name: "Leave"
  has_many :managed_projects,            foreign_key: :project_manager, primary_key: :emp_id, class_name: "Project"

  validates :name,         presence: true
  validates :email,        presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone,        presence: true
  validates :dept_id,      presence: true, unless: -> { status_onboarding? }
  validates :joining_date, presence: true, unless: -> { status_onboarding? }
  validates :gender,       presence: true

  validate :resignation_date_after_joining, if: -> { resignation_date.present? }
  validate :termination_reason_required_when_terminated

  def current_role
    employee_role_histories
      .includes(:role)
      .find_by(end_date: nil)
      &.role
  end

  def current_department_from_history
    employee_department_histories
      .includes(:department)
      .find_by(end_date: nil)
      &.department
  end

  def working_days_in_month(month, year)
    working_days = department&.working_days.to_a.reject(&:blank?)
    return 20 if working_days.blank?

    (Date.new(year, month, 1)..Date.new(year, month, -1)).count do |date|
      working_days.include?(date.strftime("%A"))
    end
  end

  def attendance_percentage_for(month, year)
    records = attendances.for_month(month, year)
    working_days = working_days_in_month(month, year)
    return 0.0 if working_days.zero?

    effective_days = records.status_present.count + (records.status_half_day.count * 0.5)
    ((effective_days / working_days.to_f) * 100).round(2)
  end

  def half_day_absence_equivalent_for(month, year)
    attendances.for_month(month, year).status_half_day.count / 2
  end

  private

  def resignation_date_after_joining
    if resignation_date <= joining_date
      errors.add(:resignation_date, "must be after joining date")
    end
  end

  def termination_reason_required_when_terminated
    if status_terminated? && termination_reason.blank?
      errors.add(:termination_reason, "is required when status is terminated")
    end
  end
end
