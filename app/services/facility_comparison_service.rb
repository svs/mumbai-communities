class FacilityComparisonService
  MATCH_RADIUS_METERS = 100
  EARTH_RADIUS_METERS = 6_371_000

  class << self
    def compare(ward_code:, facility_type: nil)
      bmc_facilities = Facility.from_bmc.in_ward(ward_code)
      osm_facilities = Facility.from_osm.in_ward(ward_code)

      if facility_type
        bmc_facilities = bmc_facilities.of_type(facility_type)
        osm_facilities = osm_facilities.of_type(facility_type)
      end

      bmc_list = bmc_facilities.to_a
      osm_list = osm_facilities.to_a

      matched = []
      bmc_matched_ids = Set.new
      osm_matched_ids = Set.new

      bmc_list.each do |bmc|
        next unless bmc.latitude && bmc.longitude

        best_match = nil
        best_distance = Float::INFINITY

        osm_list.each do |osm|
          next unless osm.latitude && osm.longitude
          next if osm_matched_ids.include?(osm.id)

          distance = haversine_distance(bmc.latitude, bmc.longitude, osm.latitude, osm.longitude)
          next unless distance < MATCH_RADIUS_METERS

          if distance < best_distance
            name_score = fuzzy_name_match(bmc.name, osm.name)
            if name_score > 0.3 || bmc.name.blank? || osm.name.blank?
              best_match = osm
              best_distance = distance
            end
          end
        end

        if best_match
          matched << {
            bmc: facility_summary(bmc),
            osm: facility_summary(best_match),
            distance_meters: best_distance.round(1),
            name_similarity: fuzzy_name_match(bmc.name, best_match.name).round(2)
          }
          bmc_matched_ids << bmc.id
          osm_matched_ids << best_match.id
        end
      end

      bmc_only = bmc_list.reject { |f| bmc_matched_ids.include?(f.id) }.map { |f| facility_summary(f) }
      osm_only = osm_list.reject { |f| osm_matched_ids.include?(f.id) }.map { |f| facility_summary(f) }

      {
        bmc_only: bmc_only,
        osm_only: osm_only,
        matched: matched,
        bmc_count: bmc_list.size,
        osm_count: osm_list.size,
        matched_count: matched.size
      }
    end

    def compare_all(facility_type: nil)
      results = {}
      Ward.pluck(:ward_code).each do |ward_code|
        result = compare(ward_code: ward_code, facility_type: facility_type)
        results[ward_code] = result if result[:bmc_count] > 0 || result[:osm_count] > 0
      end
      results
    end

    private

    def haversine_distance(lat1, lng1, lat2, lng2)
      dlat = to_rad(lat2 - lat1)
      dlng = to_rad(lng2 - lng1)
      a = Math.sin(dlat / 2)**2 +
          Math.cos(to_rad(lat1)) * Math.cos(to_rad(lat2)) * Math.sin(dlng / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      EARTH_RADIUS_METERS * c
    end

    def to_rad(degrees)
      degrees * Math::PI / 180
    end

    def fuzzy_name_match(name1, name2)
      return 0.0 if name1.blank? || name2.blank?

      s1 = name1.to_s.downcase.strip
      s2 = name2.to_s.downcase.strip

      return 1.0 if s1 == s2

      # Trigram similarity
      t1 = trigrams(s1)
      t2 = trigrams(s2)
      return 0.0 if t1.empty? && t2.empty?

      intersection = (t1 & t2).size.to_f
      union = (t1 | t2).size.to_f
      union.zero? ? 0.0 : intersection / union
    end

    def trigrams(str)
      padded = "  #{str} "
      (0..padded.length - 3).map { |i| padded[i, 3] }
    end

    def facility_summary(facility)
      {
        id: facility.id,
        name: facility.name,
        facility_type: facility.facility_type,
        source: facility.source,
        latitude: facility.latitude,
        longitude: facility.longitude,
        address: facility.address
      }
    end
  end
end
