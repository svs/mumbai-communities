require 'rgeo/geo_json'

class GeocodingService
  class << self
    def find_prabhag_from_coordinates(latitude, longitude)
      # Create a point from the coordinates
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      point = factory.point(longitude, latitude)

      Rails.logger.info "Geocoding point: #{point} (lat: #{latitude}, lng: #{longitude})"

      # Check all prabhags with boundaries for point-in-polygon containment
      Prabhag.joins(:boundaries)
             .where(boundaries: { status: ['approved', 'canonical'] })
             .includes(:boundaries)
             .find_each do |prabhag|

        boundary = prabhag.boundaries.find { |b| ['approved', 'canonical'].include?(b.status) }
        next unless boundary&.geojson

        begin
          # Parse the GeoJSON and create RGeo geometry
          feature = RGeo::GeoJSON.decode(boundary.geojson)
          next unless feature

          # Check if the point is within the boundary polygon
          # feature might be a Feature (with .geometry) or directly a geometry object
          geometry = feature.respond_to?(:geometry) ? feature.geometry : feature
          if geometry && geometry.contains?(point)
            Rails.logger.info "Found matching prabhag #{prabhag.id} (#{prabhag.number}) in ward #{prabhag.ward_code}"
            return [prabhag.ward_code, prabhag.id]
          end
        rescue JSON::ParserError => e
          Rails.logger.warn "Failed to parse prabhag #{prabhag.id} boundary: #{e.message}"
          next
        rescue RGeo::Error::ParseError => e
          Rails.logger.warn "Failed to parse prabhag #{prabhag.id} geometry: #{e.message}"
          next
        rescue StandardError => e
          Rails.logger.warn "Error processing prabhag #{prabhag.id}: #{e.message}"
          next
        end
      end

      Rails.logger.info "No matching prabhag found for coordinates #{latitude}, #{longitude}"
      [nil, nil]
    end
  end
end