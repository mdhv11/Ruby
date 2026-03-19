class Payslip < ApplicationRecord
  self.primary_key = :payslip_id

  belongs_to :employee,         foreign_key: :emp_id,       primary_key: :emp_id
  belongs_to :salary_structure, foreign_key: :structure_id, primary_key: :structure_id

  has_one :payroll, foreign_key: :payslip_id, primary_key: :payslip_id

  validates :emp_id,       presence: true
  validates :structure_id, presence: true
  validates :month,        presence: true, numericality: { only_integer: true, in: 1..12 }
  validates :year,         presence: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :emp_id,       uniqueness: { scope: [:month, :year],
                                         message: "already has a payslip for this month and year" }

  validates :unpaid_leave_deduction, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :overtime_bonus,         numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :calculate_net_salary

  def disbursed?
    payroll.present?
  end

  private

  def calculate_net_salary
    return unless salary_structure.present?

    gross = salary_structure.basic_salary +
            (salary_structure.bonus        || 0) +
            (overtime_bonus                || 0)

    tax          = (gross * ((salary_structure.tax_percent || 0) / 100.0))
    total_deduct = (salary_structure.deductions        || 0) +
                   (unpaid_leave_deduction             || 0) +
                   tax

    self.net_salary = (gross - total_deduct).round(2)
  end
end