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
  end

  test "should redirect to login if not authenticated" do
    sign_out @user
    get setup_location_url
    assert_redirected_to new_user_session_path
  end

  test "should set location when coordinates are within boundary" do
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
      status: 'approved',
      source_type: 'user_submission'
    )

    post setup_location_url, params: {
      latitude: "19.1406618",
      longitude: "72.8646092",
      formatted_address: "Test Address"
    }

    assert_redirected_to root_path

    @user.reload
    assert_equal "Test Address", @user.street_address
    assert_equal prabhag.ward_code, @user.ward_code
    assert_equal prabhag.id, @user.prabhag_id
  end

  test "should redirect back when coordinates not in any boundary" do
    post setup_location_url, params: {
      latitude: "18.0",
      longitude: "71.0",
      street_address: "Outside Mumbai"
    }

    assert_redirected_to setup_location_path
  end
end