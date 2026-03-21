---
name: enrich-ward
description: Enrich ward data by searching Parallel AI for officer profiles, news, and social links. Use when asked to "enrich ward", "populate ward data", "find officer info", "update officer profiles", or "verify ward officers".
---

# Enrich Ward Data

Uses Parallel AI's Search API to enrich ward officer data with names, bios, news coverage, social media links, and verification against public sources.

## Prerequisites

- Parallel API key stored in Rails credentials as `parallels_api_key`
- Officers already imported via `governance:import` and `governance:import_civic_diary`
- The Position model has: `person_name`, `phone`, `email`, `bio`, `linkedin_url`, `twitter_handle`, `profile_data` (JSON)

## Parallel API

```bash
curl https://api.parallel.ai/v1beta/search \
  -H "Content-Type: application/json" \
  -H "x-api-key: $PARALLEL_API_KEY" \
  -d '{
    "objective": "...",
    "search_queries": ["..."],
    "mode": "fast",
    "excerpts": {"max_chars_per_result": 3000}
  }'
```

API key: `Rails.application.credentials.parallels_api_key`

The key can also be found in the `.kamal/secrets` file or passed via env var.

## Workflow

### 1. Pick a ward (or all wards)

If the user specifies a ward, enrich just that ward. Otherwise, iterate through all wards with named officers.

```ruby
# Single ward
ward = Ward.find_by(ward_code: "A")

# All wards
Ward.all.each do |ward| ...
```

### 2. For each named officer, search Parallel

For each Position with a `person_name`, search for:
- News articles mentioning them + BMC
- LinkedIn profile
- Twitter/X handle
- Any biographical information

Use this search pattern:

```bash
curl -s https://api.parallel.ai/v1beta/search \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_KEY" \
  -d '{
    "objective": "Find news articles, LinkedIn profile, Twitter handle, and biographical information about PERSON_NAME, DESIGNATION of WARD_CODE Ward BMC Mumbai.",
    "search_queries": [
      "PERSON_NAME BMC Mumbai WARD_CODE ward",
      "PERSON_NAME MCGM Mumbai",
      "PERSON_NAME BMC linkedin"
    ],
    "mode": "fast",
    "excerpts": {"max_chars_per_result": 3000}
  }'
```

### 3. Extract structured data from results

From the Parallel search results, extract:

**LinkedIn URL**: Look for `linkedin.com/in/` URLs in results
**Twitter handle**: Look for `twitter.com/` or `x.com/` URLs
**News articles**: Collect article titles, URLs, sources, dates, and excerpts from news sites (hindustantimes.com, timesofindia.com, freepressjournal.in, mumbaimirror.indiatimes.com, ndtv.com, etc.)
**Bio**: Synthesize a 2-3 sentence bio from search results describing the officer's role, background, and notable actions

### 4. Update the Position record

```ruby
position.update!(
  linkedin_url: "https://linkedin.com/in/...",
  twitter_handle: "@handle",
  bio: "2-3 sentence bio...",
  profile_data: {
    "news" => [
      {
        "title" => "Article headline",
        "url" => "https://...",
        "source" => "Hindustan Times",
        "date" => "Mar 2025",
        "excerpt" => "Brief summary of the article..."
      }
    ],
    "enriched_at" => Time.current.iso8601,
    "source" => "Parallel AI search"
  }
)
```

### 5. Verification mode

When verifying officer names (checking if civic diary data is current):

Search for the ward + "assistant commissioner" to find the latest name:

```bash
curl -s https://api.parallel.ai/v1beta/search \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_KEY" \
  -d '{
    "objective": "Who is the current Assistant Commissioner of WARD_CODE Ward in BMC Mumbai as of 2025? Has there been any recent transfer or new appointment?",
    "search_queries": [
      "BMC WARD_CODE ward assistant commissioner 2025",
      "MCGM WARD_CODE ward officer transfer 2025"
    ],
    "mode": "fast",
    "excerpts": {"max_chars_per_result": 2000}
  }'
```

Compare the name found with what we have in the database. Report:
- **Match**: Name confirmed by web sources
- **Outdated**: New officer found, our data needs updating
- **Unverified**: No clear confirmation found

### 6. Also check MCGM portal contact pages

Each ward has a contact page on the MCGM portal with officer names. Use Parallel's Extract API to pull structured data:

```bash
curl -s https://api.parallel.ai/v1beta/extract \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_KEY" \
  -d '{
    "url": "https://portal.mcgm.gov.in/irj/go/km/docs/documents/WARD_CODE%20Ward/Important%20Numbers.pdf",
    "objective": "Extract all officer names, designations, phone numbers, and email addresses from this ward contact list.",
    "schema": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "name": {"type": "string"},
          "designation": {"type": "string"},
          "phone": {"type": "string"},
          "email": {"type": "string"}
        }
      }
    }
  }'
```

Known ward contact PDF URLs on MCGM portal:
- `https://portal.mcgm.gov.in/irj/go/km/docs/documents/D%20Ward/Important%20Numbers.pdf`
- Pattern: `https://portal.mcgm.gov.in/irj/go/km/docs/documents/WARD%20Ward/Important%20Numbers.pdf`

## Rate Limiting

- Add 2-second sleep between Parallel API calls
- Each search uses 1 SKU credit
- For bulk enrichment, process max 5 officers per ward (leadership + named AEs)
- Cache results in `profile_data` to avoid re-fetching

## Output

After enrichment, summarize what was found:

```
Ward A:
  Shri. Jaydeep More (AC) — LinkedIn found, 4 news articles, bio written
  Shri. Ravindra Mhaske (AE) — Facebook found, no news
  Shri. Pawan Kaware (AE) — 2 news articles (suspended for parking violations)

Ward B:
  Shri. Santoshkumar Dhonde (AC) — OUTDATED: replaced by Yogesh Desai (Oct 2025)
  ...
```

## Notes

- Officers are public servants; their professional information is public record
- Focus on professional/civic role information, not personal details
- News articles should relate to their BMC duties
- When an officer is found to have been transferred, note it but don't auto-update — flag for manual review
- The MCGM portal ward pages (mcgm.gov.in/irj/portal/anonymous/qlward*) have official contact lists that are more current than the civic diary
