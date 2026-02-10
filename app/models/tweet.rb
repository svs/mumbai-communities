class Tweet < ApplicationRecord
  belongs_to :ward

  validates :tweet_id, presence: true, uniqueness: true
  validates :body, presence: true

  scope :recent, -> { order(tweeted_at: :desc) }
end
