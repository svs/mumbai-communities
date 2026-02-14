namespace :bmc do
  desc "Extract ArcGIS FeatureServer URLs from BMC portal map pages using Playwright"
  task extract_arcgis_urls: :environment do
    puts "Extracting ArcGIS FeatureServer URLs from BMC portal..."
    puts
    puts "This task uses Playwright to load BMC portal map pages and extract"
    puts "the ArcGIS FeatureServer URLs from embedded iframe configs."
    puts

    urls = {}

    BmcArcGisService::PORTAL_MAP_PAGES.each do |facility_type, page_name|
      puts "Checking #{facility_type} (#{page_name})..."
      # The actual URL extraction requires Playwright browser automation.
      # For now, log the page names that need to be checked manually.
      puts "  Portal page: https://portal.mcgm.gov.in/irj/portal/anonymous/#{page_name}"
      puts "  Look for iframe src pointing to mcgm.maps.arcgis.com/apps/webappviewer/..."
      puts "  Then find the config JSON with FeatureServer URLs."
      puts
    end

    config_path = Rails.root.join("config", "arcgis_urls.json")
    if File.exist?(config_path)
      existing = JSON.parse(File.read(config_path))
      puts "Current config/arcgis_urls.json:"
      existing.each { |k, v| puts "  #{k}: #{v || '(not set)'}" }
    else
      puts "No config/arcgis_urls.json found."
      puts "Create one with the extracted URLs:"
      puts '  {"hospital": "https://...", "school": "https://...", ...}'

      # Create a template
      template = BmcArcGisService::PORTAL_MAP_PAGES.keys.each_with_object({}) { |k, h| h[k] = nil }
      File.write(config_path, JSON.pretty_generate(template))
      puts
      puts "Template created at #{config_path}"
    end
  end

  desc "Import facilities from ArcGIS FeatureServer APIs"
  task import_arcgis_facilities: :environment do
    config_path = Rails.root.join("config", "arcgis_urls.json")
    unless File.exist?(config_path)
      puts "No config/arcgis_urls.json found. Run `rake bmc:extract_arcgis_urls` first."
      exit 1
    end

    urls = JSON.parse(File.read(config_path))
    active_urls = urls.select { |_, v| v.present? }

    if active_urls.empty?
      puts "No ArcGIS URLs configured. Add FeatureServer URLs to config/arcgis_urls.json"
      exit 1
    end

    puts "Importing ArcGIS facilities..."
    results = BmcArcGisService.import_all(urls: active_urls)

    puts
    puts "Results:"
    results.each { |type, count| puts "  #{type}: #{count} facilities imported" }
    puts "  Total: #{results.values.sum}"
    puts
    puts "Total ArcGIS facilities in database: #{Facility.from_arcgis.count}"
  end

  desc "Import OSM POIs into facilities table"
  task import_osm_facilities: :environment do
    puts "Importing OSM facilities for all wards with boundaries..."

    total = OsmFacilityImporter.import_all
    puts
    puts "Imported #{total} OSM facilities"
    puts "Total OSM facilities in database: #{Facility.from_osm.count}"
  end

  desc "Compare BMC vs OSM facilities for a ward (or all wards)"
  task :compare, [:ward_code] => :environment do |_t, args|
    if args[:ward_code]
      result = FacilityComparisonService.compare(ward_code: args[:ward_code])
      print_comparison(args[:ward_code], result)
    else
      results = FacilityComparisonService.compare_all
      results.each { |ward_code, result| print_comparison(ward_code, result) }
    end
  end

  desc "Scrape all BMC portal ward pages"
  task scrape_portal: :environment do
    puts "Scraping BMC portal pages..."

    results = BmcScraper.scrape_all
    puts
    puts "Scraped: #{results[:scraped]} pages"
    puts "Changed: #{results[:changed]} pages"
    puts "Errors: #{results[:errors]} pages"
  end

  desc "Full monitoring run: scrape, detect changes, write report"
  task monitor: :environment do
    puts "Running BMC change monitor..."
    puts

    # Scrape portal pages
    puts "Step 1: Scraping portal pages..."
    scrape_results = BmcScraper.scrape_all
    puts "  Scraped #{scrape_results[:scraped]} pages (#{scrape_results[:changed]} changed)"

    # Re-import ArcGIS if configured
    config_path = Rails.root.join("config", "arcgis_urls.json")
    if File.exist?(config_path)
      urls = JSON.parse(File.read(config_path)).select { |_, v| v.present? }
      if urls.any?
        puts "Step 2: Re-importing ArcGIS facilities..."
        arcgis_results = BmcArcGisService.import_all(urls: urls)
        puts "  Imported #{arcgis_results.values.sum} facilities"
      end
    end

    # Detect and report changes
    puts "Step 3: Detecting changes..."
    changes = BmcChangeMonitor.run
    puts "  Found #{changes.size} changes"

    output_path = BmcChangeMonitor::OUTPUT_PATH
    puts
    puts "Report written to: #{output_path}"
    puts
    if File.exist?(output_path)
      puts File.read(output_path)
    end
  end

  desc "One-shot hydrate: import everything (ArcGIS + OSM + portal)"
  task hydrate: :environment do
    puts "=== BMC Data Hydration ==="
    puts

    # ArcGIS facilities
    config_path = Rails.root.join("config", "arcgis_urls.json")
    if File.exist?(config_path)
      urls = JSON.parse(File.read(config_path)).select { |_, v| v.present? }
      if urls.any?
        puts "1. Importing ArcGIS facilities..."
        results = BmcArcGisService.import_all(urls: urls)
        results.each { |type, count| puts "   #{type}: #{count}" }
      else
        puts "1. Skipping ArcGIS (no URLs configured)"
      end
    else
      puts "1. Skipping ArcGIS (run `rake bmc:extract_arcgis_urls` first)"
    end
    puts

    # OSM facilities
    puts "2. Importing OSM facilities..."
    osm_count = OsmFacilityImporter.import_all
    puts "   Imported #{osm_count} OSM facilities"
    puts

    # Portal scraping
    puts "3. Scraping BMC portal pages..."
    scrape_results = BmcScraper.scrape_all
    puts "   Scraped #{scrape_results[:scraped]} pages"
    puts

    # Summary
    puts "=== Summary ==="
    puts "ArcGIS facilities: #{Facility.from_arcgis.count}"
    puts "OSM facilities: #{Facility.from_osm.count}"
    puts "Total facilities: #{Facility.count}"
    puts "Ward snapshots: #{WardDataSnapshot.count}"
    puts
    puts "Facilities by type:"
    Facility.group(:facility_type).count.sort_by { |_, v| -v }.each do |type, count|
      puts "  #{type}: #{count}"
    end
  end
end

def print_comparison(ward_code, result)
  puts "=== Ward #{ward_code} ==="
  puts "  BMC facilities: #{result[:bmc_count]}"
  puts "  OSM facilities: #{result[:osm_count]}"
  puts "  Matched: #{result[:matched_count]}"
  puts "  BMC only: #{result[:bmc_only].size}"
  puts "  OSM only: #{result[:osm_only].size}"

  if result[:bmc_only].any?
    puts "  BMC-only facilities:"
    result[:bmc_only].first(5).each do |f|
      puts "    - #{f[:name] || '(unnamed)'} (#{f[:facility_type]})"
    end
    puts "    ... and #{result[:bmc_only].size - 5} more" if result[:bmc_only].size > 5
  end

  if result[:osm_only].any?
    puts "  OSM-only facilities:"
    result[:osm_only].first(5).each do |f|
      puts "    - #{f[:name] || '(unnamed)'} (#{f[:facility_type]})"
    end
    puts "    ... and #{result[:osm_only].size - 5} more" if result[:osm_only].size > 5
  end
  puts
end
