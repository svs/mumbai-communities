class Prabhag < ApplicationRecord
  belongs_to :assigned_to, class_name: "User", optional: true
  belongs_to :ward, foreign_key: "ward_code", primary_key: "ward_code"
  has_many :tickets, foreign_key: [ "prabhag_number", "ward_code" ], primary_key: [ "number", "ward_code" ]

  validates :number, presence: true, uniqueness: { scope: :ward_code }
  validates :ward_code, presence: true
  validates :pdf_url, presence: true
  validates :status, inclusion: { in: %w[available assigned submitted approved rejected] }

  before_create :set_default_status

  scope :available, -> { where(status: "available", assigned_to: nil) }
  scope :assigned, -> { where(status: "assigned") }
  scope :submitted, -> { where(status: "submitted") }
  scope :approved, -> { where(status: "approved") }
  scope :for_ward, ->(ward_code) { where(ward_code: ward_code) }

  def can_be_assigned_to?(user)
    status == "available" && assigned_to.nil?
  end

  def assign_to!(user)
    update!(assigned_to: user, status: "assigned")
  end

  def submit_boundary!(geojson)
    update!(boundary_geojson: geojson, status: "submitted")
  end

  def approve!
    update!(status: "approved")
  end

  def reject!
    update!(status: "rejected", assigned_to: nil)
  end

  # Get path to the converted PNG image for the boundary tracer
  def map_image_src
    "/prabhag_images/prabhag_#{number}.png"
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
end
