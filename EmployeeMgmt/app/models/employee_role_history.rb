class EmployeeRoleHistory < ApplicationRecord
  self.primary_key = nil
  belongs_to :employee, foreign_key: :emp_id,   primary_key: :emp_id
  belongs_to :role,     foreign_key: :role_id,  primary_key: :role_id
end