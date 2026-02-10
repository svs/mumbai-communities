require 'rails_helper'

RSpec.describe "Wards", type: :request do
  fixtures :users, :wards, :prabhags, :boundaries

  let(:user) { users(:user_one) }
  let(:ward) { wards(:ward_A) }

  describe "GET /wards" do
    it "gets index" do
      get wards_path
      expect(response).to have_http_status(:success)
    end

    it "allows anonymous access" do
      get wards_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /wards/:id" do
    it "gets show" do
      get ward_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "gets show as JSON without errors" do
      get ward_path(ward), headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('features')
      expect(json_response['features']).to be_an(Array)
    end

    it "allows anonymous access" do
      get ward_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "displays tweets in the newspaper view" do
      Tweet.create!(tweet_id: "req_test_1", ward: ward, body: "Water pipeline repair in Colaba", author_username: "mybmcWardA", author_name: "BMC Ward A", tweeted_at: 1.hour.ago)
      get ward_path(ward)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Water pipeline repair in Colaba")
      expect(response.body).to include("From the Community")
    end
  end
end
