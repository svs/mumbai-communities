class Tweet < ApplicationRecord
  belongs_to :ward
  belongs_to :parent_tweet, class_name: "Tweet", optional: true, foreign_key: :in_reply_to_status_id, primary_key: :tweet_id
  has_many :replies, class_name: "Tweet", foreign_key: :in_reply_to_status_id, primary_key: :tweet_id
  has_many :issues

  validates :tweet_id, presence: true, uniqueness: true
  validates :body, presence: true

  scope :recent, -> { order(tweeted_at: :desc) }
  scope :original, -> { where(in_reply_to_status_id: nil).where.not("body LIKE 'RT @%'") }
  scope :from_ward_account, -> { joins(:ward).where("tweets.author_username = wards.twitter_handle") }
  scope :replies_only, -> { where.not(in_reply_to_status_id: nil) }
end
