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

  describe "GET /wards/:ward_id/tweets/:id" do
    let!(:complaint) do
      Tweet.create!(tweet_id: "100", body: "Pothole on main road", ward: ward,
                    author_username: "citizen1", author_name: "Citizen One",
                    tweeted_at: 2.hours.ago)
    end

    let!(:reply) do
      Tweet.create!(tweet_id: "101", body: "We are looking into it", ward: ward,
                    author_username: "mybmcWardA", author_name: "BMC Ward A",
                    in_reply_to_status_id: "100", tweeted_at: 1.hour.ago)
    end

    it "renders the tweet detail page" do
      get ward_tweet_path(ward, complaint)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pothole on main road")
    end

    it "shows replies to the tweet" do
      get ward_tweet_path(ward, complaint)
      expect(response.body).to include("We are looking into it")
    end

    it "shows parent tweet when viewing a reply" do
      get ward_tweet_path(ward, reply)
      expect(response.body).to include("Pothole on main road")
      expect(response.body).to include("We are looking into it")
    end

    it "includes a link to view on X" do
      get ward_tweet_path(ward, complaint)
      expect(response.body).to include("x.com/citizen1/status/100")
    end

    it "is publicly accessible without login" do
      get ward_tweet_path(ward, complaint)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "User tweet URL submission" do
    let(:user) { users(:user_one) }
    let(:tweet_url) { "https://x.com/mybmcWardA/status/1234567890" }

    let(:oembed_response) do
      {
        "author_name" => "BMC Ward A",
        "author_url" => "https://twitter.com/mybmcWardA",
        "html" => '<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Pothole fixed near station road</p></blockquote>'
      }.to_json
    end

    describe "GET /wards/:ward_id/tweets/new" do
      it "renders the form when logged in" do
        sign_in user
        get new_ward_tweet_path(ward)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("tweet_url")
      end

      it "redirects to sign in when not logged in" do
        get new_ward_tweet_path(ward)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe "POST /wards/:ward_id/tweets with tweet_url" do
      it "creates a tweet from a valid URL when logged in" do
        sign_in user
        allow(TweetService).to receive(:import_from_url) {
          Tweet.create!(tweet_id: "1234567890", body: "Pothole fixed near station road", ward: ward)
        }

        expect {
          post ward_tweets_path(ward), params: { tweet_url: tweet_url }
        }.to change(Tweet, :count).by(1)

        expect(response).to redirect_to(news_ward_path(ward))
        follow_redirect!
        expect(response.body).to include("Tweet submitted")
      end

      it "rejects an invalid URL" do
        sign_in user
        post ward_tweets_path(ward), params: { tweet_url: "https://example.com/not-a-tweet" }

        expect(response).to redirect_to(news_ward_path(ward))
        follow_redirect!
        expect(response.body).to include("Invalid tweet URL")
        expect(Tweet.count).to eq(0)
      end

      it "redirects to sign in when not logged in" do
        post ward_tweets_path(ward), params: { tweet_url: tweet_url }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
