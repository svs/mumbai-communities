#!/bin/bash
# Scrape tweets for a single ward and POST to the ingestion API
# Usage: scrape_ward.sh <twitter_handle> <ward_slug> <api_url> <api_key> [count]

set -euo pipefail

HANDLE="$1"
WARD_SLUG="$2"
API_URL="$3"
API_KEY="$4"
COUNT="${5:-20}"

# Fetch tweets using bird-cli
TWEETS=$(bird search "@${HANDLE}" --json -n "$COUNT" --plain 2>/dev/null)

# Check if we got any tweets
if [ -z "$TWEETS" ] || [ "$TWEETS" = "[]" ]; then
  echo "${HANDLE}: no tweets found"
  exit 0
fi

# POST to the API
RESPONSE=$(curl -s -X POST "${API_URL}/wards/${WARD_SLUG}/tweets" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer ${API_KEY}" \
  -d "{\"tweets\": ${TWEETS}}")

IMPORTED=$(echo "$RESPONSE" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["imported"] rescue puts "error"')
echo "${HANDLE}: imported ${IMPORTED} tweets"
