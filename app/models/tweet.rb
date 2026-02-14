class Tweet < ApplicationRecord
  belongs_to :ward

  validates :tweet_id, presence: true, uniqueness: true
  validates :body, presence: true

  scope :recent, -> { order(tweeted_at: :desc) }
  scope :original, -> { where(in_reply_to_status_id: nil) }
  scope :replies, -> { where.not(in_reply_to_status_id: nil) }
end
