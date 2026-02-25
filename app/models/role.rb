class Role < ApplicationRecord
  belongs_to :person
  belongs_to :roleable, polymorphic: true

  validates :role_name, presence: true

  scope :active, -> { where(ended_at: nil).or(where(ended_at: Time.current..)) }
end
