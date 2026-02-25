class FetchNewTweetsJob < ApplicationJob
  queue_as :default

  # Fetches new tweets from all ward accounts (~27 API calls)
  def perform
    TweetService.refresh_all
  end
end
