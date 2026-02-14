class Facility < ApplicationRecord
  belongs_to :ward, foreign_key: "ward_code", primary_key: "ward_code", optional: true

  validates :facility_type, presence: true
  validates :source, presence: true
  validates :external_id, uniqueness: { scope: :source }, allow_nil: true

  SOURCES = %w[bmc_arcgis bmc_portal osm].freeze
  FACILITY_TYPES = %w[
    hospital school toilet park parking fire_station library
    police place_of_worship pharmacy bank post_office
    playground bus_station railway_station garden open_space
    ward_office community_hall market swimming_pool
  ].freeze

  validates :source, inclusion: { in: SOURCES }

  scope :from_bmc, -> { where(source: %w[bmc_arcgis bmc_portal]) }
  scope :from_osm, -> { where(source: "osm") }
  scope :from_arcgis, -> { where(source: "bmc_arcgis") }
  scope :of_type, ->(type) { where(facility_type: type) }
  scope :in_ward, ->(ward_code) { where(ward_code: ward_code) }

  def coordinates
    [latitude, longitude] if latitude && longitude
  end

  def compute_content_hash
    Digest::SHA256.hexdigest(raw_data.to_json) if raw_data
  end

  def update_content_hash!
    update!(content_hash: compute_content_hash)
  end
end
