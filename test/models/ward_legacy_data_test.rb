require "test_helper"

class WardLegacyDataTest < ActiveSupport::TestCase
  def setup
    @ward = wards(:ward_a)
  end

  test "completion_percentage should be 0 when prabhags have 2025 canonical boundaries" do
    # Create prabhags with 2025 canonical boundaries
    prabhag1 = @ward.prabhags.create!(
      number: 101,
      name: "Test Prabhag 101",
      pdf_url: "http://example.com/101.pdf",
      status: "approved"
    )

    prabhag2 = @ward.prabhags.create!(
      number: 102,
      name: "Test Prabhag 102",
      pdf_url: "http://example.com/102.pdf",
      status: "approved"
    )

    # Add 2025 canonical boundaries
    prabhag1.boundaries.create!(
      geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}',
      source_type: 'official_import',
      year: 2025,
      status: 'canonical',
      is_canonical: true
    )

    prabhag2.boundaries.create!(
      geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}',
      source_type: 'official_import',
      year: 2025,
      status: 'canonical',
      is_canonical: true
    )

    assert_equal 0.0, @ward.completion_percentage
  end

  test "completion_percentage should be 100 when all prabhags have 2017 boundaries as best" do
    # Create prabhags with 2017 boundaries only
    prabhag1 = @ward.prabhags.create!(
      number: 103,
      name: "Test Prabhag 103",
      pdf_url: "http://example.com/103.pdf",
      status: "approved"
    )

    prabhag2 = @ward.prabhags.create!(
      number: 104,
      name: "Test Prabhag 104",
      pdf_url: "http://example.com/104.pdf",
      status: "approved"
    )

    # Add 2017 approved boundaries (these will be the best/only boundaries)
    prabhag1.boundaries.create!(
      geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}',
      source_type: 'kml_import',
      year: 2017,
      status: 'approved',
      is_canonical: false
    )

    prabhag2.boundaries.create!(
      geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}',
      source_type: 'kml_import',
      year: 2017,
      status: 'approved',
      is_canonical: false
    )

    assert_equal 100.0, @ward.completion_percentage
  end

  test "completion_percentage should be 50 when half the prabhags have 2017 as best boundary" do
    # Create 4 prabhags
    4.times do |i|
      @ward.prabhags.create!(
        number: 105 + i,
        name: "Test Prabhag #{105 + i}",
        pdf_url: "http://example.com/#{105 + i}.pdf",
        status: "approved"
      )
    end

    prabhags = @ward.prabhags.order(:number)

    # First 2 prabhags get 2025 canonical boundaries
    prabhags.first(2).each do |prabhag|
      prabhag.boundaries.create!(
        geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}',
        source_type: 'official_import',
        year: 2025,
        status: 'canonical',
        is_canonical: true
      )
    end

    # Last 2 prabhags get 2017 approved boundaries
    prabhags.last(2).each do |prabhag|
      prabhag.boundaries.create!(
        geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}',
        source_type: 'kml_import',
        year: 2017,
        status: 'approved',
        is_canonical: false
      )
    end

    assert_equal 50.0, @ward.completion_percentage
  end

  test "completion_percentage prioritizes canonical over approved even when both are 2017" do
    # Create prabhag with both 2017 approved and 2017 canonical boundaries
    prabhag = @ward.prabhags.create!(
      number: 109,
      name: "Test Prabhag 109",
      pdf_url: "http://example.com/109.pdf",
      status: "approved"
    )

    # Add 2017 approved boundary first
    prabhag.boundaries.create!(
      geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}',
      source_type: 'kml_import',
      year: 2017,
      status: 'approved',
      is_canonical: false
    )

    # Add 2017 canonical boundary (should be chosen by .best scope)
    prabhag.boundaries.create!(
      geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[1,1],[2,1],[2,2],[1,2],[1,1]]]}}',
      source_type: 'official_import',
      year: 2017,
      status: 'canonical',
      is_canonical: true
    )

    # The best boundary should be the canonical one
    best_boundary = prabhag.boundary
    assert_equal 'canonical', best_boundary.status
    assert_equal 2017, best_boundary.year

    # Since best boundary is 2017, should count as legacy
    assert_equal 100.0, @ward.completion_percentage
  end
end