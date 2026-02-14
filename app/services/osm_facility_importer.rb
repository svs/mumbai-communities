class OsmFacilityImporter
  # Map OSM amenity/leisure types to our facility_type
  TYPE_MAP = {
    "hospital" => "hospital",
    "school" => "school",
    "college" => "school",
    "police" => "police",
    "fire_station" => "fire_station",
    "library" => "library",
    "place_of_worship" => "place_of_worship",
    "pharmacy" => "pharmacy",
    "bank" => "bank",
    "post_office" => "post_office",
    "park" => "park",
    "playground" => "playground",
    "bus_station" => "bus_station",
    "station" => "railway_station"
  }.freeze

  ALL_CATEGORIES = OsmService::CATEGORY_TAGS.keys.freeze

  class << self
    def import_all(ward_codes: nil)
      wards = if ward_codes
        Ward.where(ward_code: ward_codes)
      else
        Ward.all
      end

      total = 0
      wards.find_each do |ward|
        count = import_ward(ward)
        total += count
        Rails.logger.info "OsmFacilityImporter: Imported #{count} POIs for ward #{ward.ward_code}"
      end

      total
    end

    def import_ward(ward)
      boundary = ward.boundary || ward.approved_boundary
      return 0 unless boundary&.geojson.present?

      pois = OsmService.pois_within(boundary.geojson, categories: ALL_CATEGORIES)
      return 0 if pois.empty?

      imported = 0
      pois.each do |poi|
        external_id = build_external_id(poi)
        facility_type = map_type(poi[:type])
        next unless facility_type

        facility = Facility.find_or_initialize_by(source: "osm", external_id: external_id)
        facility.assign_attributes(
          name: poi[:name],
          facility_type: facility_type,
          ward_code: ward.ward_code,
          latitude: poi[:lat],
          longitude: poi[:lng],
          raw_data: poi[:tags],
          content_hash: Digest::SHA256.hexdigest(poi[:tags].to_json),
          last_seen_at: Time.current
        )
        facility.save!
        imported += 1
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn "OsmFacilityImporter: Skipping POI #{external_id}: #{e.message}"
      end

      imported
    end

    private

    def build_external_id(poi)
      # OSM POIs from Overpass have an id and type in their tags
      tags = poi[:tags] || {}
      osm_type = tags["osm_type"] || "node"
      osm_id = tags["osm_id"]

      if osm_id
        "#{osm_type}/#{osm_id}"
      else
        # Fallback: use coordinates + type as a stable ID
        "#{poi[:type]}/#{poi[:lat]&.round(6)},#{poi[:lng]&.round(6)}"
      end
    end

    def map_type(osm_type)
      TYPE_MAP[osm_type.to_s]
    end
  end
end
