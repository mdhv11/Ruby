class Organization < ApplicationRecord
  self.primary_key = :org_id

  has_many :departments, foreign_key: :org_id, primary_key: :org_id, dependent: :restrict_with_error
  has_many :roles,       foreign_key: :org_id, primary_key: :org_id, dependent: :restrict_with_error

  has_many :employees, through: :departments

  validates :name,     presence: true, uniqueness: { case_sensitive: false }
  validates :industry, presence: true
  validates :ceo,      presence: true
  validates :address,  presence: true
end