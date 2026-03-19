class Project < ApplicationRecord
  self.primary_key = :project_id

  enum :status, {
    assigned:    "assigned",
    in_progress: "in_progress",
    completed:   "completed"
  }, prefix: true

  normalize_enum_attributes :status

  belongs_to :department,      foreign_key: :dept_id,         primary_key: :dept_id
  belongs_to :manager,         foreign_key: :project_manager, primary_key: :emp_id,
             class_name: "Employee", optional: true

  has_many :employee_projects, foreign_key: :project_id, primary_key: :project_id
  has_many :employees, through: :employee_projects

  validates :project_name, presence: true
  validates :dept_id,      presence: true
  validates :status,       presence: true
  validates :start_date,   presence: true

  validate :end_date_after_start_date,       if: -> { end_date.present? }
  validate :manager_belongs_to_department,   if: -> { project_manager.present? }
  validate :cannot_reopen_completed_project, if: -> { status_changed? && status_completed? }

  private

  def end_date_after_start_date
    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def manager_belongs_to_department
    unless Employee.exists?(emp_id: project_manager, dept_id: dept_id)
      errors.add(:project_manager, "must be an employee of the project's department")
    end
  end

  def cannot_reopen_completed_project
    if status_completed? && status_was != "completed"
    end
    if status_was == "completed" && !status_completed?
      errors.add(:status, "cannot be changed once project is completed")
    end
  end
end