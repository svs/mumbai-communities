require 'rails_helper'

RSpec.describe TweetService, type: :service do
  fixtures :wards

  let(:ward) { wards(:ward_A) }

  let(:api_response) do
    {
      "data" => [
        {
          "id" => "111222333",
          "text" => "Pothole fixed on MG Road",
          "created_at" => "2026-02-09T10:00:00.000Z",
          "author_id" => "999",
          "public_metrics" => { "like_count" => 3, "retweet_count" => 1, "reply_count" => 0 }
        },
        {
          "id" => "111222334",
          "text" => "Drainage cleaning drive tomorrow",
          "created_at" => "2026-02-09T08:00:00.000Z",
          "author_id" => "888",
          "public_metrics" => { "like_count" => 7, "retweet_count" => 2, "reply_count" => 5 },
          "referenced_tweets" => [{ "type" => "replied_to", "id" => "111222300" }]
        }
      ],
      "includes" => {
        "users" => [
          { "id" => "999", "username" => "mybmcWardA", "name" => "BMC Ward A" },
          { "id" => "888", "username" => "resident123", "name" => "Local Resident" }
        ],
        "tweets" => [
          {
            "id" => "111222300",
            "text" => "Please fix the drainage on my street",
            "created_at" => "2026-02-08T12:00:00.000Z",
            "author_id" => "777"
          }
        ]
      }
    }
  end

  let(:http_success) { instance_double(Net::HTTPSuccess, is_a?: true, body: api_response.to_json) }
  let(:http_failure) { instance_double(Net::HTTPServiceUnavailable, is_a?: false, code: "503", body: "Service Unavailable") }

  before do
    allow(http_success).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    allow(http_failure).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
  end

  describe ".fetch" do
    it "parses API response and creates Tweet records" do
      allow(TweetService).to receive(:api_get).and_return(http_success)

      tweets = TweetService.fetch(ward)

      expect(tweets.length).to eq(2)
      expect(tweets.first).to be_a(Tweet)
      expect(tweets.first).to be_persisted
      expect(tweets.first.tweet_id).to eq("111222333")
      expect(tweets.first.body).to eq("Pothole fixed on MG Road")
      expect(tweets.first.ward).to eq(ward)
    end

    it "imports parent tweets from referenced_tweets" do
      allow(TweetService).to receive(:api_get).and_return(http_success)

      TweetService.fetch(ward)

      parent = Tweet.find_by(tweet_id: "111222300")
      expect(parent).to be_present
      expect(parent.body).to eq("Please fix the drainage on my street")

      reply = Tweet.find_by(tweet_id: "111222334")
      expect(reply.in_reply_to_status_id).to eq("111222300")
      expect(reply.parent_tweet).to eq(parent)
    end

    it "upserts on duplicate tweet_id" do
      allow(TweetService).to receive(:api_get).and_return(http_success)

      TweetService.fetch(ward)
      expect { TweetService.fetch(ward) }.not_to change(Tweet, :count)
    end

    it "returns empty array when ward has no twitter_handle" do
      ward_no_handle = wards(:ward_B)
      expect(ward_no_handle.twitter_handle).to be_blank

      tweets = TweetService.fetch(ward_no_handle)
      expect(tweets).to eq([])
    end

    it "returns empty array on API failure" do
      allow(TweetService).to receive(:api_get).and_return(http_failure)

      tweets = TweetService.fetch(ward)
      expect(tweets).to eq([])
    end
  end

  describe ".import" do
    it "stores conversation_id and in_reply_to_status_id" do
      tweets_data = [
        {
          "id" => "555",
          "text" => "Test reply",
          "author" => { "username" => "test", "name" => "Test" },
          "inReplyToStatusId" => "444",
          "conversationId" => "444"
        }
      ]

      result = TweetService.import(ward, tweets_data)
      tweet = result.first

      expect(tweet.in_reply_to_status_id).to eq("444")
      expect(tweet.conversation_id).to eq("444")
    end
  end
end
