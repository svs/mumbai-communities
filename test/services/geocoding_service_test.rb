require 'test_helper'

class GeocodingServiceTest < ActiveSupport::TestCase
  test "should find prabhag from coordinates when point is within boundary" do
    # Create a prabhag with a boundary
    prabhag = prabhags(:one)

    # Create a simple square boundary around the test coordinates
    boundary = boundaries(:prabhag_boundary)
    boundary.update!(
      boundable: prabhag,
      geojson: {
        type: "Feature",
        geometry: {
          type: "Polygon",
          coordinates: [[
            [72.8, 19.1],   # Southwest corner
            [72.9, 19.1],   # Southeast corner
            [72.9, 19.2],   # Northeast corner
            [72.8, 19.2],   # Northwest corner
            [72.8, 19.1]    # Close the polygon
          ]]
        }
      }.to_json,
      status: 'approved'
    )

    # Test point within the boundary
    ward_code, prabhag_id = GeocodingService.find_prabhag_from_coordinates(19.15, 72.85)

    assert_equal prabhag.ward_code, ward_code
    assert_equal prabhag.id, prabhag_id
  end

  test "should return nil when point is outside all boundaries" do
    # Test point outside any boundary
    ward_code, prabhag_id = GeocodingService.find_prabhag_from_coordinates(0, 0)

    assert_nil ward_code
    assert_nil prabhag_id
  end

  test "should handle invalid geojson gracefully" do
    # Create a prabhag with invalid geojson
    prabhag = prabhags(:one)
    boundary = boundaries(:prabhag_boundary)
    boundary.update!(
      boundable: prabhag,
      geojson: "invalid json",
      status: 'approved'
    )

    # Should not raise error, should return nil
    ward_code, prabhag_id = GeocodingService.find_prabhag_from_coordinates(19.15, 72.85)

    assert_nil ward_code
    assert_nil prabhag_id
  end

  test "should only check approved and canonical boundaries" do
    prabhag = prabhags(:one)

    # Create a pending boundary that contains the point
    pending_boundary = Boundary.create!(
      boundable: prabhag,
      geojson: {
        type: "Feature",
        geometry: {
          type: "Polygon",
          coordinates: [[
            [72.8, 19.1], [72.9, 19.1], [72.9, 19.2], [72.8, 19.2], [72.8, 19.1]
          ]]
        }
      }.to_json,
      source_type: 'user_submission',
      status: 'pending'
    )

    # Should not match pending boundary
    ward_code, prabhag_id = GeocodingService.find_prabhag_from_coordinates(19.15, 72.85)

    assert_nil ward_code
    assert_nil prabhag_id
  end

  test "should log information during geocoding" do
    # Test that logging works without errors
    assert_nothing_raised do
      GeocodingService.find_prabhag_from_coordinates(19.15, 72.85)
    end
  end
end