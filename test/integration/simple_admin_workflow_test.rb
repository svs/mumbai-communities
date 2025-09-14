require "test_helper"

class SimpleAdminWorkflowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = users(:user_two)  # admin user
    @user = users(:user_one)   # regular user
    @prabhag = prabhags(:prabhag_one)
    @geojson_data = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[72.8777,19.0760],[72.8778,19.0760],[72.8778,19.0761],[72.8777,19.0761],[72.8777,19.0760]]]},"properties":{}}'
  end

  test "complete admin workflow: submit -> approve" do
    # Set up a prabhag with pending boundary
    @prabhag.update!(status: 'submitted', assigned_to: @user)
    boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @user
    )

    # Admin can access the page
    sign_in @admin
    get admin_prabhag_path(@prabhag)
    assert_response :success

    # Admin can approve the boundary
    post approve_admin_prabhag_path(@prabhag)
    assert_response :redirect

    # Check that boundary and prabhag were updated
    boundary.reload
    @prabhag.reload

    assert_equal 'approved', boundary.status
    assert_equal @admin, boundary.approved_by
    assert_equal 'approved', @prabhag.status
  end

  test "complete admin workflow: submit -> reject" do
    # Set up a prabhag with pending boundary
    @prabhag.update!(status: 'submitted', assigned_to: @user)
    boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @user
    )

    # Admin can reject the boundary
    sign_in @admin
    post reject_admin_prabhag_path(@prabhag), params: { rejection_reason: "Please improve" }
    assert_response :redirect

    # Check that boundary and prabhag were updated
    boundary.reload
    @prabhag.reload

    assert_equal 'rejected', boundary.status
    assert_equal "Please improve", boundary.rejection_reason
    assert_equal 'rejected', @prabhag.status
    assert_nil @prabhag.assigned_to  # Should be unassigned
  end

  test "admin can access index page" do
    sign_in @admin

    get admin_prabhags_path
    assert_response :success
    assert_select 'h1', text: /Admin Panel/
  end

  test "non-admin cannot access admin functions" do
    sign_in @user

    get admin_prabhags_path
    assert_response :redirect  # Should be redirected away

    get admin_prabhag_path(@prabhag)
    assert_response :redirect  # Should be redirected away
  end
end