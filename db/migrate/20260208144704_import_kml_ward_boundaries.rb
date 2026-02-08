require 'rexml/document'

class ImportKmlWardBoundaries < ActiveRecord::Migration[8.0]
  def up
    kml_path = Rails.root.join('db', 'data', 'wards.kml')
    unless File.exist?(kml_path)
      say "KML file not found at #{kml_path}, skipping import"
      return
    end

    doc = REXML::Document.new(File.read(kml_path))
    imported = 0
    skipped = 0

    doc.elements.each('//Placemark') do |placemark|
      # Extract ward name from SimpleData
      name_el = placemark.elements[".//SimpleData[@name='NAME']"]
      next unless name_el

      ward_name = name_el.text.strip

      # Find ward by short_name
      ward = Ward.find_by(short_name: ward_name)
      unless ward
        say "  No ward found for short_name '#{ward_name}', skipping"
        skipped += 1
        next
      end

      # Skip if ward already has a canonical boundary
      if ward.boundaries.where(is_canonical: true).exists?
        say "  Ward #{ward.ward_code} already has canonical boundary, skipping"
        skipped += 1
        next
      end

      # Extract coordinates from Polygon
      coords_el = placemark.elements['.//coordinates']
      next unless coords_el

      coords_text = coords_el.text.strip
      coordinates = coords_text.split(/\s+/).map do |coord|
        parts = coord.split(',')
        [parts[0].to_f, parts[1].to_f]
      end

      geojson = {
        type: 'Feature',
        geometry: {
          type: 'Polygon',
          coordinates: [coordinates]
        },
        properties: {
          name: ward_name
        }
      }.to_json

      Boundary.create!(
        boundable: ward,
        geojson: geojson,
        source_type: 'kml_import',
        status: 'approved',
        is_canonical: true
      )

      imported += 1
      say "  Imported boundary for Ward #{ward.ward_code} (#{ward_name})"
    end

    say "Import complete: #{imported} imported, #{skipped} skipped"

    # P/S has bad KML data (only Madh Island, missing main ward area)
    # Override with full BMC ArcGIS boundary
    import_ps_from_bmc
  end

  def down
    Boundary.where(source_type: ['kml_import', 'official_import'], boundable_type: 'Ward', is_canonical: true).destroy_all
  end

  private

  def import_ps_from_bmc
    ps_path = Rails.root.join('db', 'data', 'ps_ward_bmc.geojson')
    unless File.exist?(ps_path)
      say "  P/S BMC GeoJSON not found, skipping"
      return
    end

    ward = Ward.find_by(short_name: 'P/S')
    return unless ward

    data = JSON.parse(File.read(ps_path))
    feature = data['features'].first
    geojson = {
      type: 'Feature',
      geometry: feature['geometry'],
      properties: { name: 'P/S', source: 'bmc_arcgis' }
    }.to_json

    # Replace existing canonical boundary
    existing = ward.boundaries.find_by(is_canonical: true)
    if existing
      existing.update!(geojson: geojson, source_type: 'official_import')
      say "  Updated P/S boundary from BMC ArcGIS (#{geojson.length} bytes)"
    else
      Boundary.create!(
        boundable: ward,
        geojson: geojson,
        source_type: 'official_import',
        status: 'approved',
        is_canonical: true
      )
      say "  Created P/S boundary from BMC ArcGIS"
    end
  end
end
