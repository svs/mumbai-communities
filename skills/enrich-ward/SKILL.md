---
name: enrich-ward
description: Populate ward officer data using Parallel AI search and extract. Use when asked to "enrich ward", "populate ward data", "update officers", "refresh officer data", or "import ward officers".
---

# Enrich Ward Data

Uses Parallel AI to find and extract ward officer data from MCGM portal contact lists, news articles, and social media. No manual PDF parsing needed — Parallel does the web research.

## API Details

**Base URL**: `https://api.parallel.ai/v1beta/`
**Auth**: `x-api-key` header
**Key**: Use `Rails.application.credentials.parallels_api_key` or from shell: source `.kamal/secrets` and use `$PARALLEL_API_KEY`, or hardcode from Rails credentials.

### Search API
```bash
curl https://api.parallel.ai/v1beta/search \
  -H "Content-Type: application/json" \
  -H "x-api-key: $KEY" \
  -d '{
    "objective": "...",
    "search_queries": ["..."],
    "mode": "fast",
    "excerpts": {"max_chars_per_result": 3000}
  }'
```

### Extract API
```bash
curl https://api.parallel.ai/v1beta/extract \
  -H "Content-Type: application/json" \
  -H "x-api-key: $KEY" \
  -d '{
    "urls": ["https://..."],
    "objective": "...",
    "excerpts": true,
    "full_content": true
  }'
```

## Workflow

### Step 1: Find the ward contact PDF URL

For each ward, search Parallel for the MCGM portal contact list:

```bash
curl -s https://api.parallel.ai/v1beta/search \
  -H "Content-Type: application/json" \
  -H "x-api-key: $KEY" \
  -d '{
    "objective": "Find the official MCGM/BMC contact list PDF for WARD_CODE Ward Mumbai with officer names, designations, and phone numbers",
    "search_queries": [
      "site:mcgm.gov.in WARD_CODE ward important numbers contact",
      "site:portal.mcgm.gov.in WARD_CODE ward officers"
    ],
    "mode": "fast"
  }'
```

Known URL patterns on MCGM portal:
- `https://portal.mcgm.gov.in/irj/go/km/docs/documents/D%20Ward/Important%20Numbers.pdf`
- `https://dm.mcgm.gov.in/ward-directory` (disaster management ward directory)

### Step 2: Extract officer data

Once you have the PDF URL, extract structured data:

```bash
curl -s https://api.parallel.ai/v1beta/extract \
  -H "Content-Type: application/json" \
  -H "x-api-key: $KEY" \
  -d '{
    "urls": ["PDF_URL_HERE"],
    "objective": "Extract all officer names, designations, phone numbers, and email addresses from this BMC ward contact list",
    "excerpts": true,
    "full_content": true
  }'
```

### Step 3: Parse the extracted content into our format

From the Parallel Extract results, build a JSON structure. The extract returns markdown-formatted content that you should parse into:

```json
{
  "ward_code": "D",
  "source_url": "https://portal.mcgm.gov.in/...",
  "extracted_at": "2026-03-21",
  "officers": [
    {
      "designation": "Assistant Commissioner",
      "person_name": "Shri. Sharad Ughade",
      "phone": "9167494033",
      "email": "ac.d@mcgm.gov.in",
      "section": "Ward Office",
      "level": "senior"
    },
    {
      "designation": "Executive Engineer",
      "person_name": "Suresh Kanoja",
      "phone": "9975673419",
      "email": "ee.d@mcgm.gov.in",
      "section": "Ward Office",
      "level": "senior"
    }
  ]
}
```

#### Designation to Section mapping

| Designation | Section | Level |
|-------------|---------|-------|
| Asst. Commissioner, Assistant Commissioner | Ward Office | senior |
| Executive Engineer | Ward Office | senior |
| Designated Officer | Ward Office | senior |
| A.E. (Maint), A.E. (Maint) East/West | Maintenance | mid |
| A.E. (SWM) | Solid Waste Management | mid |
| A.E. (B&F) | Building and Factory | mid |
| A.E. (Water) | Water Works | mid |
| Medical Officer of Health, MOH | Health | senior |
| Complaint Officer | Ward Office | mid |
| Sr. Insp. Licence, Sr. Insp. Ench. | Licence | mid |
| AA&C, Asst. Assessor & Collector | Assessment and Collection | mid |
| PCO, Pest Control Officer | Health | mid |
| ASG, Asst. Supdt. of Garden | Gardens | mid |
| A.O. (School), Administrative Officer (School) | Education | mid |
| Colony Officer | Estate | mid |

