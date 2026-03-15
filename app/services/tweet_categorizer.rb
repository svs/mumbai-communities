class TweetCategorizer
  MODEL = "google/gemini-2.0-flash-lite-001"

  CATEGORIES = %w[
    roads_and_footpaths
    water_and_sewerage
    solid_waste_management
    public_health
    encroachment
    transport_and_mobility
    environment
    housing_and_building
    public_safety
    utilities
    parks_and_open_spaces
    education_and_social_services
    governance_and_accountability
    disaster_and_emergency
    other
  ].freeze

  TWEET_TYPES = %w[complaint resolution appreciation information question].freeze

  PROMPT = <<~PROMPT
    Categorize each tweet about Mumbai municipal issues.

    Categories: #{CATEGORIES.join(", ")}
    Tweet types: #{TWEET_TYPES.join(", ")}

    Return a JSON array with one object per tweet, in the same order as the input:
    [{"id": <id>, "category": "<category>", "tweet_type": "<tweet_type>"}, ...]

    Tweets:
  PROMPT

  class << self
    def categorize(tweet)
      bulk_categorize(Tweet.where(id: tweet.id))
    end

    def bulk_categorize(scope = Tweet.where(category: nil))
      scope.find_in_batches(batch_size: 20) do |batch|
        categorize_batch(batch)
      end
    end

    private

    def categorize_batch(tweets)
      tweets_json = tweets.map { |t| { id: t.id, text: t.body.truncate(300) } }
      chat = RubyLLM.chat(model: MODEL, provider: :openrouter)
      response = chat.ask(PROMPT + tweets_json.to_json)

      text = response.content.gsub(/\A```json\s*/, "").gsub(/\s*```\z/, "")
      results = JSON.parse(text)
      results_by_id = results.index_by { |r| r["id"] }

      tweets.each do |tweet|
        result = results_by_id[tweet.id]
        next unless result
        tweet.update_columns(
          category: result["category"],
          tweet_type: result["tweet_type"]
        )
      end
    rescue JSON::ParserError => e
      Rails.logger.error "TweetCategorizer: Failed to parse response: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "TweetCategorizer: #{e.message}"
    end
  end
end
