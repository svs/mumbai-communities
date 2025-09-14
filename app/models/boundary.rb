class Boundary < ApplicationRecord
  belongs_to :boundable, polymorphic: true
  belongs_to :submitted_by, class_name: 'User', optional: true
  belongs_to :approved_by, class_name: 'User', optional: true

  validates :geojson, presence: true
  validates :source_type, presence: true, inclusion: { in: %w[user_submission official_import kml_import] }
  validates :status, inclusion: { in: %w[pending approved rejected canonical] }
  validates :boundable_type, inclusion: { in: %w[Ward Prabhag] }

  scope :canonical, -> { where(is_canonical: true) }
  scope :for_year, ->(year) { where(year: year) }
  scope :approved, -> { where(status: ['approved', 'canonical']) }
  scope :pending, -> { where(status: 'pending') }
  scope :rejected, -> { where(status: 'rejected') }

  # Semantic scopes for finding the "best" boundary
  scope :best, -> {
    # Priority order: canonical > approved > pending > rejected
    order(
      Arel.sql("CASE
        WHEN status = 'canonical' THEN 1
        WHEN status = 'approved' THEN 2
        WHEN status = 'pending' THEN 3
        WHEN status = 'rejected' THEN 4
        ELSE 5
      END"),
      created_at: :desc
    )
  }

  # Most recent boundaries first
  scope :recent, -> { order(created_at: :desc) }

  # User-submitted boundaries only
  scope :user_submitted, -> { where(source_type: 'user_submission') }

  # Official/imported boundaries only
  scope :official, -> { where(source_type: ['official_import', 'kml_import']) }

  def make_canonical!
    transaction do
      self.class.where(
        boundable_type: boundable_type,
        boundable_id: boundable_id,
        is_canonical: true
      ).update_all(is_canonical: false)

      update!(is_canonical: true, status: 'canonical')
    end
  end

  def approve!(approved_by_user)
    update!(
      status: 'approved',
      approved_by: approved_by_user,
      approved_at: Time.current
    )
  end

  def reject!(approved_by_user, reason = nil)
    update!(
      status: 'rejected',
      approved_by: approved_by_user,
      approved_at: Time.current,
      rejection_reason: reason
    )
  end

  def ward?
    boundable_type == 'Ward'
  end

  def prabhag?
    boundable_type == 'Prabhag'
  end
end
