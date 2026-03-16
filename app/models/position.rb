class Position < ApplicationRecord
  belongs_to :department

  validates :designation, presence: true

  scope :senior, -> { where(level: "senior") }
  scope :elected, -> { where(elected: true) }
  scope :appointed, -> { where(elected: false) }
  scope :with_email, -> { where.not(email: [ nil, "" ]) }
  scope :ordered, -> { order(Arel.sql("CASE level
    WHEN 'senior' THEN 1
    WHEN 'mid' THEN 2
    WHEN 'junior' THEN 3
    ELSE 4
  END")) }

  delegate :organisation, to: :department
end
