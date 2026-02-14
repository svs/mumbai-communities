require "net/http"
require "json"
require "uri"

class BmcArcGisService
  # Known ArcGIS FeatureServer URLs for MCGM facility layers.
  # These are extracted from the web app viewer configs embedded in BMC portal iframes.
  # Run `rake bmc:extract_arcgis_urls` to discover/update these.
  LAYER_URLS = {
    "hospital" => nil,
    "school" => nil,
    "toilet" => nil,
    "garden" => nil,
    "parking" => nil,
    "ward_office" => nil
  }.freeze

  # BMC portal pages that embed ArcGIS web app viewers
  PORTAL_MAP_PAGES = {
    "hospital" => "BMC-on-Map-Facilities-Health",
    "school" => "BMC-on-Map-Facilities-Schools",
    "toilet" => "BMC-on-Map-Facilities-Toilets",
    "garden" => "BMC-on-Map-Amenities-Gardens-OpenSpaces",
    "parking" => "BMC-on-Map-Facilities-ParkingLots",
    "ward_office" => "BMC-on-Map-Wards-Offices"
  }.freeze

  TIMEOUT_SECONDS = 60
  BATCH_SIZE = 2000

  class << self
    def import_all(urls: nil)
      urls_to_use = urls || load_urls
      results = {}

      urls_to_use.each do |facility_type, url|
        next if url.blank?

        Rails.logger.info "BmcArcGisService: Importing #{facility_type} from #{url}"
        count = import_layer(facility_type, url)
        results[facility_type] = count
        Rails.logger.info "BmcArcGisService: Imported #{count} #{facility_type} facilities"
      end

      results
    end

    def import_layer(facility_type, feature_server_url)
      features = query_all_features(feature_server_url)
      return 0 if features.empty?

      imported = 0
      features.each do |feature|
        attrs = feature["attributes"] || {}
        geometry = feature["geometry"] || {}

        lat, lng = convert_geometry(geometry)
        next unless lat && lng

        external_id = attrs["OBJECTID"]&.to_s || attrs["FID"]&.to_s
        next if external_id.blank?

        name = extract_name(attrs)
        ward_code = attrs["WARD"] || attrs["Ward"] || attrs["ward_name"] || assign_ward(lat, lng)

        facility = Facility.find_or_initialize_by(source: "bmc_arcgis", external_id: external_id)
        facility.assign_attributes(
          name: name,
          facility_type: normalize_facility_type(facility_type),
          ward_code: normalize_ward_code(ward_code),
          latitude: lat,
          longitude: lng,
          address: extract_address(attrs),
          raw_data: attrs,
          content_hash: Digest::SHA256.hexdigest(attrs.to_json),
          last_seen_at: Time.current
        )
        facility.save!
        imported += 1
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn "BmcArcGisService: Skipping feature #{external_id}: #{e.message}"
      end

      imported
    end

    def query_all_features(feature_server_url)
      all_features = []
      offset = 0

      loop do
        batch = query_features(feature_server_url, offset: offset)
        break if batch.empty?

        all_features.concat(batch)
        break if batch.size < BATCH_SIZE

        offset += BATCH_SIZE
      end

      all_features
    end

    private

    def load_urls
      config_path = Rails.root.join("config", "arcgis_urls.json")
      if File.exist?(config_path)
        JSON.parse(File.read(config_path))
      else
        LAYER_URLS
      end
    end

    def query_features(feature_server_url, offset: 0)
      base_url = feature_server_url.chomp("/")
      base_url += "/0" unless base_url.match?(/\/\d+$/)

      uri = URI("#{base_url}/query")
      params = {
        "where" => "1=1",
        "outFields" => "*",
        "f" => "json",
        "resultRecordCount" => BATCH_SIZE.to_s,
        "resultOffset" => offset.to_s,
        "outSR" => "4326"
      }
      uri.query = URI.encode_www_form(params)

      response = make_request(uri)
      return [] unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      data["features"] || []
    rescue StandardError => e
      Rails.logger.error "BmcArcGisService: Query failed for #{feature_server_url}: #{e.message}"
      []
    end

    def convert_geometry(geometry)
      x = geometry["x"]
      y = geometry["y"]
      return [nil, nil] unless x && y

      # outSR=4326 means coordinates are already in lat/lng
      [y.to_f, x.to_f]
    end

    def extract_name(attrs)
      attrs["NAME"] || attrs["Name"] || attrs["name"] ||
        attrs["FACILITY_NAME"] || attrs["facility_name"] ||
        attrs["HOSPITAL_NAME"] || attrs["SCHOOL_NAME"] ||
        attrs["GARDEN_NAME"] || attrs["TOILET_NAME"]
    end

    def extract_address(attrs)
      attrs["ADDRESS"] || attrs["Address"] || attrs["address"] ||
        attrs["LOCATION"] || attrs["Location"] || attrs["location"]
    end

    def normalize_facility_type(type)
      case type.to_s.downcase
      when "garden", "open_space" then "garden"
      when "health", "hospital" then "hospital"
      when "school", "schools" then "school"
      when "toilet", "toilets" then "toilet"
      when "parking", "parkinglots" then "parking"
      when "ward_office", "wards_offices" then "ward_office"
      else type.to_s.downcase
      end
    end

    def normalize_ward_code(ward_code)
      return nil if ward_code.blank?
      WardCodeMapper.normalize(ward_code.to_s.strip)
    rescue
      ward_code.to_s.strip
    end

    def assign_ward(lat, lng)
      result = GeocodingService.find_prabhag_from_coordinates(lat, lng)
      result&.first
    rescue
      nil
    end

    def make_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = TIMEOUT_SECONDS
      http.read_timeout = TIMEOUT_SECONDS
      http.request(Net::HTTP::Get.new(uri))
    rescue StandardError => e
      Rails.logger.error "BmcArcGisService: HTTP request failed: #{e.message}"
      nil
    end
  end
end
