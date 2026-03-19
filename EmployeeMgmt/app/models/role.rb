class Role < ApplicationRecord
  self.primary_key = :role_id

  belongs_to :organization, foreign_key: :org_id,  primary_key: :org_id
  belongs_to :department,   foreign_key: :dept_id, primary_key: :dept_id

  has_one  :salary_structure,       foreign_key: :role_id, primary_key: :role_id, dependent: :restrict_with_error
  has_many :employee_role_histories, foreign_key: :role_id, primary_key: :role_id

  validates :name,        presence: true
  validates :org_id,      presence: true
  validates :dept_id,     presence: true
  validates :name,        uniqueness: { scope: :dept_id, case_sensitive: false,
                                        message: "already exists in this department" }

  def current_employees
    Employee.joins(:employee_role_histories)
            .where(employee_role_histories: { role_id: role_id, end_date: nil })
  end
end