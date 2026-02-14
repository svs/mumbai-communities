require 'rails_helper'

RSpec.describe "Wards::Facilities", type: :request do
  let(:ward) { wards(:ward_A) }

  before do
    Facility.create!(
      name: "Test Hospital", facility_type: "hospital", source: "osm",
      external_id: "osm_hosp_1", ward_code: "A", latitude: 18.93, longitude: 72.83
    )
    Facility.create!(
      name: "Test School", facility_type: "school", source: "osm",
      external_id: "osm_sch_1", ward_code: "A", latitude: 18.94, longitude: 72.84
    )
    Facility.create!(
      name: "BMC Hospital", facility_type: "hospital", source: "bmc_portal",
      external_id: "bmc_hosp_1", ward_code: "A", latitude: 18.93, longitude: 72.83
    )
  end

  describe "GET /wards/:ward_id/facilities" do
    it "returns success for HTML" do
      get ward_facilities_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "returns GeoJSON FeatureCollection for JSON" do
      get ward_facilities_path(ward, format: :json)
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json["type"]).to eq("FeatureCollection")
      expect(json["features"]).to be_an(Array)
      expect(json["features"].length).to eq(3)
    end

    it "includes marker properties in GeoJSON features" do
      get ward_facilities_path(ward, format: :json)
      json = JSON.parse(response.body)

      hospital_feature = json["features"].find { |f| f["properties"]["name"] == "Test Hospital" }
      expect(hospital_feature).to be_present
      expect(hospital_feature["properties"]["marker_color"]).to be_present
      expect(hospital_feature["properties"]["facility_type"]).to eq("hospital")
      expect(hospital_feature["properties"]["source_label"]).to be_present
    end

    it "allows anonymous access" do
      get ward_facilities_path(ward)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /wards/:ward_id/facilities/scorecard" do
    it "returns success" do
      get scorecard_ward_facilities_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "includes facility type counts" do
      get scorecard_ward_facilities_path(ward)
      expect(response.body).to include("Hospital")
      expect(response.body).to include("School")
    end
  end
end
