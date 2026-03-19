class SalaryStructure < ApplicationRecord
  self.primary_key = :structure_id

  belongs_to :role, foreign_key: :role_id, primary_key: :role_id

  has_many :payslips, foreign_key: :structure_id, primary_key: :structure_id

  validates :role_id,      presence: true
  validates :basic_salary, presence: true, numericality: { greater_than: 0 }
  validates :bonus,        numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :tax_percent,  numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :deductions,   numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :role_id,      uniqueness: { message: "already has a salary structure" }
end