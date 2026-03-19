class LeaveBalance < ApplicationRecord
  self.primary_key = nil

  belongs_to :employee,     foreign_key: :emp_id,    primary_key: :emp_id
  belongs_to :leave_policy, foreign_key: :policy_id, primary_key: :policy_id

  validates :emp_id,        presence: true
  validates :policy_id,     presence: true
  validates :year,          presence: true,
            numericality: { only_integer: true, greater_than: 2000 }
  validates :total_allowed, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :used,          presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :remaining,     presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :emp_id,        uniqueness: { scope: [:policy_id, :year],
                                          message: "balance already exists for this employee, policy, and year" }

  validate :used_cannot_exceed_total

  def self.find_or_initialize_for(emp_id:, policy_id:, year:)
    find_by(emp_id: emp_id, policy_id: policy_id, year: year) ||
      new(
        emp_id:        emp_id,
        policy_id:     policy_id,
        year:          year,
        total_allowed: LeavePolicy.find_by(policy_id: policy_id)&.days_allowed || 0,
        used:          0,
        remaining:     LeavePolicy.find_by(policy_id: policy_id)&.days_allowed || 0
      )
  end

  private

  def used_cannot_exceed_total
    if used.present? && total_allowed.present? && used > total_allowed
      errors.add(:used, "cannot exceed total allowed days")
    end
  end
end