---
name: import-officers
description: Extract ward officer data from PDFs or URLs and import into the governance database. Use when asked to "import officers", "extract officers from PDF", "add officer data", or "update governance data from [source]".
---

# Import Officers

Extracts ward officer data from BMC documents (PDFs, URLs, or pasted text) and imports it into the governance database.

## Output Data Format

The extraction MUST produce JSON in this exact format:

```json
{
  "source": "Description of source document",
  "wards": {
    "A": {
      "sections": {
        "Ward Office": [
          {
            "designation": "Assistant Commissioner",
            "person_name": "Shri. Jaydeep More",
            "email": "ac.a@mcgm.gov.in",
            "phone": "9969666505",
            "level": "senior"
          }
        ],
        "Maintenance": [
          {
            "designation": "Designated Officer",
            "person_name": "Shri. Jaydeep More",
            "phone": "9969666505",
            "level": "senior"
          },
          {
            "designation": "Assistant Engineer",
            "person_name": "Shri. Ravindra Mhaske",
            "phone": "9004688678",
            "level": "mid"
          }
        ]
      }
    }
  }
}
```

### Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| `designation` | Yes | Officer's title: Assistant Commissioner, Executive Engineer, Designated Officer, Assistant Engineer, Sub Engineer, Junior Engineer, Medical Officer, etc. |
| `person_name` | No | Full name with honorific (Shri./Smt./Dr.). Null if vacant. |
| `email` | No | Official @mcgm.gov.in email if available |
| `phone` | No | 10-digit mobile number (no country code) |
| `level` | Yes | One of: `senior`, `mid`, `junior`. See mapping below. |

### Level Mapping

- **senior**: Assistant Commissioner, Executive Engineer, Medical Officer, Designated Officer, Assessor & Collector, Administrative Officer, Chief Medical Officer
- **mid**: Assistant Engineer, Road Engineer, Horticultural Assistant
- **junior**: Sub Engineer, Junior Engineer, Head Clerk

### Ward Codes

Use these exact ward codes as keys:

```
A, B, C, D, E, F SOUTH, F NORTH, G SOUTH, G NORTH,
H EAST, H WEST, K EAST, K WEST, K NORTH, L,
M EAST, M WEST, N, P EAST, P SOUTH, P NORTH,
R SOUTH, R/Central, R/North, S, T
```

### Section Names

Normalize department/section names to these standard values:

```
Ward Office, Maintenance, Water Works, Solid Waste Management,
Building and Factory, M&E, Health, Estate, Roads, Gardens,
Assessment and Collection, Education, Sewerage
```

## Workflow

### 1. Read the source

If given a PDF path, read it with the Read tool (it supports PDFs). If given a URL, fetch it. If given pasted text, use it directly.

For large PDFs, read in page ranges (max 20 pages at a time). Start by scanning for table of contents or section headers to find relevant pages.

### 2. Extract officer data

Read the relevant pages and extract officer information into the JSON format above. Use your understanding of BMC organizational structure to:

- Identify ward codes from context (e.g., "'A' Ward" → "A")
- Map designations to levels
- Normalize section/department names
- Extract phone numbers (10-digit mobile numbers)
- Extract emails (@mcgm.gov.in addresses)
- Preserve full names with honorifics

### 3. Save the JSON

Write the extracted JSON to `db/data/` with a descriptive filename:

```
db/data/civic_diary_officers.json
db/data/ward_email_officers.json
```

### 4. Import into database

Run the import using Tidewave's project_eval tool (NOT rails runner):

```ruby
json = JSON.parse(File.read(Rails.root.join("db/data/<filename>.json")))

json["wards"].each do |ward_code, ward_data|
  ward = Ward.find_by(ward_code: ward_code)
  next unless ward

  ward_org = Organisation.find_or_create_by!(organisable: ward, org_type: "ward") do |org|
    org.name = "Ward #{ward.ward_code}"
  end

  ward_data["sections"].each do |section_name, officers|
    dept = Department.find_or_create_by!(organisation: ward_org, name: section_name)

    officers.each do |officer|
      next unless officer["designation"].present?

      # Find existing position by email or designation+department
      position = if officer["email"].present?
        Position.find_by(department: dept, email: officer["email"])
      end
      position ||= Position.find_by(department: dept, designation: officer["designation"], person_name: officer["person_name"])

      if position
        # Update existing position with new data
        position.update!(
          person_name: officer["person_name"],
          phone: officer["phone"],
          level: officer["level"]
        )
      else
        Position.create!(
          department: dept,
          designation: officer["designation"],
          person_name: officer["person_name"],
          email: officer["email"],
          phone: officer["phone"],
          level: officer["level"]
        )
      end
    end
  end
end
```

### 5. Verify

After import, verify the data:

```ruby
Position.where.not(person_name: [nil, ""]).count
# Should show how many positions now have names

Ward.find_by(ward_code: "A").organisation.departments.flat_map { |d| d.positions.where.not(person_name: nil) }.map { |p| "#{p.designation}: #{p.person_name}" }
```

## Notes

- The import is idempotent — running it multiple times won't create duplicates
- When updating, new data (names, phones) overwrites old data for the same position
- Vacant positions (person_name: null) are valid and should be preserved
- Some officers serve multiple wards (I/C = In Charge) — create a position in each ward
- Phone numbers should be stored as 10-digit strings without country code
- The `political_party` column exists on Position for elected officials
