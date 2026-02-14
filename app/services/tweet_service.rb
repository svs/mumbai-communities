require 'open3'
require 'json'

class TweetService
  class << self
    def fetch(ward, count: 10)
      return [] if ward.twitter_handle.blank?

      stdout, stderr, status = Open3.capture3(
        "bird", "search", "@#{ward.twitter_handle}", "--json", "-n", count.to_s, "--plain"
      )

      unless status.success?
        Rails.logger.error "TweetService: bird CLI failed for @#{ward.twitter_handle}: #{stderr}"
        return []
      end

      tweets_data = JSON.parse(stdout)
      import(ward, tweets_data)
    rescue JSON::ParserError => e
      Rails.logger.error "TweetService: Failed to parse bird output: #{e.message}"
      []
    rescue StandardError => e
      Rails.logger.error "TweetService: #{e.message}"
      []
    end

    def refresh_all
      Ward.where.not(twitter_handle: [nil, ""]).find_each do |ward|
        fetch(ward)
      end
    end

    def import(ward, tweets_data)
      Array(tweets_data).filter_map do |data|
        id = data["id"]&.to_s
        next if id.blank?

        tweet = Tweet.find_or_initialize_by(tweet_id: id)
        author = data["author"] || {}
        tweet.assign_attributes(
          ward: ward,
          body: data["text"] || "",
          author_username: author["username"],
          author_name: author["name"],
          tweeted_at: parse_time(data["createdAt"]),
          like_count: data["likeCount"].to_i,
          retweet_count: data["retweetCount"].to_i,
          reply_count: data["replyCount"].to_i,
          in_reply_to_status_id: data["inReplyToStatusId"]&.to_s
        )
        tweet.save!
        tweet
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "TweetService: Failed to save tweet #{id}: #{e.message}"
        nil
      end
    end

    def parse_time(value)
      return nil if value.blank?
      Time.parse(value)
    rescue ArgumentError
      nil
    end
  end
end
