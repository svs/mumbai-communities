require 'json'
require 'net/http'

class TweetService
  TWEET_URL_PATTERN = %r{\Ahttps?://(twitter\.com|x\.com)/\w+/status/(\d+)}
  API_BASE = "https://api.x.com/2"
  TWEET_FIELDS = "created_at,author_id,public_metrics,in_reply_to_user_id,attachments"
  EXPANSIONS = "author_id,attachments.media_keys"
  MEDIA_FIELDS = "url,preview_image_url,type"
  USER_FIELDS = "username,name"

  class << self
    def import_from_url(ward, url)
      match = url.match(TWEET_URL_PATTERN)
      raise ArgumentError, "Invalid tweet URL" unless match

      tweet_id = match[2]
      oembed_uri = URI("https://publish.twitter.com/oembed?url=#{CGI.escape(url)}")
      response = Net::HTTP.get_response(oembed_uri)
      raise "Failed to fetch tweet (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      text = data["html"]&.gsub(/<[^>]+>/, "")&.strip&.truncate(500) || ""
      username = data["author_url"]&.split("/")&.last

      tweet_data = [{
        "id" => tweet_id,
        "text" => text,
        "author" => { "username" => username, "name" => data["author_name"] }
      }]
      import(ward, tweet_data).first
    end

    def fetch(ward, count: 10)
      return [] if ward.twitter_handle.blank?

      query = "from:#{ward.twitter_handle}"
      uri = URI("#{API_BASE}/tweets/search/recent?query=#{CGI.escape(query)}&max_results=#{count}&tweet.fields=#{TWEET_FIELDS}&expansions=#{EXPANSIONS}&media.fields=#{MEDIA_FIELDS}&user.fields=#{USER_FIELDS}")

      response = api_get(uri)
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error "TweetService: X API failed for @#{ward.twitter_handle}: #{response.code} #{response.body}"
        return []
      end

      payload = JSON.parse(response.body)
      return [] unless payload["data"]

      users = (payload.dig("includes", "users") || []).index_by { |u| u["id"] }
      media = (payload.dig("includes", "media") || []).index_by { |m| m["media_key"] }

      tweets_data = payload["data"].map do |tweet|
        author = users[tweet["author_id"]] || {}
        media_keys = tweet.dig("attachments", "media_keys") || []
        media_urls = media_keys.filter_map { |k| media[k]&.slice("url", "preview_image_url", "type") }
        metrics = tweet["public_metrics"] || {}

        {
          "id" => tweet["id"],
          "text" => tweet["text"],
          "createdAt" => tweet["created_at"],
          "author" => { "username" => author["username"], "name" => author["name"] },
          "likeCount" => metrics["like_count"],
          "retweetCount" => metrics["retweet_count"],
          "replyCount" => metrics["reply_count"],
          "inReplyToUserId" => tweet["in_reply_to_user_id"],
          "mediaUrls" => media_urls
        }
      end

      import(ward, tweets_data)
    rescue JSON::ParserError => e
      Rails.logger.error "TweetService: Failed to parse X API response: #{e.message}"
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
          in_reply_to_status_id: data["inReplyToUserId"]&.to_s
        )
        tweet.save!
        tweet
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "TweetService: Failed to save tweet #{id}: #{e.message}"
        nil
      end
    end

    private

    def bearer_token
      Rails.application.credentials.dig(:x, :bearer_token)
    end

    def api_get(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{bearer_token}"
      http.request(request)
    end

    def parse_time(value)
      return nil if value.blank?
      Time.parse(value)
    rescue ArgumentError
      nil
    end
  end
end
