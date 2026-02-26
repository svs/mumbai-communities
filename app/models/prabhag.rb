class Prabhag < ApplicationRecord
  include HasPois
  include Discussable

  belongs_to :assigned_to, class_name: "User", optional: true
  belongs_to :ward, foreign_key: "ward_code", primary_key: "ward_code"
  has_many :tickets, foreign_key: [ "prabhag_number", "ward_code" ], primary_key: [ "number", "ward_code" ]
  has_many :boundaries, as: :boundable, dependent: :destroy
  has_many :facilities, foreign_key: "prabhag_number", primary_key: "number"
  has_many :roles, as: :roleable, dependent: :destroy
  has_many :people, through: :roles

  validates :number, presence: true, uniqueness: { scope: :ward_code }
  validates :ward_code, presence: true
  validates :pdf_url, presence: true
  validates :status, inclusion: { in: %w[available assigned submitted approved rejected] }

  # Override find to work with both number and id for consistent routing
  def self.find(id)
    # Try to find by number first (for URL params), then by id
    find_by(number: id) || super(id)
  end

  def to_param
    number.to_s
  end

  before_create :set_default_status

  scope :available, -> { where(status: "available", assigned_to: nil) }
  scope :assigned, -> { where(status: "assigned") }
  scope :submitted, -> { where(status: "submitted") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :for_ward, ->(ward_code) { where(ward_code: ward_code) }

  def can_be_assigned_to?(user)
    status == "available" && assigned_to.nil?
  end

  def assign_to!(user)
    update!(assigned_to: user, status: "assigned")
  end

  def submit_boundary!(geojson, submitted_by: nil)
    transaction do
      # Create a new user-submitted boundary traced from MCGM PDF
      boundaries.create!(
        geojson: geojson,
        source_type: 'user_submission',
        year: 2025,
        status: 'pending',
        is_canonical: false,
        submitted_by: submitted_by
      )

      # Update prabhag status
      update!(status: "submitted")
    end
  end


  # Get path to the converted PNG image for the boundary tracer
  def map_image_src
    "/prabhag_images/prabhag_#{number}.png"
  end

  # Computed mapping status derived from actual boundary records (not prabhag.status)
  def computed_mapping_status
    best = boundary
    return :unmapped unless best

    case best.source_type
    when 'kml_import'
      :legacy_needs_remapping
    when 'official_import'
      best.status == 'canonical' ? :official_canonical : :official_approved
    when 'user_submission'
      case best.status
      when 'pending' then :pending_review
      when 'approved' then :community_approved
      when 'rejected' then :rejected
      else :unknown
      end
    else
      :unknown
    end
  end

  # Lifecycle stage — determines what the prabhag page shows and what actions are available
  # :unmapped → :pending → :mapped → :enriched → :active
  def lifecycle_stage
    best = boundary
    return :unmapped unless best
    return :pending if best.status == 'pending'

    # Has an approved/canonical boundary — check if enriched with facilities
    facility_count = Facility.where(ward_code: ward_code).count
    has_discussions = respond_to?(:discussions) && discussions.exists?

    if has_discussions && facility_count > 0
      :active
    elsif facility_count > 0
      :enriched
    else
      :mapped
    end
  end

  # Badge display data for the computed mapping status
  def mapping_status_badge
    case computed_mapping_status
    when :unmapped
      { label: "Unmapped", bg: "bg-red-50", text: "text-red-700" }
    when :legacy_needs_remapping
      { label: "Legacy — needs remapping", bg: "bg-orange-50", text: "text-orange-700" }
    when :official_canonical
      { label: "Official", bg: "bg-green-50", text: "text-green-700" }
    when :official_approved
      { label: "Approved", bg: "bg-green-50", text: "text-green-700" }
    when :pending_review
      { label: "Under review", bg: "bg-yellow-50", text: "text-yellow-700" }
    when :community_approved
      { label: "Community mapped", bg: "bg-purple-50", text: "text-purple-700" }
    when :rejected
      { label: "Rejected — needs remapping", bg: "bg-red-50", text: "text-red-700" }
    else
      { label: "Unknown", bg: "bg-gray-100", text: "text-gray-600" }
    end
  end

  private

  def set_default_status
    self.status ||= "available"
  end

  public

  # Convert GeoJSON string to RGeo geometry
  def boundary_geometry
    return nil unless boundary_geojson.present?

    begin
      geojson_hash = JSON.parse(boundary_geojson)
      RGeo::GeoJSON.decode(geojson_hash)
    rescue JSON::ParserError, RGeo::Error::ParseError
      nil
    end
  end

  # Convert geometry to GeoJSON
  def geometry_to_geojson(geometry)
    RGeo::GeoJSON.encode(geometry).to_json if geometry
  end

  # Calculate approximate area in square meters
  def boundary_area_sqm
    geom = boundary_geometry
    return nil unless geom && geom.respond_to?(:area)

    # Simple area calculation (this would be more accurate with proper projection)
    geom.area * 111_000 * 111_000  # Rough conversion from degrees to meters
  end

  # Get boundary centroid
  def boundary_center
    return nil unless boundary_geojson.present?

    begin
      geojson_hash = JSON.parse(boundary_geojson)
      coordinates = geojson_hash.dig("geometry", "coordinates", 0)
      return nil unless coordinates && coordinates.any?

      # Simple centroid calculation - average of all points
      lats = coordinates.map { |coord| coord[1] }
      lngs = coordinates.map { |coord| coord[0] }

      [ lats.sum / lats.size, lngs.sum / lngs.size ]
    rescue JSON::ParserError
      nil
    end
  end

  public :boundary_center

  # Semantic boundary finders - get the best available boundary
  def boundary
    Boundary.where(id: boundaries.select(:id)).best
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

  # Get all boundaries for this prabhag, ordered by best first
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

  # Check if prabhag has any boundary data
  def has_boundary?
    boundaries.exists?
  end

  # Check if prabhag needs mapping (no boundaries or only legacy boundaries)
  def needs_mapping?
    # No boundaries at all = needs mapping
    return true unless has_boundary?

    # Only has legacy boundaries (kml_import) = needs mapping
    # Official boundaries (official_import with canonical/approved status) = doesn't need mapping
    approved_boundary = self.approved_boundary
    return true unless approved_boundary

    # If the approved boundary is from legacy KML import, it needs new mapping
    approved_boundary.source_type == 'kml_import'
  end
end
