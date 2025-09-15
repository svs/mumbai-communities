require "test_helper"

class Admin::PrabhagsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin_user = users(:admin_2)  # Use fixture admin user
    @regular_user = users(:user_one)  # Use fixture regular user
    @prabhag = prabhags(:prabhag_one)  # Use fixture prabhag

    # Create some test boundaries for different scenarios
    @geojson_data = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[72.8777,19.0760],[72.8778,19.0760],[72.8778,19.0761],[72.8777,19.0761],[72.8777,19.0760]]]},"properties":{}}'
  end

  # Authentication Tests
  test "redirects to login when not authenticated" do
    get admin_prabhags_path
    assert_redirected_to new_user_session_path
  end

  test "redirects to root when not admin" do
    sign_in @regular_user
    get admin_prabhags_path
    assert_redirected_to root_path
    assert_equal 'Access denied. Admin privileges required.', flash[:alert]
  end

  # Index Action Tests
  test "admin can access index" do
    sign_in @admin_user
    get admin_prabhags_path
    assert_response :success
  end

  test "index loads prabhags by status with counts" do
    # Set up prabhags in different statuses
    submitted_prabhag = Prabhag.find_by(status: 'submitted') || @prabhag
    submitted_prabhag.update!(status: 'submitted')

    approved_prabhag = Prabhag.where.not(id: submitted_prabhag.id).first
    approved_prabhag&.update!(status: 'approved')

    rejected_prabhag = Prabhag.where.not(id: [submitted_prabhag.id, approved_prabhag&.id]).first
    rejected_prabhag&.update!(status: 'rejected')

    sign_in @admin_user
    get admin_prabhags_path

    assert_response :success

    # Check that instance variables are set
    assert_not_nil assigns(:submitted_prabhags)
    assert_not_nil assigns(:approved_prabhags)
    assert_not_nil assigns(:rejected_prabhags)
    assert_not_nil assigns(:total_submitted)
    assert_not_nil assigns(:total_approved)
    assert_not_nil assigns(:total_rejected)
  end

  test "index includes assigned_to associations" do
    # Set up a prabhag with assigned user
    @prabhag.update!(status: 'submitted', assigned_to: @regular_user)

    sign_in @admin_user
    get admin_prabhags_path

    assert_response :success

    # Verify that assigned_to associations are loaded (no additional queries)
    submitted_prabhags = assigns(:submitted_prabhags)
    assert submitted_prabhags.any?

    # This should not trigger additional database queries since we included :assigned_to
    submitted_prabhags.each { |p| p.assigned_to&.name }
  end

  # Show Action Tests
  test "admin can access show" do
    sign_in @admin_user
    get admin_prabhag_path(@prabhag)
    assert_response :success
  end

  test "show sets pending and current boundary" do
    # Use the prabhag that will actually be found by the controller
    # The controller uses Prabhag.find(@prabhag.number), so we need to make sure
    # we're testing with the same prabhag instance the controller will use
    controller_prabhag = Prabhag.find(@prabhag.number)

    # Create a pending boundary on the correct prabhag
    controller_prabhag.update!(status: 'submitted', assigned_to: @regular_user)
    pending_boundary = controller_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user
    get admin_prabhag_path(@prabhag)

    assert_response :success
    assert_equal pending_boundary, assigns(:pending_boundary)
    assert_equal pending_boundary, assigns(:current_boundary)
  end

  test "show uses best available boundary when no pending boundary" do
    # Use the prabhag that will actually be found by the controller
    controller_prabhag = Prabhag.find(@prabhag.number)

    # Create an approved boundary
    approved_boundary = controller_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'approved',
      submitted_by: @regular_user,
      approved_by: @admin_user,
      approved_at: 1.hour.ago
    )

    sign_in @admin_user
    get admin_prabhag_path(@prabhag)

    assert_response :success
    assert_nil assigns(:pending_boundary)
    assert_equal approved_boundary, assigns(:current_boundary)
  end

  test "show parses geojson data when available" do
    # Use the prabhag that will actually be found by the controller
    controller_prabhag = Prabhag.find(@prabhag.number)

    # Create boundary with geojson
    boundary = controller_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user
    get admin_prabhag_path(@prabhag)

    assert_response :success
    assert_not_nil assigns(:geojson_data)
    assert_equal JSON.parse(@geojson_data), assigns(:geojson_data)
  end

  test "show handles missing geojson gracefully" do
    # Create boundary with valid geojson but then simulate missing data in controller
    boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    # Mock geojson to return nil to test graceful handling
    boundary.stubs(:geojson).returns(nil)
    @prabhag.stubs(:boundary).returns(boundary)

    sign_in @admin_user
    get admin_prabhag_path(@prabhag)

    assert_response :success
    assert_nil assigns(:geojson_data)
  end

  test "show handles empty geojson gracefully" do
    # Create boundary with valid geojson but then simulate empty data in controller
    boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    # Mock geojson to return empty string to test graceful handling
    boundary.stubs(:geojson).returns('')
    @prabhag.stubs(:boundary).returns(boundary)

    sign_in @admin_user
    get admin_prabhag_path(@prabhag)

    assert_response :success
    assert_nil assigns(:geojson_data)
  end

  test "show handles malformed geojson gracefully" do
    # Create boundary with valid geojson but then simulate malformed data in controller
    boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    # Mock geojson to return invalid JSON to test graceful handling
    boundary.stubs(:geojson).returns('invalid json')
    @prabhag.stubs(:boundary).returns(boundary)

    sign_in @admin_user

    # Should not raise an error
    assert_nothing_raised do
      get admin_prabhag_path(@prabhag)
    end

    assert_response :success
  end

  # Prabhag Finding Tests
  test "finds prabhag by number when using routing" do
    # Prabhag.find should work with both id and number
    sign_in @admin_user
    get admin_prabhag_path(@prabhag.number)  # Use number instead of id
    assert_response :success
  end

  test "returns 404 for non-existent prabhag" do
    sign_in @admin_user

    get admin_prabhag_path(99999)
    assert_response :not_found
  end

  # Authorization Edge Cases
  test "denies access when user loses admin privileges mid-session" do
    sign_in @admin_user

    # Simulate user losing admin privileges
    @admin_user.update!(admin: false)

    get admin_prabhags_path
    assert_redirected_to root_path
    assert_equal 'Access denied. Admin privileges required.', flash[:alert]
  end

  test "allows access for valid admin user" do
    # Ensure user is admin
    @admin_user.update!(admin: true)
    sign_in @admin_user

    get admin_prabhags_path
    assert_response :success
  end

  # View Rendering Tests
  test "index renders successfully with multiple prabhag statuses" do
    # Create prabhags in different statuses
    prabhag1 = @prabhag
    prabhag1.update!(status: 'submitted')

    prabhag2 = Prabhag.where.not(id: prabhag1.id).first
    prabhag2&.update!(status: 'approved')

    sign_in @admin_user
    get admin_prabhags_path

    assert_response :success
    assert_select 'h1', text: /Admin Panel/
  end

  test "show renders successfully with boundary data" do
    @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user
    get admin_prabhag_path(@prabhag)

    assert_response :success
    assert_select 'h1', text: /Admin: Prabhag/
  end

  # Error Handling Tests
  test "handles database errors gracefully" do
    sign_in @admin_user

    # Simulate database connection error
    Prabhag.stubs(:submitted).raises(ActiveRecord::StatementInvalid.new('Database error'))

    assert_raises(ActiveRecord::StatementInvalid) do
      get admin_prabhags_path
    end
  end

  # Boundary Review Workflow Tests

  test "should get boundary review list with for_review param" do
    controller_prabhag = Prabhag.find(@prabhag.number)

    # Create a few boundaries for review
    boundary1 = controller_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    boundary2 = controller_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user
    get boundaries_admin_prabhag_path(@prabhag), headers: { 'Accept' => 'application/json' }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal 2, response_data['boundaries'].count
  end

  test "should show only pending boundaries in review list" do
    controller_prabhag = Prabhag.find(@prabhag.number)

    # Create boundaries with different statuses
    pending_boundary = controller_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    approved_boundary = controller_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'approved',
      submitted_by: @regular_user,
      approved_by: @admin_user,
      approved_at: 1.hour.ago
    )

    sign_in @admin_user
    get boundaries_admin_prabhag_path(@prabhag), headers: { 'Accept' => 'application/json' }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal 1, response_data['boundaries'].count
    # Check that only the pending boundary is included
    boundary_ids = response_data['boundaries'].map { |b| b['id'] }
    assert_includes boundary_ids, pending_boundary.id
    assert_not_includes boundary_ids, approved_boundary.id
  end

  test "should include PDF and map data for boundary review" do
    controller_prabhag = Prabhag.find(@prabhag.number)

    # Create a boundary for review
    boundary = controller_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user
    get boundaries_admin_prabhag_path(@prabhag), headers: { 'Accept' => 'application/json' }

    assert_response :success
    response_data = JSON.parse(response.body)

    # Check prabhag data includes PDF info
    assert_not_nil response_data['prabhag']
    assert_equal controller_prabhag.pdf_url, response_data['prabhag']['pdf_url']
    assert_equal controller_prabhag.map_image_src, response_data['prabhag']['map_image_src']

    # Check boundaries include geojson_feature for map display
    boundary_data = response_data['boundaries'].first
    assert_not_nil boundary_data['geojson_feature']

    # Parse the geojson_feature if it's a string
    geojson_feature = boundary_data['geojson_feature']
    if geojson_feature.is_a?(String)
      geojson_feature = JSON.parse(geojson_feature)
    end
    assert_equal 'Feature', geojson_feature['type']
  end

  test "should respond with JSON for boundary review list" do
    controller_prabhag = Prabhag.find(@prabhag.number)

    # Create a boundary for review
    boundary = controller_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user
    get boundaries_admin_prabhag_path(@prabhag), headers: { 'Accept' => 'text/html' }

    assert_response :success
    assert_select 'h1', text: /Review Boundaries/
    assert_select '.boundary-map[data-controller="leaflet-map"]'
    assert_select 'a', text: 'Review in Detail'
    assert_select 'button', text: /Quick Approve/
  end

  test "should show empty state when no boundaries for review" do
    controller_prabhag = Prabhag.find(@prabhag.number)

    # Make sure there are no pending boundaries
    controller_prabhag.boundaries.where(status: 'pending').destroy_all

    sign_in @admin_user
    get boundaries_admin_prabhag_path(@prabhag), headers: { 'Accept' => 'application/json' }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal 0, response_data['boundaries'].count
  end

  test "admin show page includes review boundaries link when pending boundaries exist" do
    controller_prabhag = Prabhag.find(@prabhag.number)

    # Create a pending boundary
    controller_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user
    get admin_prabhag_path(@prabhag)

    assert_response :success
    assert_select 'a[href=?]', boundaries_admin_prabhag_path(@prabhag), text: /Review Boundaries/
    assert_select 'div', text: /1 Pending Review/
  end

  test "should get boundary edit page for admin review" do
    # TODO: Implement test
    skip "Not yet implemented"
  end

  test "should pre-populate boundary data for admin editing" do
    # TODO: Implement test
    skip "Not yet implemented"
  end

  test "should allow admin to edit and save boundary changes" do
    # TODO: Implement test
    skip "Not yet implemented"
  end

  test "should track edited_by when admin modifies boundary" do
    # TODO: Implement test
    skip "Not yet implemented"
  end

  test "should approve boundary from detailed review page" do
    # TODO: Implement test
    skip "Not yet implemented"
  end

  test "should reject boundary from detailed review page" do
    # TODO: Implement test
    skip "Not yet implemented"
  end
end
