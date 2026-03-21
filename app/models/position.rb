class Position < ApplicationRecord
  belongs_to :organisation
  belongs_to :person, optional: true
  belongs_to :department, optional: true # legacy, being phased out

  validates :designation, presence: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :senior, -> { where(level: "senior") }
  scope :elected, -> { where(elected: true) }
  scope :appointed, -> { where(elected: false) }
  scope :with_person, -> { where.not(person_id: nil) }
  scope :vacant, -> { where(person_id: nil) }
  scope :ordered, -> { order(Arel.sql("CASE level
    WHEN 'senior' THEN 1
    WHEN 'mid' THEN 2
    WHEN 'junior' THEN 3
    ELSE 4
  END")) }

  def vacant?
    person_id.nil?
  end

  def transfer_to!(new_person, started_on: Date.current)
    transaction do
      # End current tenure
      update!(active: false, ended_on: started_on) if person_id.present?

      # Create new tenure
      self.class.create!(
        organisation: organisation,
        designation: designation,
        email: email,
        level: level,
        section: section,
        person: new_person,
        active: true,
        started_on: started_on
      )
    end
  end
end
