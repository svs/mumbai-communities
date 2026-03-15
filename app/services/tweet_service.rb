require 'json'
require 'net/http'

class TweetService
  TWEET_URL_PATTERN = %r{\Ahttps?://(twitter\.com|x\.com)/\w+/status/(\d+)}
  API_BASE = "https://api.x.com/2"

  # City-wide handles — tweets mentioning these get assigned to a ward
  # only if they also co-mention a ward handle
  CITYWIDE_HANDLES = %w[
    mybmc
    mybmcInfra
    mybmcSWM
    mybmcHealth
    mybmcHealthDept
    MumbaiPolice
    MTPHereToHelp
    CPMumbaiPolice
    MMRDAOfficial
    mayor_mumbai
  ].freeze
  TWEET_FIELDS = "created_at,author_id,public_metrics,in_reply_to_user_id,attachments,conversation_id,referenced_tweets"
  EXPANSIONS = "author_id,attachments.media_keys,referenced_tweets.id,referenced_tweets.id.author_id"
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

    def fetch(ward, count: 10, since_id: nil)
      return [] if ward.twitter_handle.blank?

      query = "(from:#{ward.twitter_handle} OR @#{ward.twitter_handle}) -is:retweet"
      params = "query=#{CGI.escape(query)}&max_results=#{count}&tweet.fields=#{TWEET_FIELDS}&expansions=#{EXPANSIONS}&media.fields=#{MEDIA_FIELDS}&user.fields=#{USER_FIELDS}"
      params += "&since_id=#{since_id}" if since_id
      uri = URI("#{API_BASE}/tweets/search/recent?#{params}")

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
        build_tweet_data(tweet, users, media)
      end

      # Import referenced (parent) tweets — then fetch their full data (media, metrics)
      referenced_tweets = (payload.dig("includes", "tweets") || []).map do |tweet|
        build_tweet_data(tweet, users, media)
      end

      if referenced_tweets.any?
        import(ward, referenced_tweets)
        parent_ids = referenced_tweets.map { |t| t["id"] }.compact
        refresh_batch(parent_ids) if parent_ids.any?
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
        latest_tweet_id = ward.tweets.order(tweeted_at: :desc).pick(:tweet_id)
        fetch(ward, since_id: latest_tweet_id)
      end
      fetch_citywide
    end

    # Fetch tweets mentioning city-wide handles and assign to wards by co-mention
    def fetch_citywide(count: 100)
      ward_handle_map = Ward.where.not(twitter_handle: [nil, ""])
        .pluck(:twitter_handle, :id)
        .to_h { |handle, id| [handle.downcase, id] }

      latest_tweet_id = Tweet.order(tweeted_at: :desc).pick(:tweet_id)

      CITYWIDE_HANDLES.each do |handle|
        query = "@#{handle} -is:retweet"
        params = "query=#{CGI.escape(query)}&max_results=#{count}&tweet.fields=#{TWEET_FIELDS}&expansions=#{EXPANSIONS}&media.fields=#{MEDIA_FIELDS}&user.fields=#{USER_FIELDS}"
        params += "&since_id=#{latest_tweet_id}" if latest_tweet_id
        uri = URI("#{API_BASE}/tweets/search/recent?#{params}")

        response = api_get(uri)
        unless response.is_a?(Net::HTTPSuccess)
          Rails.logger.error "TweetService: X API failed for @#{handle}: #{response.code}"
          next
        end

        payload = JSON.parse(response.body)
        next unless payload["data"]

        users = (payload.dig("includes", "users") || []).index_by { |u| u["id"] }
        media = (payload.dig("includes", "media") || []).index_by { |m| m["media_key"] }

        payload["data"].each do |tweet_data|
          text = tweet_data["text"] || ""
          # Find which ward handle is co-mentioned
          ward_id = ward_handle_map.find { |ward_handle, _|
            text.downcase.include?("@#{ward_handle}")
          }&.last
          next unless ward_id

          ward = Ward.find(ward_id)
          data = build_tweet_data(tweet_data, users, media)
          import(ward, [data])
        end

        Rails.logger.info "TweetService: Scanned #{payload['data'].size} tweets for @#{handle}"
      rescue JSON::ParserError => e
        Rails.logger.error "TweetService: Failed to parse response for @#{handle}: #{e.message}"
      rescue StandardError => e
        Rails.logger.error "TweetService: Error fetching @#{handle}: #{e.message}"
      end
    end

    # Refresh metrics and media for recent tweets using bulk lookup (100 per API call)
    # Defaults to tweets from last 7 days - when engagement is most active
    def refresh_activity(scope: Tweet.where("tweeted_at > ?", 7.days.ago))
      scope.order(tweeted_at: :desc).pluck(:id, :tweet_id).each_slice(100) do |batch|
        refresh_batch(batch.map(&:last))
      end
    end

    def fetch_single(tweet)
      refresh_batch([tweet.tweet_id])
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
          in_reply_to_status_id: data["inReplyToStatusId"]&.to_s.presence,
          conversation_id: data["conversationId"]&.to_s,
          media_urls: normalize_media(data).presence
        )
        tweet.save!
        tweet
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "TweetService: Failed to save tweet #{id}: #{e.message}"
        nil
      end
    end

    # Backfill: re-fetch reply tweets to get parent tweet IDs, then fetch parents
    def fetch_parent_tweets
      # Re-fetch our reply tweets to get referenced_tweets data
      Tweet.replies_only.where(conversation_id: nil).pluck(:tweet_id).each_slice(100) do |batch|
        refresh_batch(batch, import_parents: true)
      end
      Rails.logger.info "Parent tweet backfill complete"
    end

    private

    def build_tweet_data(tweet, users, media)
      author = users[tweet["author_id"]] || {}
      media_keys = tweet.dig("attachments", "media_keys") || []
      media_urls = media_keys.filter_map { |k| media[k]&.slice("url", "preview_image_url", "type") }
      metrics = tweet["public_metrics"] || {}

      # Get parent tweet ID from referenced_tweets
      replied_to = (tweet["referenced_tweets"] || []).find { |r| r["type"] == "replied_to" }

      {
        "id" => tweet["id"],
        "text" => tweet["text"],
        "createdAt" => tweet["created_at"],
        "author" => { "username" => author["username"], "name" => author["name"] },
        "likeCount" => metrics["like_count"],
        "retweetCount" => metrics["retweet_count"],
        "replyCount" => metrics["reply_count"],
        "inReplyToStatusId" => replied_to&.dig("id"),
        "conversationId" => tweet["conversation_id"],
        "mediaUrls" => media_urls
      }
    end

    def refresh_batch(tweet_ids, import_parents: false)
      ids_param = tweet_ids.join(",")
      uri = URI("#{API_BASE}/tweets?ids=#{ids_param}&tweet.fields=#{TWEET_FIELDS}&expansions=#{EXPANSIONS}&media.fields=#{MEDIA_FIELDS}&user.fields=#{USER_FIELDS}")
      response = api_get(uri)
      return unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      return unless payload["data"]

      users = (payload.dig("includes", "users") || []).index_by { |u| u["id"] }
      media_map = (payload.dig("includes", "media") || []).index_by { |m| m["media_key"] }

      payload["data"].each do |data|
        tweet = Tweet.find_by(tweet_id: data["id"])
        next unless tweet

        media_keys = data.dig("attachments", "media_keys") || []
        media_urls = media_keys.filter_map { |k| media_map[k]&.slice("url", "preview_image_url", "type") }
        metrics = data["public_metrics"] || {}
        replied_to = (data["referenced_tweets"] || []).find { |r| r["type"] == "replied_to" }

        tweet.update!(
          media_urls: media_urls.presence,
          like_count: metrics["like_count"].to_i,
          retweet_count: metrics["retweet_count"].to_i,
          reply_count: metrics["reply_count"].to_i,
          in_reply_to_status_id: replied_to&.dig("id") || tweet.in_reply_to_status_id,
          conversation_id: data["conversation_id"] || tweet.conversation_id
        )
      end

      # Import parent tweets from includes, then fetch their full data
      if import_parents
        referenced = (payload.dig("includes", "tweets") || []).map do |tweet|
          build_tweet_data(tweet, users, media_map)
        end
        if referenced.any?
          ward_ids = Tweet.where(tweet_id: tweet_ids).pluck(:tweet_id, :ward_id).to_h
          parent_ids = []
          referenced.each do |parent_data|
            reply = payload["data"].find { |d| (d["referenced_tweets"] || []).any? { |r| r["id"] == parent_data["id"] } }
            next unless reply
            ward_id = ward_ids[reply["id"]]
            next unless ward_id
            ward = Ward.find_by(id: ward_id)
            if ward
              import(ward, [parent_data])
              parent_ids << parent_data["id"]
            end
          end
          refresh_batch(parent_ids) if parent_ids.any?
        end
      end

      Rails.logger.info "Refreshed #{payload['data'].size} tweets"
    rescue StandardError => e
      Rails.logger.warn "Batch refresh failed: #{e.message}"
    end

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

    # Accept both X API v2 format ("mediaUrls") and bird-cli format ("media")
    def normalize_media(data)
      if data["mediaUrls"]
        data["mediaUrls"]
      elsif data["media"]
        data["media"].map do |m|
          { "url" => m["url"], "preview_image_url" => m["previewUrl"], "type" => m["type"] }
        end
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
