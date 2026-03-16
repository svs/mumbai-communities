class Municipality < ApplicationRecord
  has_many :wards

  validates :name, presence: true
end
