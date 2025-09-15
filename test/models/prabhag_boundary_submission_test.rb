require "test_helper"

class PrabhaghBoundarySubmissionTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_one)
    @admin = users(:admin_user)

    # Create test prabhag instead of using fixture
    @prabhag = Prabhag.create!(
      number: 1001,
      name: "Test Prabhag A1",
      ward_code: "TEST1",
      pdf_url: "https://example.com/test1001.pdf",
      status: "available"
    )
  end

  test "submit_boundary! should create a new pending boundary record" do
    geojson_data = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}'

    assert_difference '@prabhag.boundaries.count', 1 do
      @prabhag.submit_boundary!(geojson_data, submitted_by: @user)
    end

    boundary = @prabhag.boundaries.last
    assert_equal 'user_submission', boundary.source_type
    assert_equal 2025, boundary.year
    assert_equal 'pending', boundary.status
    assert_equal false, boundary.is_canonical
    assert_equal @user, boundary.submitted_by
    assert_equal 'submitted', @prabhag.reload.status
  end



  test "multiple submissions should create multiple boundary records" do
    geojson_data1 = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}'
    geojson_data2 = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[1,1],[2,1],[2,2],[1,2],[1,1]]]}}'

    # First submission
    @prabhag.submit_boundary!(geojson_data1, submitted_by: @user)
    assert_equal 1, @prabhag.boundaries.count

    # Reject first submission (direct boundary update)
    boundary1 = @prabhag.boundaries.last
    boundary1.update!(status: 'rejected', rejection_reason: "Try again")
    @prabhag.update!(status: 'rejected', assigned_to: nil)

    # Reassign and second submission
    @prabhag.update!(status: 'assigned', assigned_to: @user)
    @prabhag.submit_boundary!(geojson_data2, submitted_by: @user)

    assert_equal 2, @prabhag.boundaries.count

    # Approve the second boundary (direct boundary update)
    boundary2 = @prabhag.boundaries.last
    boundary2.update!(status: 'approved', approved_by: @admin, approved_at: Time.current)
    @prabhag.update!(status: 'approved')

    boundaries = @prabhag.boundaries.order(:created_at)
    assert_equal 'rejected', boundaries.first.status
    assert_equal 'approved', boundaries.last.status
  end

  test "boundary semantic finders work with submitted boundaries" do
    # Start with no boundaries
    assert_nil @prabhag.boundary
    assert_equal false, @prabhag.has_boundary?

    # Submit a boundary
    geojson_data = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}'
    @prabhag.submit_boundary!(geojson_data, submitted_by: @user)

    # Should still have no approved boundary
    assert_nil @prabhag.approved_boundary
    assert_equal true, @prabhag.has_boundary? # has_boundary? includes pending

    # Approve the boundary (direct boundary update)
    boundary = @prabhag.boundaries.last
    boundary.update!(status: 'approved', approved_by: @admin, approved_at: Time.current)
    @prabhag.update!(status: 'approved')

    # Now should have approved boundary
    boundary = @prabhag.approved_boundary
    assert_not_nil boundary
    assert_equal 'approved', boundary.status
    assert_equal boundary, @prabhag.boundary # .boundary should return the approved one
  end
end