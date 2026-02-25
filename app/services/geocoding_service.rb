class GeocodingService
  class << self
    def find_prabhag_from_coordinates(latitude, longitude)
      Rails.logger.info "Geocoding: lat=#{latitude}, lng=#{longitude}"

      # Try prabhag first, then ward
      if (boundary = Boundary.for_point(latitude, longitude, type: :prabhag))
        prabhag = boundary.boundable
        Rails.logger.info "Matched prabhag #{prabhag.number} in ward #{prabhag.ward_code}"
        return [prabhag.ward_code, prabhag.id]
      end

      if (boundary = Boundary.for_point(latitude, longitude, type: :ward))
        ward = boundary.boundable
        Rails.logger.info "Matched ward #{ward.ward_code}"
        return [ward.ward_code, nil]
      end

      Rails.logger.info "No match for #{latitude}, #{longitude}"
      [nil, nil]
    end
  end
end
