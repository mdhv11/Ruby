class Asset < ApplicationRecord
  self.primary_key = :asset_id
  self.inheritance_column = :_type_disabled

  enum :status, {
    assigned:  "assigned",
    idle:      "idle",
    in_repair: "in_repair",
    sold:      "sold"
  }, prefix: true

  has_many :asset_assignment_histories, foreign_key: :asset_id, primary_key: :asset_id

  has_one :current_assignment,
          -> { where(returned_date: nil) },
          class_name: "AssetAssignmentHistory",
          foreign_key: :asset_id,
          primary_key: :asset_id

  validates :asset_name,    presence: true
  validates :asset_type,    presence: true
  validates :purchase_date, presence: true
  validates :status,        presence: true

  validate :not_assignable_when_sold_or_in_repair, if: -> { status_assigned? }

  private

  def not_assignable_when_sold_or_in_repair
    if status_sold? || status_in_repair?
      errors.add(:status, "cannot be assigned while sold or in repair")
    end
  end
end
