namespace :prabhag_data do
  desc "Export mapped prabhags with GeoJSON to JSON file"
  task export: :environment do
    mapped_prabhags = Prabhag.where.not(boundary_geojson: nil)
                            .where.not(boundary_geojson: '')
                            .includes(:assigned_to)

    if mapped_prabhags.empty?
      puts "No mapped prabhags found in database."
      exit
    end

    export_data = {
      exported_at: Time.current.iso8601,
      count: mapped_prabhags.count,
      prabhags: mapped_prabhags.map do |prabhag|
        {
          number: prabhag.number,
          name: prabhag.name,
          ward_code: prabhag.ward_code,
          pdf_url: prabhag.pdf_url,
          boundary_geojson: prabhag.boundary_geojson,
          status: prabhag.status,
          assigned_to_id: prabhag.assigned_to&.id,
          created_at: prabhag.created_at.iso8601,
          updated_at: prabhag.updated_at.iso8601
        }
      end
    }

    filename = "prabhag_export_#{Date.current.strftime('%Y%m%d')}.json"
    File.write(filename, JSON.pretty_generate(export_data))

    puts "Exported #{mapped_prabhags.count} mapped prabhags to #{filename}"
    puts "File size: #{File.size(filename) / 1024}KB"

    # Print summary by status
    status_summary = mapped_prabhags.group(:status).count
    puts "\nStatus breakdown:"
    status_summary.each { |status, count| puts "  #{status}: #{count}" }
  end

  desc "Import prabhag data from JSON file (use RAILS_ENV=production for production import)"
  task :import, [:filename] => :environment do |t, args|
    filename = args[:filename]

    unless filename
      puts "Usage: rake prabhag_data:import[filename.json]"
      puts "Example: RAILS_ENV=production rake prabhag_data:import[prabhag_export_20250914.json]"
      exit
    end

    unless File.exist?(filename)
      puts "File not found: #{filename}"
      exit
    end

    puts "Current environment: #{Rails.env}"
    if Rails.env.production?
      print "Are you sure you want to import to PRODUCTION? (yes/no): "
      confirmation = STDIN.gets.chomp
      unless confirmation.downcase == 'yes'
        puts "Import cancelled."
        exit
      end
    end

    begin
      data = JSON.parse(File.read(filename))
      imported_count = 0
      updated_count = 0
      skipped_count = 0

      data['prabhags'].each do |prabhag_data|
        existing_prabhag = Prabhag.find_by(number: prabhag_data['number'], ward_code: prabhag_data['ward_code'])

        if existing_prabhag
          # Only update if the imported data has a boundary and current doesn't, or if forced
          if existing_prabhag.boundary_geojson.blank? && prabhag_data['boundary_geojson'].present?
            existing_prabhag.update!(
              boundary_geojson: prabhag_data['boundary_geojson'],
              status: prabhag_data['status']
            )
            updated_count += 1
            puts "Updated Prabhag #{prabhag_data['number']} (#{prabhag_data['ward_code']})"
          else
            skipped_count += 1
            puts "Skipped Prabhag #{prabhag_data['number']} (#{prabhag_data['ward_code']}) - already has boundary data"
          end
        else
          # Create new prabhag (without assigned_to to avoid user ID conflicts)
          Prabhag.create!(
            number: prabhag_data['number'],
            name: prabhag_data['name'],
            ward_code: prabhag_data['ward_code'],
            pdf_url: prabhag_data['pdf_url'],
            boundary_geojson: prabhag_data['boundary_geojson'],
            status: prabhag_data['status']
          )
          imported_count += 1
          puts "Created Prabhag #{prabhag_data['number']} (#{prabhag_data['ward_code']})"
        end
      end

      puts "\nImport completed:"
      puts "  Created: #{imported_count}"
      puts "  Updated: #{updated_count}"
      puts "  Skipped: #{skipped_count}"
      puts "  Total processed: #{imported_count + updated_count + skipped_count}"

    rescue JSON::ParserError => e
      puts "Error parsing JSON file: #{e.message}"
    rescue => e
      puts "Error during import: #{e.message}"
      puts e.backtrace.first(5)
    end
  end

  desc "Show summary of mapped prabhags in current environment"
  task summary: :environment do
    total_prabhags = Prabhag.count
    mapped_prabhags = Prabhag.where.not(boundary_geojson: nil).where.not(boundary_geojson: '').count

    puts "Environment: #{Rails.env}"
    puts "Total prabhags: #{total_prabhags}"
    puts "Mapped prabhags: #{mapped_prabhags}"
    puts "Unmapped prabhags: #{total_prabhags - mapped_prabhags}"
    puts "Mapping progress: #{'%.1f' % (mapped_prabhags.to_f / total_prabhags * 100)}%"

    if mapped_prabhags > 0
      puts "\nStatus breakdown:"
      Prabhag.where.not(boundary_geojson: nil).where.not(boundary_geojson: '').group(:status).count.each do |status, count|
        puts "  #{status}: #{count}"
      end
    end
  end
end