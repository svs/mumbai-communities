require 'rails_helper'

RSpec.describe 'Ward Legacy Data', type: :model do
  let(:ward) { wards(:ward_a) }

  describe '#completion_percentage' do
    it 'is 0 when prabhags have 2025 canonical boundaries' do
      prabhag1 = ward.prabhags.create!(
        number: 101,
        name: "Test Prabhag 101",
        pdf_url: "http://example.com/101.pdf",
        status: "approved"
      )

      prabhag2 = ward.prabhags.create!(
        number: 102,
        name: "Test Prabhag 102",
        pdf_url: "http://example.com/102.pdf",
        status: "approved"
      )

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

      expect(ward.completion_percentage).to eq(0.0)
    end

    it 'is 100 when all prabhags have 2017 boundaries as best' do
      prabhag1 = ward.prabhags.create!(
        number: 103,
        name: "Test Prabhag 103",
        pdf_url: "http://example.com/103.pdf",
        status: "approved"
      )

      prabhag2 = ward.prabhags.create!(
        number: 104,
        name: "Test Prabhag 104",
        pdf_url: "http://example.com/104.pdf",
        status: "approved"
      )

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

      expect(ward.completion_percentage).to eq(100.0)
    end

    it 'is 50 when half the prabhags have 2017 as best boundary' do
      4.times do |i|
        ward.prabhags.create!(
          number: 105 + i,
          name: "Test Prabhag #{105 + i}",
          pdf_url: "http://example.com/#{105 + i}.pdf",
          status: "approved"
        )
      end

      prabhags = ward.prabhags.order(:number)

      prabhags.first(2).each do |prabhag|
        prabhag.boundaries.create!(
          geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}',
          source_type: 'official_import',
          year: 2025,
          status: 'canonical',
          is_canonical: true
        )
      end

      prabhags.last(2).each do |prabhag|
        prabhag.boundaries.create!(
          geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}',
          source_type: 'kml_import',
          year: 2017,
          status: 'approved',
          is_canonical: false
        )
      end

      expect(ward.completion_percentage).to eq(50.0)
    end

    it 'prioritizes canonical over approved even when both are 2017' do
      prabhag = ward.prabhags.create!(
        number: 109,
        name: "Test Prabhag 109",
        pdf_url: "http://example.com/109.pdf",
        status: "approved"
      )

      prabhag.boundaries.create!(
        geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}',
        source_type: 'kml_import',
        year: 2017,
        status: 'approved',
        is_canonical: false
      )

      prabhag.boundaries.create!(
        geojson: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[1,1],[2,1],[2,2],[1,2],[1,1]]]}}',
        source_type: 'official_import',
        year: 2017,
        status: 'canonical',
        is_canonical: true
      )

      best_boundary = prabhag.boundary
      expect(best_boundary.status).to eq('canonical')
      expect(best_boundary.year).to eq(2017)

      expect(ward.completion_percentage).to eq(100.0)
    end
  end
end
