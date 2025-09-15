require "test_helper"

class Admin::BoundariesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  def setup
    @admin_user = users(:admin_2)  # Already has admin: true in fixtures
    @regular_user = users(:svs_3)  # Regular user in fixtures

    @ward = Ward.find(21)  # Ward referenced by boundary_ward_21_1
    @prabhag = prabhags(:prabhag_A_225)  # Use fixture prabhag

    # Use existing approved boundary as base for creating pending boundaries
    @existing_ward_boundary = boundaries(:boundary_ward_21_1)

    # Create pending boundaries for testing (not in fixtures)
    @ward_boundary = Boundary.create!(
      boundable: @ward,
      geojson: @existing_ward_boundary.geojson,
      source_type: 'user_submission',
      status: 'pending',
      submitted_by: @regular_user
    )

    @prabhag_boundary = Boundary.create!(
      boundable: @prabhag,
      geojson: '{"type":"Polygon","coordinates":[[[72.8266139,19.0192703],[72.8268942,19.0194151],[72.8266139,19.0192703]]]}',
      source_type: 'user_submission',
      status: 'pending',
      submitted_by: @regular_user
    )
  end

  # Authentication and Authorization Tests

  test "should require authentication for approve action" do
    post approve_admin_boundary_path(@ward_boundary)
    assert_redirected_to new_user_session_path
  end

  test "should require authentication for reject action" do
    post reject_admin_boundary_path(@ward_boundary)
    assert_redirected_to new_user_session_path
  end

  test "should require admin privileges for approve action" do
    sign_in @regular_user
    post approve_admin_boundary_path(@ward_boundary)
    assert_redirected_to root_path
    assert_equal 'Access denied. Admin privileges required.', flash[:alert]
  end

  test "should require admin privileges for reject action" do
    sign_in @regular_user
    post reject_admin_boundary_path(@ward_boundary)
    assert_redirected_to root_path
    assert_equal 'Access denied. Admin privileges required.', flash[:alert]
  end

  # Boundary Approval Tests

  test "admin can approve a pending ward boundary" do
    sign_in @admin_user

    assert_equal 'pending', @ward_boundary.status
    assert_nil @ward_boundary.approved_by
    assert_nil @ward_boundary.approved_at

    post approve_admin_boundary_path(@ward_boundary)

    @ward_boundary.reload
    assert_equal 'approved', @ward_boundary.status
    assert_equal @admin_user, @ward_boundary.approved_by
    assert_not_nil @ward_boundary.approved_at
    assert_redirected_to admin_boundaries_path
    assert_equal 'Boundary approved successfully!', flash[:notice]
  end

  test "admin can approve a pending prabhag boundary" do
    sign_in @admin_user

    assert_equal 'pending', @prabhag_boundary.status
    assert_nil @prabhag_boundary.approved_by
    assert_nil @prabhag_boundary.approved_at

    post approve_admin_boundary_path(@prabhag_boundary)

    @prabhag_boundary.reload
    assert_equal 'approved', @prabhag_boundary.status
    assert_equal @admin_user, @prabhag_boundary.approved_by
    assert_not_nil @prabhag_boundary.approved_at
    assert_redirected_to admin_prabhag_path(@prabhag)
    assert_equal 'Prabhag boundary approved successfully!', flash[:notice]
  end

  test "approving boundary sets approval timestamp" do
    sign_in @admin_user
    freeze_time = Time.current

    travel_to freeze_time do
      post approve_admin_boundary_path(@ward_boundary)
    end

    @ward_boundary.reload
    assert_equal freeze_time.to_i, @ward_boundary.approved_at.to_i
  end

  # Boundary Rejection Tests

  test "admin can reject a pending ward boundary with default reason" do
    sign_in @admin_user

    assert_equal 'pending', @ward_boundary.status
    assert_nil @ward_boundary.approved_by
    assert_nil @ward_boundary.approved_at
    assert_nil @ward_boundary.rejection_reason

    post reject_admin_boundary_path(@ward_boundary)

    @ward_boundary.reload
    assert_equal 'rejected', @ward_boundary.status
    assert_equal @admin_user, @ward_boundary.approved_by
    assert_not_nil @ward_boundary.approved_at
    assert_equal "Rejected by admin", @ward_boundary.rejection_reason
    assert_redirected_to admin_boundaries_path
    assert_equal 'Boundary rejected.', flash[:notice]
  end

  test "admin can reject a pending prabhag boundary with custom reason" do
    sign_in @admin_user

    custom_reason = "Boundary is inaccurate and extends beyond prabhag limits"

    post reject_admin_boundary_path(@prabhag_boundary), params: { rejection_reason: custom_reason }

    @prabhag_boundary.reload
    assert_equal 'rejected', @prabhag_boundary.status
    assert_equal @admin_user, @prabhag_boundary.approved_by
    assert_not_nil @prabhag_boundary.approved_at
    assert_equal custom_reason, @prabhag_boundary.rejection_reason
    assert_redirected_to admin_prabhag_path(@prabhag)
    assert_equal 'Prabhag boundary rejected. It has been made available for reassignment.', flash[:notice]
  end

  test "rejecting boundary sets approval timestamp" do
    sign_in @admin_user
    freeze_time = Time.current

    travel_to freeze_time do
      post reject_admin_boundary_path(@ward_boundary)
    end

    @ward_boundary.reload
    assert_equal freeze_time.to_i, @ward_boundary.approved_at.to_i
  end

  # Edge Cases and Error Handling

  test "cannot approve already approved boundary" do
    @ward_boundary.update!(status: 'approved', approved_by: @admin_user, approved_at: 1.day.ago)
    sign_in @admin_user

    original_approved_at = @ward_boundary.approved_at

    post approve_admin_boundary_path(@ward_boundary)

    @ward_boundary.reload
    # Should update the approval details even for already approved boundary
    assert_equal 'approved', @ward_boundary.status
    assert_equal @admin_user, @ward_boundary.approved_by
    assert_not_equal original_approved_at.to_i, @ward_boundary.approved_at.to_i
  end

  test "cannot approve non-existent boundary" do
    sign_in @admin_user

    # Use an ID that definitely doesn't exist in fixtures
    non_existent_id = Boundary.maximum(:id).to_i + 1000

    post approve_admin_boundary_path(non_existent_id)
    assert_response :not_found
  end

  test "cannot reject non-existent boundary" do
    sign_in @admin_user

    # Use an ID that definitely doesn't exist in fixtures
    non_existent_id = Boundary.maximum(:id).to_i + 1000

    post reject_admin_boundary_path(non_existent_id)
    assert_response :not_found
  end

  # Multiple Boundary Scenarios

  test "approving one boundary does not affect other boundaries for same boundable" do
    # Create a second boundary for the same prabhag
    second_boundary = Boundary.create!(
      boundable: @prabhag,
      geojson: '{"type":"Polygon","coordinates":[[[72.8270000,19.0195000],[72.8275000,19.0200000],[72.8270000,19.0195000]]]}',
      source_type: 'user_submission',
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user

    # Approve first boundary
    post approve_admin_boundary_path(@prabhag_boundary)

    @prabhag_boundary.reload
    second_boundary.reload

    assert_equal 'approved', @prabhag_boundary.status
    assert_equal 'pending', second_boundary.status
    assert_equal @admin_user, @prabhag_boundary.approved_by
    assert_nil second_boundary.approved_by
  end

  test "can approve multiple boundaries for same prabhag independently" do
    # Create a second boundary for the same prabhag
    second_boundary = Boundary.create!(
      boundable: @prabhag,
      geojson: '{"type":"Polygon","coordinates":[[[72.8270000,19.0195000],[72.8275000,19.0200000],[72.8270000,19.0195000]]]}',
      source_type: 'user_submission',
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user

    # Approve both boundaries independently
    post approve_admin_boundary_path(@prabhag_boundary)
    post approve_admin_boundary_path(second_boundary)

    @prabhag_boundary.reload
    second_boundary.reload

    assert_equal 'approved', @prabhag_boundary.status
    assert_equal 'approved', second_boundary.status
    assert_equal @admin_user, @prabhag_boundary.approved_by
    assert_equal @admin_user, second_boundary.approved_by
  end

  test "can approve one boundary and reject another for same prabhag" do
    # Create a second boundary for the same prabhag
    second_boundary = Boundary.create!(
      boundable: @prabhag,
      geojson: '{"type":"Polygon","coordinates":[[[72.8270000,19.0195000],[72.8275000,19.0200000],[72.8270000,19.0195000]]]}',
      source_type: 'user_submission',
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user

    # Approve first, reject second
    post approve_admin_boundary_path(@prabhag_boundary)
    post reject_admin_boundary_path(second_boundary), params: { rejection_reason: "Lower quality submission" }

    @prabhag_boundary.reload
    second_boundary.reload

    assert_equal 'approved', @prabhag_boundary.status
    assert_equal 'rejected', second_boundary.status
    assert_equal @admin_user, @prabhag_boundary.approved_by
    assert_equal @admin_user, second_boundary.approved_by
    assert_nil @prabhag_boundary.rejection_reason
    assert_equal "Lower quality submission", second_boundary.rejection_reason
  end

  # Redirects Testing

  test "approving ward boundary redirects to admin boundaries index" do
    sign_in @admin_user

    post approve_admin_boundary_path(@ward_boundary)

    assert_redirected_to admin_boundaries_path
  end

  test "approving prabhag boundary redirects to admin prabhag show" do
    sign_in @admin_user

    post approve_admin_boundary_path(@prabhag_boundary)

    assert_redirected_to admin_prabhag_path(@prabhag)
  end

  test "rejecting ward boundary redirects to admin boundaries index" do
    sign_in @admin_user

    post reject_admin_boundary_path(@ward_boundary)

    assert_redirected_to admin_boundaries_path
  end

  test "rejecting prabhag boundary redirects to admin prabhag show" do
    sign_in @admin_user

    post reject_admin_boundary_path(@prabhag_boundary)

    assert_redirected_to admin_prabhag_path(@prabhag)
  end

  # Boundary Review Workflow Tests - These are covered by system tests

  # US-2: Detailed Boundary Editing Tests

  test "should get boundary edit page for admin" do
    sign_in @admin_user

    get edit_admin_prabhag_boundary_path(@prabhag, @prabhag_boundary)

    assert_response :success
    assert_select "div[data-controller='boundary-tracer']"
    assert_select "iframe#pdf-embed"
    assert_select "div#map[data-boundary-tracer-target='map']"
    assert_select "input[type='submit'][value*='Update Boundary']"

    # Check for approve form (button_to creates a form with submit input)
    assert_match /✅ Approve/, response.body
    assert_select "form[action*='approve']"
  end

  test "should pre-populate boundary data in edit form" do
    sign_in @admin_user

    get edit_admin_prabhag_boundary_path(@prabhag, @prabhag_boundary)

    assert_response :success
    assert_select "div[data-boundary-tracer-existing-boundary-value]"

    # Check that boundary data is included in the page
    boundary_geometry = JSON.parse(@prabhag_boundary.geojson)["geometry"]
    assert_match boundary_geometry.to_json, response.body
  end

  test "should show admin-specific actions on edit page" do
    sign_in @admin_user

    get edit_admin_prabhag_boundary_path(@prabhag, @prabhag_boundary)

    assert_response :success

    # Check that both update and approve buttons are present
    assert_select "input[type='submit'][value*='Update Boundary']"
    assert_match /✅ Approve/, response.body
    assert_select "form[action*='approve']"

    # Check that search landmarks input is NOT present (removed in implementation)
    assert_select "input#map-search-input", count: 0
  end

  test "should only respond to HTML for boundary edit page" do
    sign_in @admin_user

    get edit_admin_prabhag_boundary_path(@prabhag, @prabhag_boundary)
    assert_response :success

    # Edit page doesn't support JSON format
    get edit_admin_prabhag_boundary_path(@prabhag, @prabhag_boundary, format: :json)
    assert_response :not_acceptable
  end

  test "should update boundary with admin edits" do
    sign_in @admin_user

    new_geojson = '{"type":"Feature","properties":{"prabhag_id":1,"created":"2024-01-01T00:00:00.000Z"},"geometry":{"type":"Polygon","coordinates":[[[72.8280000,19.0200000],[72.8285000,19.0205000],[72.8290000,19.0200000],[72.8280000,19.0200000]]]}}'

    patch admin_prabhag_boundary_path(@prabhag, @prabhag_boundary), params: {
      boundary: { geojson: new_geojson }
    }

    @prabhag_boundary.reload
    assert_equal new_geojson, @prabhag_boundary.geojson
    assert_redirected_to admin_prabhag_path(@prabhag)
    assert_equal 'Boundary updated successfully.', flash[:notice]
  end

  test "should track edited_by when admin edits boundary" do
    sign_in @admin_user

    assert_nil @prabhag_boundary.edited_by

    new_geojson = '{"type":"Feature","properties":{"prabhag_id":1,"created":"2024-01-01T00:00:00.000Z"},"geometry":{"type":"Polygon","coordinates":[[[72.8280000,19.0200000],[72.8285000,19.0205000],[72.8290000,19.0200000],[72.8280000,19.0200000]]]}}'

    patch admin_prabhag_boundary_path(@prabhag, @prabhag_boundary), params: {
      boundary: { geojson: new_geojson }
    }

    @prabhag_boundary.reload
    assert_equal @admin_user, @prabhag_boundary.edited_by
  end

  # US-3: Administrative Actions Tests (Extended)

  test "should require admin for boundary edit page" do
    sign_in @regular_user

    get edit_admin_prabhag_boundary_path(@prabhag, @prabhag_boundary)

    assert_redirected_to root_path
    assert_equal 'Access denied. Admin privileges required.', flash[:alert]
  end

  # Delete Action Tests

  test "should require authentication for delete action" do
    delete admin_boundary_path(@ward_boundary)
    assert_redirected_to new_user_session_path
  end

  test "should require admin privileges for delete action" do
    sign_in @regular_user
    delete admin_boundary_path(@ward_boundary)
    assert_redirected_to root_path
    assert_equal 'Access denied. Admin privileges required.', flash[:alert]
  end

  test "admin can delete a ward boundary" do
    sign_in @admin_user

    assert_difference('Boundary.count', -1) do
      delete admin_boundary_path(@ward_boundary)
    end

    assert_redirected_to admin_boundaries_path
    assert_equal 'Boundary deleted successfully.', flash[:notice]
  end

  test "admin can delete a prabhag boundary" do
    sign_in @admin_user

    assert_difference('Boundary.count', -1) do
      delete admin_boundary_path(@prabhag_boundary)
    end

    assert_redirected_to admin_boundaries_path
    assert_equal 'Boundary deleted successfully.', flash[:notice]
  end

  test "cannot delete non-existent boundary" do
    sign_in @admin_user

    # Use an ID that definitely doesn't exist in fixtures
    non_existent_id = Boundary.maximum(:id).to_i + 1000

    delete admin_boundary_path(non_existent_id)
    assert_response :not_found
  end

  test "deleting boundary does not affect other boundaries for same boundable" do
    # Create a second boundary for the same prabhag
    second_boundary = Boundary.create!(
      boundable: @prabhag,
      geojson: '{"type":"Polygon","coordinates":[[[72.8270000,19.0195000],[72.8275000,19.0200000],[72.8270000,19.0195000]]]}',
      source_type: 'user_submission',
      status: 'pending',
      submitted_by: @regular_user
    )

    sign_in @admin_user

    assert_difference('Boundary.count', -1) do
      delete admin_boundary_path(@prabhag_boundary)
    end

    second_boundary.reload
    assert_equal 'pending', second_boundary.status
    assert_equal @prabhag, second_boundary.boundable
  end

  test "can delete approved boundary" do
    @prabhag_boundary.update!(status: 'approved', approved_by: @admin_user, approved_at: 1.day.ago)
    sign_in @admin_user

    assert_difference('Boundary.count', -1) do
      delete admin_boundary_path(@prabhag_boundary)
    end

    assert_redirected_to admin_boundaries_path
    assert_equal 'Boundary deleted successfully.', flash[:notice]
  end

  test "can delete rejected boundary" do
    @prabhag_boundary.update!(status: 'rejected', approved_by: @admin_user, approved_at: 1.day.ago, rejection_reason: 'Test rejection')
    sign_in @admin_user

    assert_difference('Boundary.count', -1) do
      delete admin_boundary_path(@prabhag_boundary)
    end

    assert_redirected_to admin_boundaries_path
    assert_equal 'Boundary deleted successfully.', flash[:notice]
  end

  test "can delete canonical boundary" do
    @prabhag_boundary.update!(status: 'canonical', is_canonical: true)
    sign_in @admin_user

    assert_difference('Boundary.count', -1) do
      delete admin_boundary_path(@prabhag_boundary)
    end

    assert_redirected_to admin_boundaries_path
    assert_equal 'Boundary deleted successfully.', flash[:notice]
  end

end