### Step 4: Import into database (idempotent)

Use this import logic that tracks tenure changes:

```ruby
ward = Ward.find_by(ward_code: ward_code)
ward_org = Organisation.find_or_create_by!(organisable: ward, org_type: "ward") do |org|
  org.name = "Ward #{ward.ward_code}"
end

officers_data.each do |officer|
  dept = Department.find_or_create_by!(organisation: ward_org, name: officer["section"])

  # Find existing active position by email OR by designation in same department
  existing = nil
  if officer["email"].present?
    existing = Position.joins(:department)
      .where(departments: { organisation_id: ward_org.id })
      .where(email: officer["email"], active: true)
      .first
  end
  existing ||= Position.where(
    department: dept,
    designation: officer["designation"],
    active: true
  ).first

  if existing
    if existing.person_name == officer["person_name"]
      # Same person — update contact info only
      existing.update!(
        phone: officer["phone"].presence || existing.phone,
        email: officer["email"].presence || existing.email
      )
    elsif officer["person_name"].present?
      # Different person — officer has changed!
      # End the old tenure
      existing.update!(active: false, ended_on: Date.current)
      # Create new position for new officer
      Position.create!(
        department: dept,
        designation: officer["designation"],
        person_name: officer["person_name"],
        phone: officer["phone"],
        email: officer["email"],
        level: officer["level"],
        active: true,
        started_on: Date.current
      )
    end
  else
    # New position
    Position.create!(
      department: dept,
      designation: officer["designation"],
      person_name: officer["person_name"],
      phone: officer["phone"],
      email: officer["email"],
      level: officer["level"],
      active: true,
      started_on: Date.current
    )
  end
end
```

### Step 5: Enrich profiles (optional)

After importing base data, optionally enrich key officers (AC, DO) with news and social links:

```bash
curl -s https://api.parallel.ai/v1beta/search \
  -H "Content-Type: application/json" \
  -H "x-api-key: $KEY" \
  -d '{
    "objective": "Find news articles, LinkedIn profile, and Twitter handle for PERSON_NAME, DESIGNATION of WARD_CODE Ward BMC Mumbai",
    "search_queries": [
      "PERSON_NAME BMC Mumbai",
      "PERSON_NAME MCGM linkedin"
    ],
    "mode": "fast",
    "excerpts": {"max_chars_per_result": 2000}
  }'
```

Update the Position with:
- `linkedin_url`: LinkedIn profile URL if found
- `twitter_handle`: Twitter/X handle if found
- `bio`: 2-3 sentence bio synthesized from results
- `profile_data`: JSON with news articles array

### Step 6: Verify against current news

Search for recent transfers to catch stale data:

```bash
curl -s https://api.parallel.ai/v1beta/search \
  -H "Content-Type: application/json" \
  -H "x-api-key: $KEY" \
  -d '{
    "objective": "Has there been any recent transfer or new appointment for WARD_CODE Ward assistant commissioner in BMC Mumbai?",
    "search_queries": [
      "BMC WARD_CODE ward assistant commissioner transfer 2025 2026",
      "MCGM WARD_CODE ward new officer appointment"
    ],
    "mode": "fast"
  }'
```

## Rate Limiting

- Sleep 2 seconds between API calls
- Each search/extract uses 1 SKU credit
- For bulk processing, do one ward at a time

## Running for all wards

Process wards in order. For each ward:
1. Search for contact PDF URL (1 API call)
2. Extract officer data from PDF (1 API call)
3. Parse and import (no API call)
4. Optionally enrich top 2-3 officers (2-3 API calls)

Total per ward: 2-5 API calls. All 27 wards: ~60-135 calls.

## Output

After processing, report:
```
Ward A: 17 officers imported (4 new, 2 updated, 1 transfer detected)
Ward B: 15 officers imported (15 new)
...
```
