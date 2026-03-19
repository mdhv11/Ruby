class PerformanceReview < ApplicationRecord
  self.primary_key = :review_id

  belongs_to :employee, foreign_key: :emp_id,       primary_key: :emp_id
  belongs_to :reviewer, foreign_key: :reviewer_id,  primary_key: :emp_id, class_name: "Employee"

  validates :emp_id,      presence: true
  validates :reviewer_id, presence: true
  validates :review_date, presence: true
  validates :rating,      presence: true,
            numericality: { only_integer: true, in: 1..5 }
  validates :feedback,    presence: true

  validate :cannot_review_yourself
  validate :review_date_not_in_future
  validate :reviewer_must_be_active

  private

  def cannot_review_yourself
    if emp_id.present? && reviewer_id.present? && emp_id == reviewer_id
      errors.add(:reviewer_id, "cannot review themselves")
    end
  end

  def review_date_not_in_future
    if review_date.present? && review_date > Date.today
      errors.add(:review_date, "cannot be in the future")
    end
  end

  def reviewer_must_be_active
    if reviewer_id.present?
      reviewer = Employee.find_by(emp_id: reviewer_id)
      unless reviewer&.status_active?
        errors.add(:reviewer_id, "must be an active employee")
      end
    end
  end
end