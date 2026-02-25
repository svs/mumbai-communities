---
name: refresh-tweets
description: Fetch latest tweets from X API for all wards and optionally push to production. Use when asked to "refresh tweets", "update tweets", "fetch tweets", or "sync tweets".
---

# Refresh Tweets

## Overview

Fetches the latest tweets from all BMC ward Twitter accounts using the X API v2 and stores them locally. Can also push tweets to the production server at mcgm.svs.io via the ingestion API.

## Workflow

### 1. Refresh locally

```ruby
# Via rails runner
TweetService.refresh_all
```

This fetches 10 recent tweets per ward from the X API and upserts them into the local DB.

### 2. Check usage

```bash
curl -s -H "Authorization: Bearer $(rails runner "puts Rails.application.credentials.dig(:x, :bearer_token)")" \
  "https://api.x.com/2/usage/tweets" | python3 -m json.tool
```

Cap is 2M tweets/month. Each refresh_all uses ~270 tweets (27 wards × 10).

### 3. Push to production

After refreshing locally, push tweets to prod via the ingestion API:

```bash
# For each ward, export tweets as JSON and POST to prod
rails runner "
  Ward.where.not(twitter_handle: [nil, '']).find_each do |ward|
    tweets = ward.tweets.recent.limit(20)
    tweets_data = tweets.map do |t|
      {
        id: t.tweet_id,
        text: t.body,
        createdAt: t.tweeted_at&.iso8601,
        author: { username: t.author_username, name: t.author_name },
        likeCount: t.like_count,
        retweetCount: t.retweet_count,
        replyCount: t.reply_count,
        inReplyToUserId: t.in_reply_to_status_id
      }
    end

    uri = URI('https://mcgm.svs.io/wards/#{ward.to_param}/tweets')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = 'Bearer ' + ENV.fetch('TWEETS_API_KEY')
    req.body = { tweets: tweets_data }.to_json
    resp = http.request(req)
    puts \"#{ward.ward_code}: #{resp.code} - #{resp.body.truncate(100)}\"
  end
"
```

### 4. Verify

Check the front page to confirm fresh tweets:
- Local: http://localhost:4090/wards
- Prod: https://mcgm.svs.io/wards

## Notes

- The X API bearer token is stored in Rails credentials (development)
- Production ingestion API requires TWEETS_API_KEY
- X API search/recent only returns tweets from the last 7 days
- Rate limit: 2M tweets/month, each refresh uses ~270
