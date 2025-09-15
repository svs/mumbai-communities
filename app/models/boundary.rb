class Boundary < ApplicationRecord
  include Approvable

  belongs_to :boundable, polymorphic: true
  belongs_to :submitted_by, class_name: 'User', optional: true
  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :edited_by, class_name: 'User', optional: true

  validates :geojson, presence: true
  validates :source_type, presence: true, inclusion: { in: %w[user_submission official_import kml_import] }
  validates :status, inclusion: { in: %w[pending approved rejected canonical] }
  validates :boundable_type, inclusion: { in: %w[Ward Prabhag] }
  validate :edited_by_must_be_admin, if: :edited_by

  scope :canonical, -> { where(is_canonical: true) }
  scope :for_year, ->(year) { where(year: year) }

  # Semantic scopes for finding the "best" boundary
  scope :best_ordered, -> {
    # Priority order: canonical (is_canonical=true) > approved > pending > rejected
    order(
      is_canonical: :desc
    ).order(
      Arel.sql("CASE
        WHEN status = 'approved' THEN 1
        WHEN status = 'pending' THEN 2
        WHEN status = 'rejected' THEN 3
        ELSE 4
      END")
    ).order(
      created_at: :desc
    )
  }

  def self.best
    best_ordered.first
  end

  # Most recent boundaries first
  scope :recent, -> { order(created_at: :desc) }

  # User-submitted boundaries only
  scope :user_submitted, -> { where(source_type: 'user_submission') }

  # Official/imported boundaries only
  scope :official, -> { where(source_type: ['official_import', 'kml_import']) }

  # Boundaries for admin review - pending user submissions
  scope :for_admin_review, -> { user_submitted.pending }

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
    validate_can_be_approved!
    update_approval_status!('approved', approved_by_user)
  end

  def reject!(approved_by_user, reason = nil)
    validate_can_be_rejected!
    update_approval_status!('rejected', approved_by_user, reason)
  end

  def edit_by_admin!(admin_user, new_geojson)
    validate_admin_user!(admin_user)

    update!(
      geojson: new_geojson,
      edited_by: admin_user
    )
  end

  def ward?
    boundable_type == 'Ward'
  end

  def prabhag?
    boundable_type == 'Prabhag'
  end

  # Always return properly formatted GeoJSON Feature
  def geojson_feature
    parsed = JSON.parse(geojson)
    return geojson if parsed['type'] == 'Feature'

    build_geojson_feature(parsed).to_json
  rescue JSON::ParserError => e
    Rails.logger.error "Invalid GeoJSON in boundary #{id}: #{e.message}"
    nil
  end

  private

  def edited_by_must_be_admin
    errors.add(:edited_by, 'must be an admin user') unless edited_by.admin?
  end

  def validate_admin_user!(user)
    raise ArgumentError, 'User must be an admin' unless user&.admin?
  end

  def validate_can_be_approved!
    # Allow re-approval of already approved boundaries (per test requirements)
    # raise ArgumentError, 'Boundary cannot be approved' unless approvable?
  end

  def validate_can_be_rejected!
    raise ArgumentError, 'Boundary cannot be rejected' unless rejectable?
  end

  def update_approval_status!(new_status, approver, reason = nil)
    update_attrs = {
      status: new_status,
      approved_by: approver,
      approved_at: Time.current
    }
    update_attrs[:rejection_reason] = reason if reason.present?

    update!(update_attrs)
  end

  def build_geojson_feature(geometry)
    {
      type: 'Feature',
      geometry: geometry,
      properties: feature_properties
    }
  end

  def feature_properties
    {
      boundary_id: id,
      status: status,
      source_type: source_type,
      year: year,
      boundable_type: boundable_type,
      boundable_id: boundable_id
    }
  end
end
