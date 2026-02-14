---
name: scrape-tweets
description: Scrape tweets for MCGM wards using bird-cli and POST them to the app's tweet ingestion API. Use when asked to scrape, fetch, or refresh tweets for wards.
---

# Scrape Tweets

## Overview

Fetches tweets mentioning MCGM ward twitter handles using the `bird` CLI, then POSTs them to the tweet ingestion API endpoint.

## Workflow

### 1. Get wards with twitter handles

Use `rails runner` to get the list:

```bash
bin/rails runner "puts Ward.where.not(twitter_handle: [nil, '']).pluck(:ward_code, :twitter_handle, :id).map { |c,h,i| [c,h,i].join(',') }"
```

### 2. Scrape tweets with bird-cli

For each ward, run:

```bash
bird search "@<twitter_handle>" --json -n <count> --plain
```

Default count is 20. The output is a JSON array of tweet objects.

### 3. POST tweets to the app

POST the bird JSON output to the tweet ingestion endpoint:

- **Local:** `http://localhost:4090/wards/<ward_slug>/tweets`
- **Production:** `https://mcgm.svs.io/wards/<ward_slug>/tweets`

The ward slug is the ward name lowercased with non-alphanumeric chars replaced by hyphens (e.g. "F SOUTH" -> "ward-f-south", "A" -> "ward-a").

Required headers:
- `Content-Type: application/json`
- `Authorization: Bearer <TWEETS_API_KEY>`

The API key is stored in `.kamal/secrets` as `TWEETS_API_KEY`. For local dev it's in `.env`.

Request body: `{"tweets": [<bird output array>]}`

Response: `{"imported": N, "tweets": [...]}`

### 4. Use the helper script

The `scripts/scrape_ward.sh` script handles steps 2-3 for a single ward:

```bash
skills/scrape-tweets/scripts/scrape_ward.sh <twitter_handle> <ward_slug> <api_url> <api_key> [count]
```

Example:
```bash
skills/scrape-tweets/scripts/scrape_ward.sh mybmcWardA ward-a https://mcgm.svs.io 'b2d140a4...' 20
```

## Typical Usage

When the user says "scrape tweets" or "refresh tweets":

1. Get wards from DB via rails runner
2. Ask which wards (all, or specific ones)
3. Run the scrape script for each ward, reporting results
4. For "all wards", iterate through each one sequentially with a brief pause between requests
