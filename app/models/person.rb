class Person < ApplicationRecord
  has_many :roles, dependent: :destroy

  validates :name, presence: true

  scope :with_role, ->(role_name) { joins(:roles).where(roles: { role_name: role_name }).distinct }
end
