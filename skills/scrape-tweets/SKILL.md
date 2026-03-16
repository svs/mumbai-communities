---
name: scrape-tweets
description: Scrape tweets for all MCGM wards using bird-cli and POST them to the production ingestion API. Use when asked to "scrape tweets", "update tweets", "refresh tweets", or "sync tweets to prod".
---

# Scrape Tweets

Fetches recent tweets mentioning MCGM ward Twitter handles using `bird` CLI and POSTs them to the production ingestion API at mcgm.svs.io.

## Workflow

### 1. Run the scrape script

```bash
skills/scrape-tweets/scripts/scrape_all_wards.sh
```

This will:
- Load bird credentials from `.env` (BIRD_AUTH_TOKEN, BIRD_CT0)
- Load the API key from `.kamal/secrets` (TWEETS_API_KEY)
- Scrape 20 tweets per ward using `bird search`
- POST each batch to `https://mcgm.svs.io/wards/<slug>/tweets`
- Print import counts per ward
- Sleep 2s between wards to avoid rate limits

### 2. Verify

After the script completes, check https://mcgm.svs.io/wards to confirm fresh tweets appear.

### 3. Single ward

To scrape just one ward:

```bash
skills/scrape-tweets/scripts/scrape_ward.sh <twitter_handle> <ward_slug> https://mcgm.svs.io <api_key> [count]
```

Example:
```bash
source .env && source .kamal/secrets
skills/scrape-tweets/scripts/scrape_ward.sh mybmcWardA ward-a https://mcgm.svs.io "$TWEETS_API_KEY" 20
```

## Notes

- Bird credentials (`BIRD_AUTH_TOKEN`, `BIRD_CT0`) are X session cookies stored in `.env`
- Use `bird --auth-token $BIRD_AUTH_TOKEN --ct0 $BIRD_CT0 whoami --plain` to verify the account
- Production API key is in `.kamal/secrets` as `TWEETS_API_KEY`
- The dev API key in `.env` is different from the production one
