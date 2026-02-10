require 'rails_helper'

RSpec.describe TweetService, type: :service do
  fixtures :wards

  let(:ward) { wards(:ward_A) }

  let(:bird_json) do
    [
      {
        "id" => "111222333",
        "text" => "Pothole fixed on MG Road",
        "createdAt" => "Mon Feb 09 10:00:00 +0000 2026",
        "likeCount" => 3,
        "retweetCount" => 1,
        "replyCount" => 0,
        "author" => { "username" => "mybmcWardA", "name" => "BMC Ward A" }
      },
      {
        "id" => "111222334",
        "text" => "Drainage cleaning drive tomorrow",
        "createdAt" => "Mon Feb 09 08:00:00 +0000 2026",
        "likeCount" => 7,
        "retweetCount" => 2,
        "replyCount" => 5,
        "author" => { "username" => "resident123", "name" => "Local Resident" }
      }
    ].to_json
  end

  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  describe ".fetch" do
    it "parses bird JSON and creates Tweet records" do
      allow(Open3).to receive(:capture3).and_return([bird_json, "", success_status])

      tweets = TweetService.fetch(ward)

      expect(tweets.length).to eq(2)
      expect(tweets.first).to be_a(Tweet)
      expect(tweets.first).to be_persisted
      expect(tweets.first.tweet_id).to eq("111222333")
      expect(tweets.first.body).to eq("Pothole fixed on MG Road")
      expect(tweets.first.ward).to eq(ward)
    end

    it "upserts on duplicate tweet_id" do
      allow(Open3).to receive(:capture3).and_return([bird_json, "", success_status])

      TweetService.fetch(ward)
      expect { TweetService.fetch(ward) }.not_to change(Tweet, :count)
    end

    it "returns empty array when ward has no twitter_handle" do
      ward_no_handle = wards(:ward_B)
      expect(ward_no_handle.twitter_handle).to be_blank

      tweets = TweetService.fetch(ward_no_handle)
      expect(tweets).to eq([])
    end

    it "returns empty array on bird failure" do
      allow(Open3).to receive(:capture3).and_return(["", "command not found", failure_status])

      tweets = TweetService.fetch(ward)
      expect(tweets).to eq([])
    end

    it "returns empty array on invalid JSON" do
      allow(Open3).to receive(:capture3).and_return(["not json at all", "", success_status])

      tweets = TweetService.fetch(ward)
      expect(tweets).to eq([])
    end
  end
end
