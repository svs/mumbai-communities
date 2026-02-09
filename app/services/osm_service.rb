require 'net/http'
require 'json'
require 'uri'

class OsmService
  OVERPASS_URL = "https://overpass-api.de/api/interpreter".freeze
  DEFAULT_CATEGORIES = %w[hospital school college police fire_station library place_of_worship].freeze
  TIMEOUT_SECONDS = 30

  # Map category names to Overpass tag filters
  CATEGORY_TAGS = {
    "hospital" => '"amenity"="hospital"',
    "school" => '"amenity"="school"',
    "college" => '"amenity"="college"',
    "police" => '"amenity"="police"',
    "fire_station" => '"amenity"="fire_station"',
    "library" => '"amenity"="library"',
    "place_of_worship" => '"amenity"="place_of_worship"',
    "pharmacy" => '"amenity"="pharmacy"',
    "bank" => '"amenity"="bank"',
    "post_office" => '"amenity"="post_office"',
    "park" => '"leisure"="park"',
    "playground" => '"leisure"="playground"',
    "bus_station" => '"amenity"="bus_station"',
    "railway_station" => '"railway"="station"'
  }.freeze

  class << self
    def pois_within(geojson, categories: nil)
      categories ||= DEFAULT_CATEGORIES
      coords = extract_polygon_coords(geojson)
      return [] if coords.blank?

      poly_string = to_overpass_poly(coords)
      query = build_query(poly_string, categories)

      response = execute_query(query)
      return [] if response.nil?

      parse_response(response)
    rescue StandardError => e
      Rails.logger.error "OsmService error: #{e.message}"
      []
    end

    private

    def extract_polygon_coords(geojson)
      parsed = geojson.is_a?(String) ? JSON.parse(geojson) : geojson

      coordinates = case parsed['type']
      when 'Feature'
        parsed.dig('geometry', 'coordinates')
      when 'Polygon'
        parsed['coordinates']
      when 'MultiPolygon'
        # Use the first polygon's outer ring
        parsed['coordinates']&.first
      when 'FeatureCollection'
        feature = parsed['features']&.first
        feature&.dig('geometry', 'coordinates')
      end

      # Return outer ring (first ring of polygon)
      coordinates&.first
    rescue JSON::ParserError => e
      Rails.logger.error "OsmService: Failed to parse GeoJSON: #{e.message}"
      nil
    end

    def to_overpass_poly(coords)
      # Overpass poly format: space-separated "lat lon lat lon ..."
      # GeoJSON is [lng, lat], Overpass wants lat lon
      coords.map { |coord| "#{coord[1]} #{coord[0]}" }.join(" ")
    end

    def build_query(poly_string, categories)
      filters = categories.filter_map { |cat| CATEGORY_TAGS[cat] }
      return nil if filters.empty?

      union_parts = filters.flat_map do |tag|
        [
          "node[#{tag}](poly:\"#{poly_string}\");",
          "way[#{tag}](poly:\"#{poly_string}\");"
        ]
      end

      <<~OVERPASS
        [out:json][timeout:#{TIMEOUT_SECONDS}];
        (
          #{union_parts.join("\n  ")}
        );
        out center;
      OVERPASS
    end

    def execute_query(query)
      return nil if query.nil?

      uri = URI(OVERPASS_URL)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data('data' => query)

      response = make_request(uri, request)

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error "OsmService: Overpass API returned #{response.code}: #{response.body.truncate(200)}"
        return nil
      end

      JSON.parse(response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error "OsmService: Timeout querying Overpass API: #{e.message}"
      nil
    rescue JSON::ParserError => e
      Rails.logger.error "OsmService: Failed to parse Overpass response: #{e.message}"
      nil
    end

    def parse_response(data)
      elements = data['elements'] || []

      elements.filter_map do |el|
        lat, lng = element_coordinates(el)
        next unless lat && lng

        {
          name: el.dig('tags', 'name'),
          type: el.dig('tags', 'amenity') || el.dig('tags', 'leisure') || el.dig('tags', 'railway'),
          lat: lat,
          lng: lng,
          tags: el['tags'] || {}
        }
      end
    end

    def element_coordinates(el)
      case el['type']
      when 'node'
        [el['lat'], el['lon']]
      when 'way', 'relation'
        # Overpass `out center` adds center coordinates for ways
        [el.dig('center', 'lat'), el.dig('center', 'lon')]
      end
    end

    def make_request(uri, request, verify_ssl: true)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = verify_ssl ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      http.open_timeout = TIMEOUT_SECONDS
      http.read_timeout = TIMEOUT_SECONDS
      http.request(request)
    rescue OpenSSL::SSL::SSLError => e
      raise unless verify_ssl
      Rails.logger.warn "OsmService: SSL verification failed (#{e.message}), retrying without CRL check"
      make_request(uri, request, verify_ssl: false)
    end
  end
end
