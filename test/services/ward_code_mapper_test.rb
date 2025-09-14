require 'test_helper'

class WardCodeMapperTest < ActiveSupport::TestCase
  test "normalize should convert KML format to database format" do
    assert_equal 'F NORTH', WardCodeMapper.normalize('F/N')
    assert_equal 'F SOUTH', WardCodeMapper.normalize('F/S')
    assert_equal 'G NORTH', WardCodeMapper.normalize('G/N')
    assert_equal 'R/Central', WardCodeMapper.normalize('R/C')
  end

  test "normalize should handle already normalized codes" do
    assert_equal 'F NORTH', WardCodeMapper.normalize('F NORTH')
    assert_equal 'L', WardCodeMapper.normalize('L')
    assert_equal 'R/Central', WardCodeMapper.normalize('R/Central')
  end

  test "normalize should handle case variations" do
    assert_equal 'F NORTH', WardCodeMapper.normalize('f/n')
    assert_equal 'R/Central', WardCodeMapper.normalize('r/central')
    assert_equal 'R/Central', WardCodeMapper.normalize('R CENTRAL')
  end

  test "normalize should return nil for blank input" do
    assert_nil WardCodeMapper.normalize(nil)
    assert_nil WardCodeMapper.normalize('')
    assert_nil WardCodeMapper.normalize('  ')
  end

  test "normalize should return original for unmapped codes" do
    assert_equal 'UNKNOWN', WardCodeMapper.normalize('UNKNOWN')
    assert_equal 'X', WardCodeMapper.normalize('X')
  end

  test "to_kml_format should convert database format to KML format" do
    assert_equal 'F/N', WardCodeMapper.to_kml_format('F NORTH')
    assert_equal 'F/S', WardCodeMapper.to_kml_format('F SOUTH')
    assert_equal 'R/C', WardCodeMapper.to_kml_format('R/Central')
  end

  test "to_kml_format should return nil for blank input" do
    assert_nil WardCodeMapper.to_kml_format(nil)
    assert_nil WardCodeMapper.to_kml_format('')
  end

  test "to_kml_format should return original for unmapped codes" do
    assert_equal 'UNKNOWN', WardCodeMapper.to_kml_format('UNKNOWN')
  end

  test "valid_ward_code? should check if ward exists" do
    # This test depends on ward fixtures
    ward = wards(:ward_one) # ward_code: 'A'

    # Mock the Ward.exists? call since we don't have F NORTH in fixtures
    Ward.expects(:exists?).with(ward_code: 'F NORTH').returns(true)
    assert WardCodeMapper.valid_ward_code?('F/N')

    Ward.expects(:exists?).with(ward_code: 'UNKNOWN').returns(false)
    refute WardCodeMapper.valid_ward_code?('UNKNOWN')

    refute WardCodeMapper.valid_ward_code?(nil)
  end

  test "find_ward should find ward by any format" do
    # Mock Ward.find_by since we don't have all ward codes in fixtures
    mock_ward = mock('ward')
    Ward.expects(:find_by).with(ward_code: 'F NORTH').returns(mock_ward)

    result = WardCodeMapper.find_ward('F/N')
    assert_equal mock_ward, result

    Ward.expects(:find_by).with(ward_code: 'UNKNOWN').returns(nil)
    assert_nil WardCodeMapper.find_ward('UNKNOWN')
  end

  test "all_formats should return all possible formats" do
    formats = WardCodeMapper.all_formats('F/N')

    assert_includes formats, 'F/N'      # original/KML format
    assert_includes formats, 'F NORTH'  # normalized
    # Note: Since 'F/N' is already in KML format, we get 2 unique formats
    assert_equal 2, formats.length
  end

  test "all_formats should handle unmapped codes" do
    formats = WardCodeMapper.all_formats('UNKNOWN')

    assert_includes formats, 'UNKNOWN'
    assert_equal 1, formats.length
  end

  test "normalize_batch should process multiple ward codes" do
    input = ['F/N', 'G/S', 'L', nil, '']
    expected = ['F NORTH', 'G SOUTH', 'L']

    assert_equal expected, WardCodeMapper.normalize_batch(input)
  end

  test "normalize_batch should return empty array for blank input" do
    assert_equal [], WardCodeMapper.normalize_batch(nil)
    assert_equal [], WardCodeMapper.normalize_batch([])
  end

  test "mappings should be comprehensive for Mumbai wards" do
    # Test that we have mappings for common Mumbai ward patterns
    mumbai_ward_codes = ['A', 'B', 'C', 'D', 'E', 'F/N', 'F/S', 'G/N', 'G/S', 'R/C']

    mumbai_ward_codes.each do |code|
      normalized = WardCodeMapper.normalize(code)
      assert_not_nil normalized, "Ward code #{code} should have a mapping"
      assert_not_equal '', normalized.to_s.strip
    end
  end
end