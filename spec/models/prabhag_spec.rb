require 'rails_helper'

RSpec.describe Prabhag, type: :model do
  describe "#computed_mapping_status" do
    let(:ward) { wards(:ward_one) }

    context "when no boundaries exist" do
      it "returns :unmapped" do
        prabhag = create(:prabhag, ward_code: ward.ward_code, ward: ward)
        expect(prabhag.computed_mapping_status).to eq(:unmapped)
      end
    end

    context "with only a KML import boundary" do
      it "returns :legacy_needs_remapping" do
        prabhag = create(:prabhag, ward_code: ward.ward_code, ward: ward)
        create(:boundary, :approved, boundable: prabhag, source_type: "kml_import", year: 2017)
        expect(prabhag.computed_mapping_status).to eq(:legacy_needs_remapping)
      end
    end

    context "with an official canonical boundary" do
      it "returns :official_canonical" do
        prabhag = create(:prabhag, ward_code: ward.ward_code, ward: ward)
        create(:boundary, boundable: prabhag, source_type: "official_import", status: "canonical", year: 2025, is_canonical: true)
        expect(prabhag.computed_mapping_status).to eq(:official_canonical)
      end
    end

    context "with an official approved boundary" do
      it "returns :official_approved" do
        prabhag = create(:prabhag, ward_code: ward.ward_code, ward: ward)
        create(:boundary, :approved, boundable: prabhag, source_type: "official_import", year: 2025)
        expect(prabhag.computed_mapping_status).to eq(:official_approved)
      end
    end

    context "with a pending user submission" do
      it "returns :pending_review" do
        prabhag = create(:prabhag, ward_code: ward.ward_code, ward: ward)
        create(:boundary, :pending, boundable: prabhag, source_type: "user_submission", year: 2025)
        expect(prabhag.computed_mapping_status).to eq(:pending_review)
      end
    end

    context "with an approved user submission" do
      it "returns :community_approved" do
        prabhag = create(:prabhag, ward_code: ward.ward_code, ward: ward)
        create(:boundary, :approved, boundable: prabhag, source_type: "user_submission", year: 2025)
        expect(prabhag.computed_mapping_status).to eq(:community_approved)
      end
    end

    context "with a rejected user submission" do
      it "returns :rejected" do
        prabhag = create(:prabhag, ward_code: ward.ward_code, ward: ward)
        create(:boundary, boundable: prabhag, source_type: "user_submission", status: "rejected", year: 2025)
        expect(prabhag.computed_mapping_status).to eq(:rejected)
      end
    end
  end

  describe "#mapping_status_badge" do
    let(:ward) { wards(:ward_one) }

    it "returns label and color for each status" do
      prabhag = create(:prabhag, ward_code: ward.ward_code, ward: ward)
      badge = prabhag.mapping_status_badge
      expect(badge).to have_key(:label)
      expect(badge).to have_key(:bg)
      expect(badge).to have_key(:text)
    end
  end
end
