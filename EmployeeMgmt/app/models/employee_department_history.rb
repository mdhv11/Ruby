class EmployeeDepartmentHistory < ApplicationRecord
  self.primary_key = nil
  belongs_to :employee,   foreign_key: :emp_id,   primary_key: :emp_id
  belongs_to :department, foreign_key: :dept_id,  primary_key: :dept_id
end