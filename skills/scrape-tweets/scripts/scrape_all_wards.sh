#!/bin/bash
# Scrape tweets for all MCGM wards and POST to production
# Usage: skills/scrape-tweets/scripts/scrape_all_wards.sh [count]
#
# Loads credentials from .env and .kamal/secrets

set -euo pipefail

cd "$(dirname "$0")/../../.."

# Load credentials
set -a
source .env
source .kamal/secrets
set +a

COUNT="${1:-20}"
API_URL="https://mcgm.svs.io"
API_KEY="$TWEETS_API_KEY"
SCRIPT_DIR="skills/scrape-tweets/scripts"

# Verify bird credentials
echo "Verifying bird credentials..."
WHOAMI=$(bird --auth-token "$BIRD_AUTH_TOKEN" --ct0 "$BIRD_CT0" whoami --plain 2>&1 | head -2)
echo "$WHOAMI"
echo ""

# All ward handle -> slug pairs
PAIRS="mybmcWardA,ward-a
mybmcWardB,ward-b
mybmcWardC,ward-c
mybmcWardD,ward-d
mybmcWardE,ward-e
mybmcWardFN,ward-f-north
mybmcWardFS,ward-f-south
mybmcWardGN,ward-g-north
mybmcWardGS,ward-g-south
mybmcWardHE,ward-h-east
mybmcWardHW,ward-h-west
mybmcWardKE,ward-k-east
mybmcWardKN,ward-k-north
mybmcWardKW,ward-k-west
mybmcWardL,ward-l
mybmcWardME,ward-m-east
mybmcWardMW,ward-m-west
mybmcWardN,ward-n
mybmcWardPE,ward-p-east
mybmcWardPN,ward-p-north
mybmcWardPS,ward-p-south
mybmcWardRC,ward-r-central
mybmcWardRN,ward-r-north
mybmcWardRS,ward-r-south
mybmcWardS,ward-s
mybmcWardT,ward-t"

TOTAL=0
ERRORS=0

echo "$PAIRS" | while IFS=',' read -r HANDLE SLUG; do
  echo "--- @${HANDLE} -> ${SLUG} ---"

  TWEETS=$(bird --auth-token "$BIRD_AUTH_TOKEN" --ct0 "$BIRD_CT0" search "@${HANDLE}" --json -n "$COUNT" --plain 2>/dev/null || echo "[]")

  if [ -z "$TWEETS" ] || [ "$TWEETS" = "[]" ]; then
    echo "${HANDLE}: no tweets found"
    sleep 2
    continue
  fi

  RESPONSE=$(curl -s -X POST "${API_URL}/wards/${SLUG}/tweets" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "{\"tweets\": ${TWEETS}}")

  IMPORTED=$(echo "$RESPONSE" | ruby -rjson -e 'j = JSON.parse(STDIN.read); puts j["imported"]' 2>/dev/null || echo "error")

  if [ "$IMPORTED" = "error" ]; then
    echo "${HANDLE}: ERROR - ${RESPONSE}"
  else
    echo "${HANDLE}: imported ${IMPORTED} tweets"
  fi

  sleep 2
done

echo ""
echo "Done."
