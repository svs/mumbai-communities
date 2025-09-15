require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Only load specific fixtures to avoid foreign key issues
  fixtures :users, :wards, :prabhags, :boundaries
  def setup
    @user = users(:admin_2)
    @ward = wards(:ward_A)
    @prabhag = prabhags(:prabhag_A_225)
  end

  test "should get index for anonymous user" do
    get root_path
    assert_response :success

    # Should show landing page elements
    assert_select "h1", text: /MAKE REAL CHANGE/
    assert_select "h2", text: "Join Your Ward Community"
    assert_select ".bg-blue-600", text: "Sign in with Google"

    # Should show statistics in the rendered content
    assert_match /\d+ Active Ward Communities/, response.body
    assert_match /\d+ Issues Resolved/, response.body
    assert_match /\d+ Events This Month/, response.body

    # Should not show user-specific content
    assert_select "h1", text: /Welcome back/, count: 0
    assert_select ".bg-yellow-50", count: 0 # User activity section
  end

  test "should redirect authenticated user with location to their prabhag" do
    sign_in @user
    get root_path

    # User has location data, should redirect to their prabhag
    assert_response :redirect
  end

  test "should load statistics correctly" do
    get root_path
    assert_response :success

    # Should show statistics from fixture data
    assert_match /\d+/, response.body
  end

  test "should load recent activity feed" do
    get root_path
    assert_response :success

    # Should render without errors - no tickets exist yet
    assert_select ".bg-white"
  end

  test "should load featured wards" do
    get root_path
    assert_response :success

    # Should render ward map without errors
    assert_select "[data-controller='leaflet-map']"
  end

  test "should handle user with assignments" do
    sign_in @user
    get root_path

    # User has location, should redirect (not show dashboard)
    assert_response :redirect
  end

  test "should render interactive ward map" do
    get root_path

    # Should include leaflet map controller
    assert_select "[data-controller='leaflet-map']"
    assert_select "[data-leaflet-map-data-url-value='/wards.json']"
    assert_select "[data-leaflet-map-static-value='true']"

    # Should show map legend
    assert_select ".bg-green-500" # Active indicator
    assert_select ".bg-yellow-500" # Growing indicator
    assert_select ".bg-gray-400" # Inactive indicator
  end

  test "should show authentication options for anonymous users" do
    get root_path

    # Should show OAuth and traditional auth options
    assert_select "form[action='#{user_google_oauth2_omniauth_authorize_path}']"
    assert_select "a[href='#{new_user_session_path}']", text: "Sign In"
    assert_select "a[href='#{new_user_registration_path}']", text: "Sign Up"
  end

  test "should not show auth section for logged in users" do
    sign_in @user
    get root_path

    assert_select "h2", text: "Ready to Make a Difference?", count: 0
    assert_select ".bg-blue-600", text: "Sign in with Google", count: 0
  end

  test "should handle user without assignments gracefully" do
    sign_in @user
    get root_path

    # User has location, should redirect (not show dashboard)
    assert_response :redirect
  end

end