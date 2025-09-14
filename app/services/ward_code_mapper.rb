class WardCodeMapper
  # Maps various ward code formats to normalized versions
  WARD_CODE_MAPPINGS = {
    # KML format -> Database format
    'F/N'       => 'F NORTH',
    'F/S'       => 'F SOUTH',
    'G/N'       => 'G NORTH',
    'G/S'       => 'G SOUTH',
    'H/E'       => 'H EAST',
    'H/W'       => 'H WEST',
    'K/E'       => 'K EAST',
    'K/W'       => 'K WEST',
    'L'         => 'L',
    'M/E'       => 'M EAST',
    'M/W'       => 'M WEST',
    'N'         => 'N',
    'P/N'       => 'P NORTH',
    'P/S'       => 'P SOUTH',
    'R/C'       => 'R/Central',
    'R/N'       => 'R NORTH',
    'R/S'       => 'R SOUTH',
    'S'         => 'S',
    'T'         => 'T',

    # Handle variations that might exist
    'F NORTH'   => 'F NORTH',
    'F SOUTH'   => 'F SOUTH',
    'G NORTH'   => 'G NORTH',
    'G SOUTH'   => 'G SOUTH',
    'R/CENTRAL' => 'R/Central',
    'R/Central' => 'R/Central',
    'R CENTRAL' => 'R/Central'
  }.freeze

  # Reverse mapping for converting from database format back to KML format
  # Only includes the primary KML format for each database format
  REVERSE_MAPPINGS = {
    'F NORTH'   => 'F/N',
    'F SOUTH'   => 'F/S',
    'G NORTH'   => 'G/N',
    'G SOUTH'   => 'G/S',
    'H EAST'    => 'H/E',
    'H WEST'    => 'H/W',
    'K EAST'    => 'K/E',
    'K WEST'    => 'K/W',
    'L'         => 'L',
    'M EAST'    => 'M/E',
    'M WEST'    => 'M/W',
    'N'         => 'N',
    'P NORTH'   => 'P/N',
    'P SOUTH'   => 'P/S',
    'R/Central' => 'R/C',
    'R NORTH'   => 'R/N',
    'R SOUTH'   => 'R/S',
    'S'         => 'S',
    'T'         => 'T'
  }.freeze

  class << self
    # Convert ward code from various formats to database format
    def normalize(ward_code)
      return nil if ward_code.blank?

      normalized = ward_code.to_s.strip.upcase

      # Try direct mapping first
      mapped = WARD_CODE_MAPPINGS[normalized]
      return mapped if mapped

      # Try case-insensitive mapping
      WARD_CODE_MAPPINGS.each do |key, value|
        return value if key.upcase == normalized
      end

      # If no mapping found, return original (might be already normalized)
      ward_code
    end

    # Convert database format back to KML format
    def to_kml_format(ward_code)
      return nil if ward_code.blank?

      # Try reverse mapping
      mapped = REVERSE_MAPPINGS[ward_code]
      return mapped if mapped

      # If no mapping found, return original
      ward_code
    end

    # Check if a ward code exists in either format
    def valid_ward_code?(ward_code)
      return false if ward_code.blank?

      normalized = normalize(ward_code)
      Ward.exists?(ward_code: normalized)
    end

    # Find ward by any valid ward code format
    def find_ward(ward_code)
      return nil if ward_code.blank?

      normalized = normalize(ward_code)
      Ward.find_by(ward_code: normalized)
    end

    # Get all possible formats for a given ward code
    def all_formats(ward_code)
      return [] if ward_code.blank?

      normalized = normalize(ward_code)
      kml_format = to_kml_format(normalized)

      [ward_code, normalized, kml_format].compact.uniq
    end

    # Batch normalize multiple ward codes
    def normalize_batch(ward_codes)
      return [] if ward_codes.blank?

      ward_codes.map { |code| normalize(code) }.compact
    end
  end
end