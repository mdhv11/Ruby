class AssetAssignmentHistory < ApplicationRecord
  self.primary_key = nil

  belongs_to :asset,    foreign_key: :asset_id, primary_key: :asset_id
  belongs_to :employee, foreign_key: :emp_id,   primary_key: :emp_id

  validates :asset_id,      presence: true
  validates :emp_id,        presence: true
  validates :assigned_date, presence: true

  validate :returned_date_after_assigned_date, if: -> { returned_date.present? }
  validate :no_open_assignment_for_asset,      on: :create

  private

  def returned_date_after_assigned_date
    if returned_date < assigned_date
      errors.add(:returned_date, "cannot be before assigned date")
    end
  end

  def no_open_assignment_for_asset
    # Prevent assigning an already-assigned asset
    if AssetAssignmentHistory.exists?(asset_id: asset_id, returned_date: nil)
      errors.add(:asset_id, "is already assigned to someone. Return it first.")
    end
  end
end