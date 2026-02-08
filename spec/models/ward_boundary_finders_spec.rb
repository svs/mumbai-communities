require 'rails_helper'

RSpec.describe 'Ward Boundary Finders', type: :model do
  let(:ward) { wards(:ward_one) }

  describe '#boundary' do
    it 'returns the best available boundary' do
      rejected = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'rejected'
      )

      pending = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'pending'
      )

      approved = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      expect(ward.boundary).to eq(approved)
    end

    it 'returns canonical boundary when available' do
      approved = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      canonical = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'official_import',
        status: 'canonical',
        is_canonical: true
      )

      expect(ward.boundary).to eq(canonical)
    end

    it 'returns nil when no boundaries exist' do
      expect(ward.boundary).to be_nil
    end
  end

  describe '#approved_boundary' do
    it 'returns approved or canonical boundary' do
      pending = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'pending'
      )

      approved = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      expect(ward.approved_boundary).to eq(approved)
    end

    it 'prioritizes more recent boundaries' do
      old_approved = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'approved',
        created_at: 2.days.ago
      )

      new_approved = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'user_submission',
        status: 'approved',
        created_at: 1.day.ago
      )

      expect(ward.approved_boundary).to eq(new_approved)
    end

    it 'returns nil when no approved boundaries exist' do
      ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'pending'
      )

      expect(ward.approved_boundary).to be_nil
    end
  end

  describe '#canonical_boundary' do
    it 'returns only canonical boundary' do
      approved = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      canonical = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'official_import',
        status: 'canonical',
        is_canonical: true
      )

      expect(ward.canonical_boundary).to eq(canonical)
    end

    it 'returns nil when no canonical boundary exists' do
      ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      expect(ward.canonical_boundary).to be_nil
    end
  end

  describe '#latest_user_boundary' do
    it 'returns most recent user submission' do
      old_user = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'pending',
        created_at: 2.days.ago
      )

      kml_import = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[5,6],[7,8],[9,10],[5,6]]]}',
        source_type: 'kml_import',
        status: 'approved',
        created_at: 1.day.ago
      )

      new_user = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'user_submission',
        status: 'approved',
        created_at: 1.hour.ago
      )

      expect(ward.latest_user_boundary).to eq(new_user)
    end

    it 'returns nil when no user submissions exist' do
      ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'kml_import',
        status: 'approved'
      )

      expect(ward.latest_user_boundary).to be_nil
    end
  end

  describe '#all_boundaries' do
    it 'returns all boundaries ordered by best first' do
      rejected = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'rejected'
      )

      approved = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      canonical = ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[13,14],[15,16],[17,18],[13,14]]]}',
        source_type: 'official_import',
        status: 'canonical',
        is_canonical: true
      )

      all = ward.all_boundaries.to_a

      expect(all.length).to eq(3)
      expect(all[0]).to eq(canonical)
      expect(all[1]).to eq(approved)
      expect(all[2]).to eq(rejected)
    end
  end

  describe '#has_boundary?' do
    it 'returns true when boundaries exist' do
      ward.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'pending'
      )

      expect(ward.has_boundary?).to be true
    end

    it 'returns false when no boundaries exist' do
      expect(ward.has_boundary?).to be false
    end
  end
end
