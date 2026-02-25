class RefreshTweetsJob < ApplicationJob
  queue_as :default

  # Only refreshes metrics + media for last 24h tweets (~1-2 API calls)
  def perform
    TweetService.refresh_activity(scope: Tweet.where("tweeted_at > ?", 24.hours.ago))
  end
end

