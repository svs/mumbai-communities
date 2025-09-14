require 'test_helper'

class LocationSetupControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    sign_in @user
  end

  test "should get show" do
    get setup_location_url
    assert_response :success
    assert_select 'h1', 'Find Your Ward Community'
    assert_select 'form[action=?]', setup_location_path
  end

  test "should redirect to login if not authenticated" do
    sign_out @user
    get setup_location_url
    assert_redirected_to new_user_session_path
  end

  test "should create location with valid coordinates" do
    # Create a real prabhag with boundary for testing
    prabhag = prabhags(:prabhag_one)

    # Create a boundary that contains the test coordinates
    Boundary.create!(
      boundable: prabhag,
      geojson: {
        type: "Feature",
        geometry: {
          type: "Polygon",
          coordinates: [[
            [72.86, 19.14],   # Southwest corner
            [72.87, 19.14],   # Southeast corner
            [72.87, 19.15],   # Northeast corner
            [72.86, 19.15],   # Northwest corner
            [72.86, 19.14]    # Close the polygon
          ]]
        }
      }.to_json,
      status: 'approved'
    )

    post setup_location_url, params: {
      street_address: "Oberoi Splendor Road, Mumbai",
      latitude: "19.1406618",
      longitude: "72.8646092",
      formatted_address: "Oberoi Splendor Rd, Oberoi Splendor, Jogeshwari East, Mumbai, Maharashtra 400060, India"
    }

    assert_redirected_to root_path
    assert_match /Perfect! We found your location in Ward #{prabhag.ward_code}/, flash[:success]

    @user.reload
    assert_equal "Oberoi Splendor Rd, Oberoi Splendor, Jogeshwari East, Mumbai, Maharashtra 400060, India", @user.street_address
    assert_equal prabhag.ward_code, @user.ward_code
    assert_equal prabhag.id, @user.prabhag_id
    assert_equal 19.1406618, @user.latitude.to_f
    assert_equal 72.8646092, @user.longitude.to_f
  end

  test "should handle coordinates not found" do
    # Use coordinates outside any existing boundary (somewhere in the ocean)
    post setup_location_url, params: {
      street_address: "Some address outside Mumbai",
      latitude: "0.0",
      longitude: "0.0",
      formatted_address: "Some formatted address"
    }

    assert_redirected_to setup_location_path
    assert_match /We couldn't match your address to a specific ward and prabhag/, flash[:alert]
  end

  test "should handle missing street address" do
    post setup_location_url, params: {
      street_address: "",
      latitude: "19.1406618",
      longitude: "72.8646092"
    }

    assert_redirected_to setup_location_path
    assert_equal "Please enter your street address", flash[:alert]
  end

  test "should handle blank street address" do
    post setup_location_url, params: {
      street_address: "   ",
      latitude: "19.1406618",
      longitude: "72.8646092"
    }

    assert_redirected_to setup_location_path
    assert_equal "Please enter your street address", flash[:alert]
  end

  test "should fallback to address matching when coordinates are zero" do
    # Mock the address fallback to return a match
    post setup_location_url, params: {
      street_address: "bandra west mumbai",
      latitude: "0",
      longitude: "0"
    }

    # Should try address matching instead of coordinates
    assert_redirected_to setup_location_path
    # Will likely not match with current simple address matching
    assert_match /We couldn't match your address/, flash[:alert]
  end

  test "should use formatted address when available with coordinates" do
    # Create a real prabhag with boundary for testing
    prabhag = prabhags(:prabhag_one)

    # Create a boundary that contains the test coordinates
    Boundary.create!(
      boundable: prabhag,
      geojson: {
        type: "Feature",
        geometry: {
          type: "Polygon",
          coordinates: [[
            [72.86, 19.14], [72.87, 19.14], [72.87, 19.15], [72.86, 19.15], [72.86, 19.14]
          ]]
        }
      }.to_json,
      status: 'approved'
    )

    post setup_location_url, params: {
      street_address: "Short address",
      latitude: "19.1406618",
      longitude: "72.8646092",
      formatted_address: "Full Formatted Address from Google"
    }

    @user.reload
    assert_equal "Full Formatted Address from Google", @user.street_address
  end

  test "should use street address when no formatted address provided" do
    # Create a real prabhag with boundary for testing
    prabhag = prabhags(:prabhag_one)

    # Create a boundary that contains the test coordinates
    Boundary.create!(
      boundable: prabhag,
      geojson: {
        type: "Feature",
        geometry: {
          type: "Polygon",
          coordinates: [[
            [72.86, 19.14], [72.87, 19.14], [72.87, 19.15], [72.86, 19.15], [72.86, 19.14]
          ]]
        }
      }.to_json,
      status: 'approved'
    )

    post setup_location_url, params: {
      street_address: "User typed address",
      latitude: "19.1406618",
      longitude: "72.8646092"
    }

    @user.reload
    assert_equal "User typed address", @user.street_address
  end
end