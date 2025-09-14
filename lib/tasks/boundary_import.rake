require 'nokogiri'
require 'rgeo/geo_json'

namespace :boundary_import do
  desc "Import ward boundaries from KML file as 2017 historical data"
  task :wards, [:kml_file] => :environment do |t, args|
    kml_file = args[:kml_file] || 'public/data/mumbai-wards-map.kml'

    unless File.exist?(kml_file)
      puts "❌ KML file not found: #{kml_file}"
      puts "Usage: rake boundary_import:wards[path/to/wards.kml]"
      exit 1
    end

    puts "🏢 Importing ward boundaries from #{kml_file}..."

    doc = Nokogiri::XML(File.open(kml_file))
    doc.remove_namespaces!

    placemarks = doc.xpath('//Placemark')
    imported_count = 0
    skipped_count = 0
    updated_count = 0

    placemarks.each do |placemark|
      begin
        # Extract ward information
        name_element = placemark.xpath('.//name').first
        next unless name_element

        ward_name = name_element.text.strip

        # Extract ward code from name (assuming format like "Ward A" or just "A")
        ward_code = ward_name.gsub(/^Ward\s+/i, '').strip
        ward_code = WardCodeMapper.normalize(ward_code)

        # Extract geometry
        coordinates_element = placemark.xpath('.//coordinates').first
        next unless coordinates_element

        coordinates_text = coordinates_element.text.strip
        next if coordinates_text.empty?

        # Parse coordinates and convert to GeoJSON
        geojson = convert_kml_coordinates_to_geojson(coordinates_text)
        next unless geojson

        # Find or create ward
        ward = Ward.find_by(ward_code: ward_code)
        unless ward
          puts "⚠️  Ward not found in database: #{ward_code} (#{ward_name})"
          skipped_count += 1
          next
        end

        # Check if boundary already exists for this ward
        existing_boundary = ward.boundaries.find_by(
          source_type: 'kml_import',
          year: 2017,
          is_canonical: true
        )

        if existing_boundary
          puts "⏭️  Boundary already exists for ward #{ward_code}, skipping..."
          skipped_count += 1
          next
        end

        # Create boundary record
        boundary = ward.boundaries.create!(
          geojson: geojson.to_json,
          source_type: 'kml_import',
          year: 2017,
          status: 'canonical',
          is_canonical: true,
          metadata: {
            imported_from: File.basename(kml_file),
            original_name: ward_name,
            import_date: Time.current.iso8601,
            coordinates_count: count_coordinates(coordinates_text)
          }
        )

        puts "✅ Imported boundary for Ward #{ward_code} (#{ward_name})"
        imported_count += 1

      rescue => e
        puts "❌ Error processing #{ward_name rescue 'unknown'}: #{e.message}"
        skipped_count += 1
      end
    end

    puts "\n📊 Ward Boundary Import Summary:"
    puts "   Imported: #{imported_count}"
    puts "   Skipped: #{skipped_count}"
    puts "   Total processed: #{imported_count + skipped_count}"
  end

  desc "Import prabhag boundaries from KML file as 2017 historical data"
  task :prabhags, [:kml_file] => :environment do |t, args|
    kml_file = args[:kml_file] || 'public/data/mumbai_prabhag_boundaries.kml'

    unless File.exist?(kml_file)
      puts "❌ KML file not found: #{kml_file}"
      puts "Usage: rake boundary_import:prabhags[path/to/prabhags.kml]"
      exit 1
    end

    puts "🏘️  Importing prabhag boundaries from #{kml_file}..."

    doc = Nokogiri::XML(File.open(kml_file))
    doc.remove_namespaces!

    placemarks = doc.xpath('//Placemark')
    imported_count = 0
    skipped_count = 0
    created_prabhags = 0

    placemarks.each do |placemark|
      begin
        # Extract extended data for prabhag information
        extended_data = extract_extended_data(placemark)

        # Extract prabhag number from extended data
        prabhag_number = extended_data['PRABHAG_NO']&.to_i
        next unless prabhag_number

        # Create a prabhag name
        prabhag_name = "Prabhag #{prabhag_number}"

        # Extract ward code from extended data
        ward_code_raw = extended_data['WARD'] || extended_data['Ward'] || extended_data['ward']

        next unless ward_code_raw
        ward_code = WardCodeMapper.normalize(ward_code_raw.strip)

        # Extract geometry
        coordinates_element = placemark.xpath('.//coordinates').first
        next unless coordinates_element

        coordinates_text = coordinates_element.text.strip
        next if coordinates_text.empty?

        # Parse coordinates and convert to GeoJSON
        geojson = convert_kml_coordinates_to_geojson(coordinates_text)
        next unless geojson

        # Find or create prabhag
        prabhag = Prabhag.find_by(number: prabhag_number, ward_code: ward_code)
        unless prabhag
          # Create new prabhag for historical 2017 data
          prabhag = Prabhag.create!(
            number: prabhag_number,
            name: prabhag_name,
            ward_code: ward_code,
            pdf_url: "https://portal.mcgm.gov.in/historical/2017/#{prabhag_number}.pdf",
            status: 'available'
          )
          puts "🆕 Created new prabhag: #{prabhag_number} (#{ward_code})"
          created_prabhags += 1
        end

        # Check if boundary already exists
        existing_boundary = prabhag.boundaries.find_by(
          source_type: 'kml_import',
          year: 2017
        )

        if existing_boundary
          puts "⏭️  Boundary already exists for prabhag #{prabhag_number} (#{ward_code}), skipping..."
          skipped_count += 1
          next
        end

        # Extract additional metadata
        councillor = extended_data['COUNCILLOR'] || extended_data['Councillor']
        population = extended_data['POPULATION'] || extended_data['Population']

        # Create boundary record
        boundary = prabhag.boundaries.create!(
          geojson: geojson.to_json,
          source_type: 'kml_import',
          year: 2017,
          status: 'approved', # Historical data is considered approved
          is_canonical: false, # Not canonical since it's historical
          metadata: {
            imported_from: File.basename(kml_file),
            original_name: prabhag_name,
            councillor: councillor,
            population: population,
            import_date: Time.current.iso8601,
            coordinates_count: count_coordinates(coordinates_text)
          }.compact
        )

        puts "✅ Imported boundary for Prabhag #{prabhag_number} (#{ward_code})"
        imported_count += 1

      rescue => e
        puts "❌ Error processing #{prabhag_name rescue 'unknown'}: #{e.message}"
        puts "   #{e.backtrace.first}" if ENV['VERBOSE']
        skipped_count += 1
      end
    end

    puts "\n📊 Prabhag Boundary Import Summary:"
    puts "   New prabhags created: #{created_prabhags}"
    puts "   Boundaries imported: #{imported_count}"
    puts "   Skipped: #{skipped_count}"
    puts "   Total processed: #{imported_count + skipped_count}"
  end

  desc "Import all boundaries (wards and prabhags) from default KML files"
  task :all => :environment do
    puts "🚀 Starting complete boundary import..."

    Rake::Task['boundary_import:wards'].invoke
    puts ""
    Rake::Task['boundary_import:prabhags'].invoke

    puts "\n🎉 Complete boundary import finished!"

    # Show summary stats
    ward_boundaries = Boundary.where(boundable_type: 'Ward', source_type: 'kml_import', year: 2017).count
    prabhag_boundaries = Boundary.where(boundable_type: 'Prabhag', source_type: 'kml_import', year: 2017).count

    puts "\n📈 Final Statistics:"
    puts "   Ward boundaries (2017): #{ward_boundaries}"
    puts "   Prabhag boundaries (2017): #{prabhag_boundaries}"
    puts "   Total boundaries imported: #{ward_boundaries + prabhag_boundaries}"
  end

  desc "Show import status and statistics"
  task :status => :environment do
    puts "📊 Boundary Import Status\n"

    total_wards = Ward.count
    ward_boundaries_2017 = Boundary.where(boundable_type: 'Ward', source_type: 'kml_import', year: 2017).count

    total_prabhags = Prabhag.count
    prabhag_boundaries_2017 = Boundary.where(boundable_type: 'Prabhag', source_type: 'kml_import', year: 2017).count

    puts "Wards:"
    puts "  Total wards in database: #{total_wards}"
    puts "  Wards with 2017 boundaries: #{ward_boundaries_2017}"
    puts "  Coverage: #{'%.1f' % (ward_boundaries_2017.to_f / total_wards * 100)}%" if total_wards > 0
    puts ""

    puts "Prabhags:"
    puts "  Total prabhags in database: #{total_prabhags}"
    puts "  Prabhags with 2017 boundaries: #{prabhag_boundaries_2017}"
    puts "  Coverage: #{'%.1f' % (prabhag_boundaries_2017.to_f / total_prabhags * 100)}%" if total_prabhags > 0
    puts ""

    puts "Boundary Status Breakdown:"
    Boundary.where(year: 2017).group(:status).count.each do |status, count|
      puts "  #{status}: #{count}"
    end
  end

  private

  def convert_kml_coordinates_to_geojson(coordinates_text)
    # KML coordinates format: "lon,lat,elevation lon,lat,elevation ..."
    # GeoJSON format: [[lon,lat], [lon,lat], ...]

    coordinate_pairs = coordinates_text.strip.split(/\s+/)
    coordinates = coordinate_pairs.map do |pair|
      parts = pair.split(',')
      next if parts.length < 2

      [parts[0].to_f, parts[1].to_f] # [longitude, latitude]
    end.compact

    return nil if coordinates.empty?

    # Ensure polygon is closed (first and last coordinates are the same)
    if coordinates.first != coordinates.last
      coordinates << coordinates.first
    end

    # Create GeoJSON Polygon
    {
      type: "Polygon",
      coordinates: [coordinates]
    }
  rescue => e
    puts "❌ Error converting coordinates: #{e.message}"
    nil
  end

  def extract_prabhag_number(name_text)
    # Try to extract number from various formats
    # "172", "Prabhag 172", "P-172", etc.
    match = name_text.match(/(\d+)/)
    match ? match[1].to_i : nil
  end

  def extract_extended_data(placemark)
    data = {}

    # Look for ExtendedData elements (format: <Data name="..."><value>...</value></Data>)
    placemark.xpath('.//ExtendedData//Data').each do |data_element|
      name = data_element.attribute('name')&.value
      value_element = data_element.xpath('.//value').first
      value = value_element&.text&.strip

      if name && value && !value.empty?
        data[name] = value
      end
    end

    # Also look for SimpleData elements (format: <SimpleData name="...">value</SimpleData>)
    placemark.xpath('.//ExtendedData//SimpleData').each do |data_element|
      name = data_element.attribute('name')&.value
      value = data_element.text&.strip

      if name && value && !value.empty?
        data[name] = value
      end
    end

    data
  end

  def count_coordinates(coordinates_text)
    coordinates_text.strip.split(/\s+/).length
  end
end