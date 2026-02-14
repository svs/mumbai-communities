require 'rails_helper'

RSpec.describe "Wards::Changes", type: :request do
  let(:ward) { wards(:ward_A) }

  describe "GET /wards/:ward_id/changes" do
    it "returns success" do
      get ward_changes_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "allows anonymous access" do
      get ward_changes_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "shows recently imported facilities" do
      Facility.create!(
        name: "New Hospital", facility_type: "hospital", source: "osm",
        external_id: "osm_new_1", ward_code: "A", latitude: 18.93, longitude: 72.83,
        last_seen_at: 1.hour.ago
      )
      get ward_changes_path(ward)
      expect(response.body).to include("New Hospital")
    end
  end
end
