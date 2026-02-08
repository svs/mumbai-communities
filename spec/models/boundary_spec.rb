require 'rails_helper'

RSpec.describe Boundary, type: :model do
  let(:user) { users(:user_one) }
  let(:ward) { wards(:ward_one) }
  let(:boundary) do
    Boundary.new(
      boundable: ward,
      geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
      source_type: 'user_submission',
      submitted_by: user
    )
  end

  describe 'validations' do
    it 'validates presence of geojson' do
      boundary.geojson = nil
      expect(boundary).not_to be_valid
      expect(boundary.errors[:geojson]).to include("can't be blank")
    end

    it 'validates presence of source_type' do
      boundary.source_type = nil
      expect(boundary).not_to be_valid
      expect(boundary.errors[:source_type]).to include("can't be blank")
    end

    it 'validates inclusion of source_type' do
      boundary.source_type = 'invalid_type'
      expect(boundary).not_to be_valid
      expect(boundary.errors[:source_type]).to include("is not included in the list")
    end

    it 'validates inclusion of status' do
      boundary.status = 'invalid_status'
      expect(boundary).not_to be_valid
      expect(boundary.errors[:status]).to include("is not included in the list")
    end

    it 'belongs to boundable' do
      boundary.boundable = nil
      expect(boundary).not_to be_valid
      expect(boundary.errors[:boundable]).to include("must exist")
    end

    it 'optionally belongs to submitted_by user' do
      boundary.submitted_by = nil
      expect(boundary).to be_valid
    end

    it 'optionally belongs to approved_by user' do
      boundary.approved_by = nil
      expect(boundary).to be_valid
    end

    it 'is valid with valid attributes' do
      expect(boundary).to be_valid
    end
  end

  describe 'defaults' do
    it 'defaults status to pending' do
      expect(boundary.status).to eq('pending')
    end

    it 'defaults is_canonical to false' do
      expect(boundary.is_canonical).to eq(false)
    end
  end

  describe '#make_canonical!' do
    it 'sets as canonical and clears others' do
      existing_canonical = Boundary.create!(
        boundable: ward,
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'official_import',
        is_canonical: true,
        status: 'canonical'
      )

      boundary.save!
      boundary.make_canonical!

      boundary.reload
      existing_canonical.reload

      expect(boundary.is_canonical?).to be true
      expect(boundary.status).to eq('canonical')
      expect(existing_canonical.is_canonical?).to be false
    end
  end

  describe '#approve!' do
    it 'sets status and approval details' do
      approver = users(:user_two)
      boundary.save!

      boundary.approve!(approver)

      expect(boundary.status).to eq('approved')
      expect(boundary.approved_by).to eq(approver)
      expect(boundary.approved_at).not_to be_nil
    end
  end

  describe '#reject!' do
    it 'sets status and rejection details' do
      approver = users(:user_two)
      reason = "Inaccurate boundary"
      boundary.save!

      boundary.reject!(approver, reason)

      expect(boundary.status).to eq('rejected')
      expect(boundary.approved_by).to eq(approver)
      expect(boundary.rejection_reason).to eq(reason)
      expect(boundary.approved_at).not_to be_nil
    end
  end

  describe '#ward?' do
    it 'returns true for Ward boundable' do
      expect(boundary.ward?).to be true
    end
  end

  describe '#prabhag?' do
    it 'returns true for Prabhag boundable' do
      prabhag = prabhags(:prabhag_one)
      prabhag_boundary = Boundary.new(
        boundable: prabhag,
        geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
        source_type: 'user_submission'
      )

      expect(prabhag_boundary.prabhag?).to be true
      expect(prabhag_boundary.ward?).to be false
    end
  end

  describe 'scopes' do
    describe '.canonical' do
      it 'returns only canonical boundaries' do
        boundary.save!
        boundary.make_canonical!

        non_canonical = Boundary.create!(
          boundable: wards(:ward_two),
          geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
          source_type: 'user_submission'
        )

        canonical_boundaries = Boundary.canonical

        expect(canonical_boundaries).to include(boundary)
        expect(canonical_boundaries).not_to include(non_canonical)
      end
    end

    describe '.for_year' do
      it 'filters by year' do
        boundary.year = 2017
        boundary.save!

        boundary_2025 = Boundary.create!(
          boundable: wards(:ward_two),
          geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
          source_type: 'kml_import',
          year: 2025
        )

        expect(Boundary.for_year(2017)).to include(boundary)
        expect(Boundary.for_year(2017)).not_to include(boundary_2025)
        expect(Boundary.for_year(2025)).to include(boundary_2025)
      end
    end

    describe '.approved' do
      it 'includes approved and canonical statuses' do
        approved_boundary = Boundary.create!(
          boundable: wards(:ward_one),
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission',
          status: 'approved'
        )

        canonical_boundary = Boundary.create!(
          boundable: wards(:ward_two),
          geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
          source_type: 'official_import',
          status: 'approved',
          is_canonical: true
        )

        pending_boundary = Boundary.create!(
          boundable: prabhags(:prabhag_one),
          geojson: '{"type":"Polygon","coordinates":[[[13,14],[15,16],[17,18],[13,14]]]}',
          source_type: 'user_submission',
          status: 'pending'
        )

        approved_boundaries = Boundary.approved

        expect(approved_boundaries).to include(approved_boundary)
        expect(approved_boundaries).to include(canonical_boundary)
        expect(approved_boundaries).not_to include(pending_boundary)
      end
    end

    describe '.rejected' do
      it 'only includes rejected boundaries' do
        rejected_boundary = Boundary.create!(
          boundable: wards(:ward_one),
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission',
          status: 'rejected'
        )

        approved_boundary = Boundary.create!(
          boundable: wards(:ward_two),
          geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
          source_type: 'user_submission',
          status: 'approved'
        )

        rejected_boundaries = Boundary.rejected

        expect(rejected_boundaries).to include(rejected_boundary)
        expect(rejected_boundaries).not_to include(approved_boundary)
      end
    end

    describe '.best' do
      it 'orders boundaries by priority' do
        rejected = Boundary.create!(
          boundable: wards(:ward_one),
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission',
          status: 'rejected'
        )

        pending = Boundary.create!(
          boundable: wards(:ward_one),
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission',
          status: 'pending'
        )

        approved = Boundary.create!(
          boundable: wards(:ward_one),
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission',
          status: 'approved'
        )

        canonical = Boundary.create!(
          boundable: wards(:ward_one),
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'official_import',
          status: 'approved',
          is_canonical: true
        )

        best_boundary = Boundary.where(boundable: wards(:ward_one)).best
        expect(best_boundary).to eq(canonical)

        all_ordered = wards(:ward_one).all_boundaries.to_a
        expect(all_ordered[0]).to eq(canonical)
        expect(all_ordered[1]).to eq(approved)
        expect(all_ordered[2]).to eq(pending)
        expect(all_ordered[3]).to eq(rejected)
      end
    end

    describe '.user_submitted' do
      it 'only includes user submissions' do
        user_boundary = Boundary.create!(
          boundable: wards(:ward_one),
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission'
        )

        imported_boundary = Boundary.create!(
          boundable: wards(:ward_two),
          geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
          source_type: 'kml_import'
        )

        user_boundaries = Boundary.user_submitted

        expect(user_boundaries).to include(user_boundary)
        expect(user_boundaries).not_to include(imported_boundary)
      end
    end

    describe '.official' do
      it 'includes imported boundaries' do
        user_boundary = Boundary.create!(
          boundable: wards(:ward_one),
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission'
        )

        kml_boundary = Boundary.create!(
          boundable: wards(:ward_one),
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'kml_import'
        )

        official_boundary = Boundary.create!(
          boundable: wards(:ward_two),
          geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
          source_type: 'official_import'
        )

        official_boundaries = Boundary.official

        expect(official_boundaries).not_to include(user_boundary)
        expect(official_boundaries).to include(kml_boundary)
        expect(official_boundaries).to include(official_boundary)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        ward = wards(:ward_one)

        old_boundary = Boundary.create!(
          boundable: ward,
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission',
          created_at: 2.days.ago
        )

        new_boundary = Boundary.create!(
          boundable: ward,
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission',
          created_at: 1.day.ago
        )

        recent_boundaries = ward.boundaries.recent

        expect(recent_boundaries.first).to eq(new_boundary)
        expect(recent_boundaries.second).to eq(old_boundary)
      end
    end
  end

  describe 'boundary approval workflow' do
    it 'optionally belongs to edited_by user' do
      boundary.edited_by = nil
      expect(boundary).to be_valid

      admin = users(:admin_2)
      boundary.edited_by = admin
      expect(boundary).to be_valid
    end

    it 'validates that edited_by is an admin when present' do
      regular_user = users(:user_one)
      admin_user = users(:admin_2)

      boundary.edited_by = regular_user
      expect(boundary).not_to be_valid
      expect(boundary.errors[:edited_by]).to include("must be an admin user")

      boundary.edited_by = admin_user
      expect(boundary).to be_valid
    end

    it 'allows nil edited_by' do
      boundary.edited_by = nil
      expect(boundary).to be_valid
      expect(boundary.errors.full_messages.join(' ')).not_to match(/edited_by/)
    end

    it 'tracks admin edits with edited_by field' do
      admin = users(:admin_2)
      new_geojson = '{"type":"Polygon","coordinates":[[[10,20],[30,40],[50,60],[10,20]]]}'
      boundary.save!

      expect(boundary.edited_by).to be_nil

      boundary.edit_by_admin!(admin, new_geojson)

      expect(boundary.edited_by).to eq(admin)
      expect(boundary.geojson).to eq(new_geojson)
    end

    it 'rejects non-admin users as edited_by' do
      regular_user = users(:user_one)
      boundary.edited_by = regular_user

      expect(boundary).not_to be_valid
      expect(boundary.errors[:edited_by]).to include("must be an admin user")
    end

    it 'accepts admin users as edited_by' do
      admin = users(:admin_2)
      boundary.edited_by = admin

      expect(boundary).to be_valid
      expect(boundary.errors[:edited_by]).to be_empty
    end

    describe '#edit_by_admin!' do
      it 'updates boundary with admin tracking' do
        admin = users(:admin_2)
        regular_user = users(:user_one)
        new_geojson = '{"type":"Polygon","coordinates":[[[100,200],[300,400],[500,600],[100,200]]]}'
        boundary.save!

        boundary.edit_by_admin!(admin, new_geojson)
        expect(boundary.edited_by).to eq(admin)
        expect(boundary.geojson).to eq(new_geojson)

        expect {
          boundary.edit_by_admin!(regular_user, new_geojson)
        }.to raise_error(ArgumentError)
      end
    end

    describe '.for_admin_review' do
      it 'returns boundaries for admin review' do
        ward = wards(:ward_one)

        pending_user_boundary = Boundary.create!(
          boundable: ward,
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission',
          status: 'pending'
        )

        approved_boundary = Boundary.create!(
          boundable: ward,
          geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
          source_type: 'user_submission',
          status: 'approved'
        )

        official_boundary = Boundary.create!(
          boundable: ward,
          geojson: '{"type":"Polygon","coordinates":[[[13,14],[15,16],[17,18],[13,14]]]}',
          source_type: 'official_import',
          status: 'pending'
        )

        review_boundaries = Boundary.for_admin_review

        expect(review_boundaries).to include(pending_user_boundary)
        expect(review_boundaries).not_to include(approved_boundary)
        expect(review_boundaries).not_to include(official_boundary)
      end

      it 'scopes boundaries pending admin review' do
        prabhag = prabhags(:prabhag_one)

        pending_user_boundary = Boundary.create!(
          boundable: prabhag,
          geojson: '{"type":"Polygon","coordinates":[[[1,2],[3,4],[5,6],[1,2]]]}',
          source_type: 'user_submission',
          status: 'pending'
        )

        rejected_boundary = Boundary.create!(
          boundable: prabhag,
          geojson: '{"type":"Polygon","coordinates":[[[7,8],[9,10],[11,12],[7,8]]]}',
          source_type: 'user_submission',
          status: 'rejected'
        )

        review_boundaries = prabhag.boundaries.for_admin_review

        expect(review_boundaries).to include(pending_user_boundary)
        expect(review_boundaries).not_to include(rejected_boundary)
      end
    end
  end
end
