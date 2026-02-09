require 'rexml/document'

class ImportKmlPrabhagBoundaries < ActiveRecord::Migration[8.0]
  # KML WARD codes → DB ward_codes
  WARD_CODE_MAP = {
    'A' => 'A',
    'B' => 'B',
    'C' => 'C',
    'D' => 'D',
    'E' => 'E',
    'FN' => 'F NORTH',
    'FS' => 'F SOUTH',
    'GN' => 'G NORTH',
    'GS' => 'G SOUTH',
  }.freeze

  def up
    kml_path = Rails.root.join('db', 'data', 'prabhags.kml')
    unless File.exist?(kml_path)
      say "KML file not found at #{kml_path}, skipping import"
      return
    end

    doc = REXML::Document.new(File.read(kml_path))
    imported = 0
    skipped = 0

    doc.elements.each('//Placemark') do |placemark|
      kml_ward = placemark.elements[".//SimpleData[@name='WARD']"]&.text&.strip
      kml_number = placemark.elements[".//SimpleData[@name='PRABHAG_NO']"]&.text&.strip&.to_i

      unless kml_ward && kml_number && kml_number > 0
        say "  Missing WARD or PRABHAG_NO, skipping placemark"
        skipped += 1
        next
      end

      ward_code = WARD_CODE_MAP[kml_ward]
      unless ward_code
        say "  Unknown KML ward code '#{kml_ward}', skipping prabhag #{kml_number}"
        skipped += 1
        next
      end

      prabhag = Prabhag.find_by(number: kml_number, ward_code: ward_code)
      unless prabhag
        say "  No prabhag found for number=#{kml_number} ward_code=#{ward_code}, skipping"
        skipped += 1
        next
      end

      # Demote any existing canonical boundary
      prabhag.boundaries.where(is_canonical: true).update_all(is_canonical: false)

      # Extract coordinates from MultiGeometry > Polygon
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
          prabhag_number: kml_number,
          ward_code: ward_code
        }
      }.to_json

      Boundary.create!(
        boundable: prabhag,
        geojson: geojson,
        source_type: 'kml_import',
        status: 'approved',
        is_canonical: true
      )

      imported += 1
      say "  Imported boundary for Prabhag #{kml_number} (#{ward_code})"
    end

    say "Prabhag import complete: #{imported} imported, #{skipped} skipped"
  end

  def down
    Boundary.where(source_type: 'kml_import', boundable_type: 'Prabhag', is_canonical: true).destroy_all
  end
end
