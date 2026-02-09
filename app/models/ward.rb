class Ward < ApplicationRecord
  include HasPois

  has_many :prabhags, foreign_key: 'ward_code', primary_key: 'ward_code'
  has_many :tickets, foreign_key: 'ward_code', primary_key: 'ward_code'
  has_many :boundaries, as: :boundable, dependent: :destroy
  
  validates :ward_code, presence: true, uniqueness: true
  validates :name, presence: true

  def to_param
    return ward_code.downcase if name.blank?
    name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
  end
  
  scope :geocoded, -> { where(is_geocoded: true) }
  scope :not_geocoded, -> { where(is_geocoded: false) }
  
  def completion_percentage
    return 0 if prabhags.count.zero?

    # Count prabhags where the best boundary is from 2017 (legacy data)
    legacy_prabhags = prabhags.select do |p|
      best_boundary = p.boundary
      best_boundary && best_boundary.year == 2017
    end

    (legacy_prabhags.count.to_f / prabhags.count * 100).round(1)
  end
  
  
  # Check if ward has all prabhags mapped
  def fully_mapped?
    return false if prabhags.count.zero?
    
    prabhags.all? { |p| p.boundary_geojson.present? }
  end
  
  # Get ward center from mapped prabhags
  def center_coordinates
    return nil unless fully_mapped?

    # Calculate centroid from all prabhag boundaries
    # This is a simplified calculation - in production you'd use proper GIS
    boundaries = prabhags.map(&:boundary_center).compact
    return nil if boundaries.empty?

    avg_lat = boundaries.sum { |coords| coords[0] } / boundaries.size
    avg_lng = boundaries.sum { |coords| coords[1] } / boundaries.size
    [avg_lat, avg_lng]
  end

  # Check if ward has boundary data in the new Boundary model
  def has_ward_boundary?
    boundaries.where(status: ['approved', 'canonical']).exists?
  end

  # Count prabhags with boundary data in the new Boundary model
  def prabhags_with_boundaries_count
    prabhags.joins(:boundaries)
            .where(boundaries: { status: ['approved', 'canonical'] })
            .distinct
            .count
  end

  # Get boundary mapping completion percentage (separate from legacy boundary_geojson)
  def boundary_mapping_percentage
    return 0 if prabhags.count.zero?

    mapped_count = prabhags_with_boundaries_count
    (mapped_count.to_f / prabhags.count * 100).round(1)
  end

  # Check if ward is fully boundary-mapped using the new system
  def fully_boundary_mapped?
    return false if prabhags.count.zero?

    prabhags_with_boundaries_count == prabhags.count
  end

  # Semantic boundary finders - get the best available boundary
  def boundary
    boundaries.best
  end

  # Get the approved boundary (approved or canonical)
  def approved_boundary
    boundaries.approved.recent.first
  end

  # Get the canonical boundary (official)
  def canonical_boundary
    boundaries.canonical.first
  end

  # Get the most recent user-submitted boundary
  def latest_user_boundary
    boundaries.user_submitted.recent.first
  end

  # Get all boundaries for this ward, ordered by best first
  def all_boundaries
    boundaries.order(
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
  end

  # Check if ward has any boundary data
  def has_boundary?
    boundaries.exists?
  end

  # Get open tickets count for this ward
  def open_tickets
    tickets.open.count
  end

  # Get overdue tickets count for this ward
  def overdue_tickets
    tickets.overdue.count
  end
end
