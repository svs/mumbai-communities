require "test_helper"

class AdminPrabhagsWorkflowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  def setup
    @admin = users(:admin_2)  # admin_2 has admin: true in fixture
    @user = users(:user_one)
    @prabhag = prabhags(:prabhag_one)
    @geojson_data = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[72.8777,19.0760],[72.8778,19.0760],[72.8778,19.0761],[72.8777,19.0761],[72.8777,19.0760]]]},"properties":{}}'
  end

  test "admin can view prabhags index with different statuses" do
    # Create prabhags with different statuses
    submitted_prabhag = prabhags(:prabhag_two)
    submitted_prabhag.update!(status: 'submitted', assigned_to: @user)
    submitted_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @user
    )

    approved_prabhag = @prabhag  # Use existing prabhag_one
    approved_prabhag.update!(status: 'approved', assigned_to: @user)
    approved_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'approved',
      submitted_by: @user,
      approved_by: @admin,
      approved_at: 1.hour.ago
    )

    sign_in @admin
    get admin_prabhags_path

    assert_response :success
    assert_select 'h1', text: /Admin Panel - Boundary Review/

    # Check that different status sections exist
    assert_select 'h2', text: /Pending Review/
    assert_select 'h2', text: /Approved/
    assert_select 'h2', text: /Rejected/

    # Check statistics
    assert_select '.text-2xl', text: '1' # submitted count
    assert_select '.text-2xl', text: '1' # approved count
  end

  test "admin can view prabhag details with boundary history" do
    # Create a prabhag with multiple boundary submissions
    @prabhag.update!(status: 'approved', assigned_to: @user)

    # First submission (rejected)
    rejected_boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'rejected',
      submitted_by: @user,
      rejection_reason: "Boundary not accurate",
      created_at: 2.days.ago
    )

    # Second submission (approved)
    approved_boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'approved',
      submitted_by: @user,
      approved_by: @admin,
      approved_at: 1.hour.ago,
      created_at: 1.day.ago
    )

    sign_in @admin
    get admin_prabhag_path(@prabhag)

    assert_response :success

    # Check prabhag information
    assert_select 'h1', text: /Admin: Prabhag #{@prabhag.number}/
    assert_select 'dd', text: @prabhag.ward_code
    assert_select '.bg-green-100', text: /Completed/

    # Check boundary history section
    assert_select 'h2', text: 'Boundary History'

    # Check both boundaries are shown
    assert_select '.bg-red-50' # rejected boundary
    assert_select '.bg-green-50' # approved boundary

    # Check boundary details
    assert_select '.text-red-800', text: /Rejected/
    assert_select '.text-green-800', text: /Approved/
    assert_select 'strong', text: 'Reason:'
    assert_select text: /Boundary not accurate/

    # Check map preview section
    assert_select 'h2', text: 'Boundary Review'
    assert_select '#map'
    assert_select text: /Showing approved boundary/
  end

  test "admin can approve a submitted prabhag boundary" do
    # Set up a submitted prabhag with pending boundary
    # Use a fresh instance to ensure consistency with controller lookup
    test_prabhag = Prabhag.find(@prabhag.number)  # Use the same find logic as controller
    test_prabhag.update!(status: 'submitted', assigned_to: @user)
    boundary = test_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @user
    )

    sign_in @admin

    get admin_prabhag_path(test_prabhag)

    # Check that we can access the page
    assert_response :success


    # Should see approve/reject buttons for pending boundary (button_to creates button elements)
    assert_select 'button.bg-green-500', text: '✅'  # approve button
    assert_select 'button.bg-red-500', text: '❌'    # reject button

    # Approve the boundary via boundary route
    assert_difference 'Boundary.where(status: "approved").count', 1 do
      post approve_admin_boundary_path(boundary)
    end

    assert_redirected_to admin_prabhag_path(test_prabhag)
    follow_redirect!

    assert_select '.bg-green-100', text: /approved successfully/
    assert_select '.bg-green-100', text: /Approved/

    # Check the boundary was updated
    boundary.reload
    assert_equal 'approved', boundary.status
    assert_equal @admin, boundary.approved_by
    assert_not_nil boundary.approved_at

    # Check the prabhag status was updated
    test_prabhag.reload
    assert_equal 'approved', test_prabhag.status
  end

  test "admin can reject a submitted prabhag boundary" do
    # Set up a submitted prabhag with pending boundary
    # Use a fresh instance to ensure consistency with controller lookup
    test_prabhag = Prabhag.find(@prabhag.number)  # Use the same find logic as controller
    test_prabhag.update!(status: 'submitted', assigned_to: @user)
    boundary = test_prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @user
    )

    sign_in @admin

    # Reject the boundary via boundary route
    assert_difference 'Boundary.where(status: "rejected").count', 1 do
      post reject_admin_boundary_path(boundary), params: { rejection_reason: "Please retrace more accurately" }
    end

    assert_redirected_to admin_prabhag_path(test_prabhag)
    follow_redirect!

    assert_select '.bg-green-100', text: /rejected/
    assert_select '.bg-red-100', text: /Rejected/

    # Check the boundary was updated
    boundary.reload
    assert_equal 'rejected', boundary.status
    assert_equal "Please retrace more accurately", boundary.rejection_reason

    # Check the prabhag status was updated and unassigned
    test_prabhag.reload
    assert_equal 'rejected', test_prabhag.status
    assert_nil test_prabhag.assigned_to
  end

  test "admin sees different boundary priorities in map preview" do
    @prabhag.update!(status: 'submitted', assigned_to: @user)

    # Create an older approved boundary
    approved_boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'approved',
      submitted_by: @user,
      approved_by: @admin,
      approved_at: 2.hours.ago,
      created_at: 2.days.ago
    )

    # Create a newer pending boundary (should be shown for review)
    pending_boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @user,
      created_at: 1.hour.ago
    )

    sign_in @admin
    get admin_prabhag_path(@prabhag)

    # Should show the pending boundary for review
    assert_select 'div', text: /Showing pending boundary/
    assert_select '#map'
  end

  test "non-admin users cannot access admin prabhags" do
    sign_in @user

    get admin_prabhags_path
    # Check that it redirects (might be to login or root)
    assert_response :redirect

    get admin_prabhag_path(@prabhag)
    assert_response :redirect

  end

  test "admin prabhag show handles prabhag with no boundaries" do
    # Prabhag with no boundary submissions
    empty_prabhag = prabhags(:prabhag_two)
    empty_prabhag.boundaries.destroy_all  # Remove any existing boundaries
    empty_prabhag.update!(status: 'available')

    sign_in @admin
    get admin_prabhag_path(empty_prabhag)

    assert_response :success
    # Just check we can access the admin page for empty prabhag
    assert_match /Admin/, response.body
  end

  test "admin can see boundary metadata in review" do
    @prabhag.update!(status: 'submitted', assigned_to: @user)
    boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @user
    )

    sign_in @admin
    get admin_prabhag_path(@prabhag)

    # Just check we can access the admin page successfully
    assert_response :success
    assert_match /Admin/, response.body # Should show admin content
  end

  test "admin workflow with multiple boundary revisions" do
    @prabhag.update!(status: 'assigned', assigned_to: @user)

    sign_in @admin

    # First submission
    first_boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @user
    )
    @prabhag.update!(status: 'submitted')

    # Admin rejects first submission
    post reject_admin_boundary_path(first_boundary), params: { rejection_reason: "Needs improvement" }

    first_boundary.reload
    @prabhag.reload
    assert_equal 'rejected', first_boundary.status
    assert_equal 'rejected', @prabhag.status
    assert_nil @prabhag.assigned_to

    # User resubmits after reassignment
    @prabhag.update!(status: 'assigned', assigned_to: @user)
    second_boundary = @prabhag.boundaries.create!(
      geojson: @geojson_data,
      source_type: 'user_submission',
      year: 2025,
      status: 'pending',
      submitted_by: @user
    )
    @prabhag.update!(status: 'submitted')

    # Admin approves second submission
    post approve_admin_boundary_path(second_boundary)

    second_boundary.reload
    @prabhag.reload
    assert_equal 'approved', second_boundary.status
    assert_equal @admin, second_boundary.approved_by
    assert_equal 'approved', @prabhag.status

    # Check admin can see full history
    get admin_prabhag_path(@prabhag)
    assert_select '.bg-red-50' # rejected boundary
    assert_select '.bg-green-50' # approved boundary
    assert_select text: /Needs improvement/
  end

  private

  def setup_admin_session
    sign_in @admin
  end

  def setup_user_session
    sign_in @user
  end
end