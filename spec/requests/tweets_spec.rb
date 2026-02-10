require 'rails_helper'

RSpec.describe "Tweets", type: :request do
  fixtures :wards

  let(:ward) { wards(:ward_A) }
  let(:api_key) { "test-tweets-api-key" }
  let(:headers) { { "Authorization" => "Bearer #{api_key}" } }

  let(:tweets_payload) do
    [
      {
        "id" => "999000001",
        "text" => "Pothole fixed near station",
        "createdAt" => "Mon Feb 10 10:00:00 +0000 2026",
        "likeCount" => 5,
        "retweetCount" => 2,
        "replyCount" => 1,
        "author" => { "username" => "mybmcWardA", "name" => "BMC Ward A" }
      },
      {
        "id" => "999000002",
        "text" => "Water supply restored",
        "createdAt" => "Mon Feb 10 11:00:00 +0000 2026",
        "likeCount" => 3,
        "retweetCount" => 0,
        "replyCount" => 0,
        "author" => { "username" => "resident456", "name" => "Local Resident" }
      }
    ]
  end

  describe "POST /wards/:ward_id/tweets" do
    before { allow(ENV).to receive(:fetch).and_call_original }
    before { allow(ENV).to receive(:fetch).with("TWEETS_API_KEY").and_return(api_key) }

    it "imports tweets and returns count" do
      post ward_tweets_path(ward), params: { tweets: tweets_payload }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["imported"]).to eq(2)
      expect(body["tweets"].length).to eq(2)
      expect(Tweet.count).to eq(2)
    end

    it "upserts duplicate tweet_ids without creating duplicates" do
      post ward_tweets_path(ward), params: { tweets: tweets_payload }, headers: headers, as: :json
      expect(Tweet.count).to eq(2)

      post ward_tweets_path(ward), params: { tweets: tweets_payload }, headers: headers, as: :json
      expect(Tweet.count).to eq(2)

      body = JSON.parse(response.body)
      expect(body["imported"]).to eq(2)
    end

    it "returns imported 0 for empty array" do
      post ward_tweets_path(ward), params: { tweets: [] }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["imported"]).to eq(0)
      expect(body["tweets"]).to eq([])
    end

    it "returns 404 for nonexistent ward" do
      post "/wards/nonexistent-ward/tweets", params: { tweets: tweets_payload }, headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Ward not found")
    end

    it "returns 401 without API key" do
      post ward_tweets_path(ward), params: { tweets: tweets_payload }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with wrong API key" do
      post ward_tweets_path(ward), params: { tweets: tweets_payload }, headers: { "Authorization" => "Bearer wrong-key" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
