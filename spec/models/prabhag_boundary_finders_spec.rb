require 'rails_helper'

RSpec.describe 'Prabhag Boundary Finders', type: :model do
  let(:prabhag) { prabhags(:prabhag_one) }

  describe '#boundary' do
    it 'returns the best available boundary' do
      rejected = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'rejected'
      )

      pending = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'pending'
      )

      approved = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      expect(prabhag.boundary).to eq(approved)
    end

    it 'returns canonical boundary when available' do
      approved = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      canonical = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'official_import',
        status: 'canonical',
        is_canonical: true
      )

      expect(prabhag.boundary).to eq(canonical)
    end

    it 'returns nil when no boundaries exist' do
      expect(prabhag.boundary).to be_nil
    end
  end

  describe '#approved_boundary' do
    it 'returns approved or canonical boundary' do
      pending = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'pending'
      )

      approved = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      expect(prabhag.approved_boundary).to eq(approved)
    end

    it 'prioritizes more recent boundaries' do
      old_approved = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'approved',
        created_at: 2.days.ago
      )

      new_approved = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'user_submission',
        status: 'approved',
        created_at: 1.day.ago
      )

      expect(prabhag.approved_boundary).to eq(new_approved)
    end

    it 'returns nil when no approved boundaries exist' do
      prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'pending'
      )

      expect(prabhag.approved_boundary).to be_nil
    end
  end

  describe '#canonical_boundary' do
    it 'returns only canonical boundary' do
      approved = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      canonical = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'official_import',
        status: 'canonical',
        is_canonical: true
      )

      expect(prabhag.canonical_boundary).to eq(canonical)
    end

    it 'returns nil when no canonical boundary exists' do
      prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      expect(prabhag.canonical_boundary).to be_nil
    end
  end

  describe '#latest_user_boundary' do
    it 'returns most recent user submission' do
      old_user = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'pending',
        created_at: 2.days.ago
      )

      kml_import = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[5,6],[7,8],[9,10],[5,6]]]}',
        source_type: 'kml_import',
        status: 'approved',
        created_at: 1.day.ago
      )

      new_user = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'user_submission',
        status: 'approved',
        created_at: 1.hour.ago
      )

      expect(prabhag.latest_user_boundary).to eq(new_user)
    end

    it 'returns nil when no user submissions exist' do
      prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'kml_import',
        status: 'approved'
      )

      expect(prabhag.latest_user_boundary).to be_nil
    end
  end

  describe '#all_boundaries' do
    it 'returns all boundaries ordered by best first' do
      rejected = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'rejected'
      )

      approved = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
        source_type: 'user_submission',
        status: 'approved'
      )

      canonical = prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[13,14],[15,16],[17,18],[13,14]]]}',
        source_type: 'official_import',
        status: 'canonical',
        is_canonical: true
      )

      all = prabhag.all_boundaries.to_a

      expect(all.length).to eq(3)
      expect(all[0]).to eq(canonical)
      expect(all[1]).to eq(approved)
      expect(all[2]).to eq(rejected)
    end
  end

  describe '#has_boundary?' do
    it 'returns true when boundaries exist' do
      prabhag.boundaries.create!(
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission',
        status: 'pending'
      )

      expect(prabhag.has_boundary?).to be true
    end

    it 'returns false when no boundaries exist' do
      expect(prabhag.has_boundary?).to be false
    end
  end
end
