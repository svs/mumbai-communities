class Organisation < ApplicationRecord
  belongs_to :organisable, polymorphic: true, optional: true
  belongs_to :parent, class_name: "Organisation", optional: true
  has_many :children, class_name: "Organisation", foreign_key: :parent_id, dependent: :destroy

  has_many :departments, dependent: :destroy
  has_many :positions, dependent: :destroy

  validates :name, presence: true
  validates :org_type, presence: true

  scope :by_type, ->(type) { where(org_type: type) }
  scope :top_level, -> { where(parent: nil) }
  scope :for_place, ->(place) { where(organisable: place) }

  def active_positions
    positions.active.ordered.includes(:person)
  end

  def people
    Person.where(id: positions.active.select(:person_id))
  end
end
