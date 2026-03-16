class Department < ApplicationRecord
  belongs_to :organisation
  has_many :positions, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(:name) }
end
