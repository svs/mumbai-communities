class Person < ApplicationRecord
  has_many :positions, dependent: :nullify
  has_many :roles, dependent: :destroy

  validates :name, presence: true

  scope :with_role, ->(role_name) { joins(:roles).where(roles: { role_name: role_name }).distinct }

  def active_positions
    positions.where(active: true)
  end

  def current_organisations
    Organisation.where(id: active_positions.select(:organisation_id))
  end
end
