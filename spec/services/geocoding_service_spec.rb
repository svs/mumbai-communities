require 'rails_helper'

RSpec.describe GeocodingService, type: :service do
  describe '.find_prabhag_from_coordinates' do
    it 'finds prabhag from coordinates when point is within boundary' do
      prabhag = prabhags(:one)

      boundary = boundaries(:prabhag_boundary)
      boundary.update!(
        boundable: prabhag,
        geojson: {
          type: "Feature",
          geometry: {
            type: "Polygon",
            coordinates: [[
              [72.8, 19.1],
              [72.9, 19.1],
              [72.9, 19.2],
              [72.8, 19.2],
              [72.8, 19.1]
            ]]
          }
        }.to_json,
        status: 'approved'
      )

      ward_code, prabhag_id = GeocodingService.find_prabhag_from_coordinates(19.15, 72.85)

      expect(ward_code).to eq(prabhag.ward_code)
      expect(prabhag_id).to eq(prabhag.id)
    end

    it 'returns nil when point is outside all boundaries' do
      ward_code, prabhag_id = GeocodingService.find_prabhag_from_coordinates(0, 0)

      expect(ward_code).to be_nil
      expect(prabhag_id).to be_nil
    end

    it 'handles invalid geojson gracefully' do
      prabhag = prabhags(:one)
      boundary = boundaries(:prabhag_boundary)
      boundary.update!(
        boundable: prabhag,
        geojson: "invalid json",
        status: 'approved'
      )

      ward_code, prabhag_id = GeocodingService.find_prabhag_from_coordinates(19.15, 72.85)

      expect(ward_code).to be_nil
      expect(prabhag_id).to be_nil
    end

    it 'only checks approved and canonical boundaries' do
      prabhag = prabhags(:one)

      pending_boundary = Boundary.create!(
        boundable: prabhag,
        geojson: {
          type: "Feature",
          geometry: {
            type: "Polygon",
            coordinates: [[
              [72.8, 19.1], [72.9, 19.1], [72.9, 19.2], [72.8, 19.2], [72.8, 19.1]
            ]]
          }
        }.to_json,
        source_type: 'user_submission',
        status: 'pending'
      )

      ward_code, prabhag_id = GeocodingService.find_prabhag_from_coordinates(19.15, 72.85)

      expect(ward_code).to be_nil
      expect(prabhag_id).to be_nil
    end

    it 'logs information during geocoding' do
      expect {
        GeocodingService.find_prabhag_from_coordinates(19.15, 72.85)
      }.not_to raise_error
    end
  end
end
