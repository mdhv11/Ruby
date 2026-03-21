class Payroll < ApplicationRecord
  self.primary_key = :payroll_id

  alias_attribute :amount_disbursed, :salary

  belongs_to :payslip, foreign_key: :payslip_id, primary_key: :payslip_id

  validates :payslip_id,       presence: true
  validates :amount_disbursed, presence: true, numericality: { greater_than: 0 }
  validates :date,             presence: true
  validates :payslip_id,       uniqueness: { message: "has already been disbursed" }

  validate :amount_matches_net_salary

  private

  def amount_matches_net_salary
    return unless payslip.present? && amount_disbursed.present?

    if amount_disbursed != payslip.net_salary
      errors.add(:amount_disbursed, "must match net salary on payslip (#{payslip.net_salary})")
    end
  end
end
