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
          # First try parsing with default factory (cartesian)
          feature = RGeo::GeoJSON.decode(boundary.geojson)
          next unless feature

          # Get the geometry
          geometry = feature.respond_to?(:geometry) ? feature.geometry : feature
          next unless geometry

          # Create a point using the same factory as the boundary geometry
          boundary_point = geometry.factory.point(longitude, latitude)

          # Check if the point is within the boundary polygon
          if geometry.contains?(boundary_point)
            Rails.logger.info "Found matching prabhag #{prabhag.id} (#{prabhag.number}) in ward #{prabhag.ward_code}"
            return [prabhag.ward_code, prabhag.id]
          else
            # If point-in-polygon fails, try bounding box as fallback
            require 'json'
            geojson_data = JSON.parse(boundary.geojson)
            coords = if geojson_data['type'] == 'Feature'
                      geojson_data.dig('geometry', 'coordinates')
                    elsif geojson_data['type'] == 'Polygon'
                      geojson_data['coordinates']
                    end

            if coords && coords[0]
              outer_ring = coords[0]
              lats = outer_ring.map { |coord| coord[1] }
              lngs = outer_ring.map { |coord| coord[0] }

              lat_in_range = lats.min <= latitude && latitude <= lats.max
              lng_in_range = lngs.min <= longitude && longitude <= lngs.max

              if lat_in_range && lng_in_range
                Rails.logger.info "Found approximate match (bounding box) for prabhag #{prabhag.id} (#{prabhag.number}) in ward #{prabhag.ward_code}"
                return [prabhag.ward_code, prabhag.id]
              end
            end
          end

        rescue JSON::ParserError => e
          Rails.logger.warn "Failed to parse prabhag #{prabhag.id} boundary: #{e.message}"
          next
        rescue RGeo::Error::ParseError => e
          Rails.logger.warn "Failed to parse prabhag #{prabhag.id} geometry: #{e.message}"
          next
        rescue RGeo::Error::InvalidGeometry => e
          Rails.logger.warn "Invalid geometry for prabhag #{prabhag.id}: #{e.message}"
          # For invalid geometries, try a simple bounding box check as fallback
          begin
            require 'json'
            geojson_data = JSON.parse(boundary.geojson)
            coords = if geojson_data['type'] == 'Feature'
                      geojson_data.dig('geometry', 'coordinates')
                    elsif geojson_data['type'] == 'Polygon'
                      geojson_data['coordinates']
                    end

            if coords && coords[0]
              outer_ring = coords[0]
              lats = outer_ring.map { |coord| coord[1] }
              lngs = outer_ring.map { |coord| coord[0] }

              lat_in_range = lats.min <= latitude && latitude <= lats.max
              lng_in_range = lngs.min <= longitude && longitude <= lngs.max

              if lat_in_range && lng_in_range
                Rails.logger.info "Found approximate match (bounding box) for prabhag #{prabhag.id} (#{prabhag.number}) in ward #{prabhag.ward_code}"
                return [prabhag.ward_code, prabhag.id]
              end
            end
          rescue => fallback_error
            Rails.logger.warn "Fallback bounding box check failed for prabhag #{prabhag.id}: #{fallback_error.message}"
          end
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