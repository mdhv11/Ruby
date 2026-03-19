class EmployeeProject < ApplicationRecord
  self.primary_key = nil
  belongs_to :employee, foreign_key: :emp_id,      primary_key: :emp_id
  belongs_to :project,  foreign_key: :project_id,  primary_key: :project_id
end