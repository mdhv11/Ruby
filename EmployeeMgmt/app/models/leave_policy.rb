class LeavePolicy < ApplicationRecord
  self.primary_key = :policy_id

  enum :leave_type, { paid: "paid", unpaid: "unpaid" }, prefix: true
  normalize_enum_attributes :leave_type

  belongs_to :department, foreign_key: :dept_id, primary_key: :dept_id

  has_many :leave_balances, foreign_key: :policy_id, primary_key: :policy_id
  has_many :leaves,         foreign_key: :policy_id, primary_key: :policy_id, class_name: "Leave"

  validates :leave_type,   presence: true
  validates :days_allowed, presence: true, numericality: { greater_than: 0 }
  validates :dept_id,      presence: true
  validates :leave_type,   uniqueness: { scope: :dept_id,
                                         message: "policy for this leave type already exists in this department" }

  validates :carry_forward, inclusion: { in: [true, false] }
end
