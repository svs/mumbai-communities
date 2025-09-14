require 'test_helper'

class WardBoundaryFindersTest < ActiveSupport::TestCase
  def setup
    @ward = wards(:ward_one)
  end

  test "boundary should return the best available boundary" do
    # Create boundaries in different states
    rejected = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'rejected'
    )

    pending = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'pending'
    )

    approved = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'approved'
    )

    # The approved boundary should be returned as the best
    assert_equal approved, @ward.boundary
  end

  test "boundary should return canonical boundary when available" do
    approved = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'approved'
    )

    canonical = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
      source_type: 'official_import',
      status: 'canonical',
      is_canonical: true
    )

    # Canonical should be returned as the best
    assert_equal canonical, @ward.boundary
  end

  test "boundary should return nil when no boundaries exist" do
    assert_nil @ward.boundary
  end

  test "approved_boundary should return approved or canonical boundary" do
    pending = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'pending'
    )

    approved = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
      source_type: 'user_submission',
      status: 'approved'
    )

    assert_equal approved, @ward.approved_boundary
  end

  test "approved_boundary should prioritize more recent boundaries" do
    old_approved = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'approved',
      created_at: 2.days.ago
    )

    new_approved = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
      source_type: 'user_submission',
      status: 'approved',
      created_at: 1.day.ago
    )

    assert_equal new_approved, @ward.approved_boundary
  end

  test "approved_boundary should return nil when no approved boundaries exist" do
    @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'pending'
    )

    assert_nil @ward.approved_boundary
  end

  test "canonical_boundary should return only canonical boundary" do
    approved = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'approved'
    )

    canonical = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
      source_type: 'official_import',
      status: 'canonical',
      is_canonical: true
    )

    assert_equal canonical, @ward.canonical_boundary
  end

  test "canonical_boundary should return nil when no canonical boundary exists" do
    @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'approved'
    )

    assert_nil @ward.canonical_boundary
  end

  test "latest_user_boundary should return most recent user submission" do
    old_user = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'pending',
      created_at: 2.days.ago
    )

    kml_import = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[5,6],[7,8],[9,10],[5,6]]]}',
      source_type: 'kml_import',
      status: 'approved',
      created_at: 1.day.ago
    )

    new_user = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
      source_type: 'user_submission',
      status: 'approved',
      created_at: 1.hour.ago
    )

    assert_equal new_user, @ward.latest_user_boundary
  end

  test "latest_user_boundary should return nil when no user submissions exist" do
    @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'kml_import',
      status: 'approved'
    )

    assert_nil @ward.latest_user_boundary
  end

  test "all_boundaries should return all boundaries ordered by best first" do
    rejected = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'rejected'
    )

    approved = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
      source_type: 'user_submission',
      status: 'approved'
    )

    canonical = @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[13,14],[15,16],[17,18],[13,14]]]}',
      source_type: 'official_import',
      status: 'canonical',
      is_canonical: true
    )

    all = @ward.all_boundaries.to_a

    assert_equal 3, all.length
    assert_equal canonical, all[0]
    assert_equal approved, all[1]
    assert_equal rejected, all[2]
  end

  test "has_boundary? should return true when boundaries exist" do
    @ward.boundaries.create!(
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      status: 'pending'
    )

    assert @ward.has_boundary?
  end

  test "has_boundary? should return false when no boundaries exist" do
    refute @ward.has_boundary?
  end
end