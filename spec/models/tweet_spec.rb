require 'rails_helper'

RSpec.describe Tweet, type: :model do
  fixtures :wards

  let(:ward) { wards(:ward_A) }

  describe "validations" do
    it "validates tweet_id uniqueness" do
      Tweet.create!(tweet_id: "123", ward: ward, body: "first tweet")
      duplicate = Tweet.new(tweet_id: "123", ward: ward, body: "dupe")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:tweet_id]).to include("has already been taken")
    end

    it "validates body presence" do
      tweet = Tweet.new(tweet_id: "999", ward: ward, body: nil)
      expect(tweet).not_to be_valid
      expect(tweet.errors[:body]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to ward" do
      tweet = Tweet.create!(tweet_id: "456", ward: ward, body: "hello", tweeted_at: Time.current)
      expect(tweet.ward).to eq(ward)
    end
  end

  describe ".recent" do
    it "orders by tweeted_at desc" do
      older = Tweet.create!(tweet_id: "1", ward: ward, body: "old", tweeted_at: 2.days.ago)
      newer = Tweet.create!(tweet_id: "2", ward: ward, body: "new", tweeted_at: 1.hour.ago)

      expect(Tweet.recent.first).to eq(newer)
      expect(Tweet.recent.last).to eq(older)
    end
  end
end
