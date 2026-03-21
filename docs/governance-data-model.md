# People, Organisations & Positions

## Core Principle

**Organisations are generic.** Any body — government agency, NGO, residents' association, political party — can be an Organisation. The data model doesn't impose a governance hierarchy. It models reality: people hold positions in organisations, and organisations operate in places.

## The Real World

Mumbai has dozens of overlapping agencies and bodies operating at the ward/city level:

```
Government Agencies
├── BMC (Brihanmumbai Municipal Corporation)
│   ├── Ward A office (org attached to Ward A)
│   ├── Ward B office
│   └── ... 27 wards
├── MMRDA (Mumbai Metropolitan Region Development Authority)
├── MMRCL (Mumbai Metro Rail Corporation)
├── MHADA (Maharashtra Housing and Area Development Authority)
├── SRA (Slum Rehabilitation Authority)
├── Mumbai Police (by zone/station)
├── Mumbai Fire Brigade
└── Collector's Office (City / Suburban)

Elected Bodies
├── BMC Corporators (per prabhag)
├── MLAs (per constituency)
└── MPs (per constituency)

Civil Society
├── ALMs (Advanced Locality Management groups)
├── Residents' Associations
├── NGOs (Praja Foundation, Civis, etc.)
└── Trade Unions / Hawker Unions

Utilities
├── BEST (buses + electricity)
├── MTNL
└── Mahanagar Gas
```

All of these are **Organisations**. A ward ALM and the BMC ward office are both orgs — they just have different `org_type` values and different relationships to the ward.

## Data Model

### Person

A human being. Name, contact info, public profile. Exists independently of any position.

```
Person
  id
  name              # "Shri. Jaydeep More"
  phone             # personal mobile
  email             # personal email
  bio               # short biography
  linkedin_url
  twitter_handle
  profile_data      # JSON: news articles, enrichment cache
  metadata          # JSON: anything else
```

### Organisation

Any body — government, private, civil society. Polymorphically attachable to Ward, Prabhag, or standalone.

```
Organisation
  id
  name              # "BMC", "Ward A Office", "Colaba ALM", "MMRDA"
  org_type           # free-form: "municipal_corporation", "ward_office",
                     #   "development_authority", "alm", "ngo", "political_party",
                     #   "police_station", "fire_station", "utility"
  organisable_type   # "Ward", "Prabhag", nil
  organisable_id     # links to a place (optional)
  parent_id          # FK to parent Organisation (optional tree structure)
  website
  jurisdiction       # "Greater Mumbai", "Ward A", etc.
```

**Key**: `organisable` is optional and polymorphic. An org *can* be tied to a Ward or Prabhag, but doesn't have to be. MMRDA is a standalone org. An ALM might be tied to a Prabhag. BMC ward offices are tied to Wards.

### Department

A functional unit within an organisation. Optional — small orgs might not have departments.

```
Department
  id
  name              # "Maintenance", "Water Works", "Advocacy", "Legal"
  organisation_id   # FK to Organisation
  description
```

### Position

A seat in an org/department. The role exists regardless of who fills it. Functional contact info (email that belongs to the role) lives here.

```
Position
  id
  designation       # "Assistant Commissioner", "President", "Coordinator"
  department_id     # FK to Department
  email             # functional email: ac.a@mcgm.gov.in (belongs to the seat)
  level             # "senior", "mid", "junior" (optional)
  elected           # boolean
  political_party   # for elected positions
  person_id         # FK to Person (nullable = vacant)
  started_on        # when this person started
  ended_on          # when they left (null = current)
  active            # boolean
  metadata          # JSON
```

## Relationships

```
Person
  has_many :positions
  # "Where does this person work / what do they do?"

Position
  belongs_to :person (optional)
  belongs_to :department
  has_one :organisation, through: :department
  # "Who sits in this seat?"

Department
  belongs_to :organisation
  has_many :positions

Organisation
  belongs_to :organisable, polymorphic: true (optional)
  belongs_to :parent, class_name: "Organisation" (optional)
  has_many :children, class_name: "Organisation", foreign_key: :parent_id
  has_many :departments
```

## Examples

### BMC Ward Office

```ruby
bmc = Organisation.create!(name: "BMC", org_type: "municipal_corporation")

ward_a = Ward.find_by(ward_code: "A")
ward_a_office = Organisation.create!(
  name: "Ward A Office",
  org_type: "ward_office",
  organisable: ward_a,
  parent: bmc
)

maintenance = Department.create!(organisation: ward_a_office, name: "Maintenance")

jaydeep = Person.create!(name: "Shri. Jaydeep More", phone: "9969666505")
Position.create!(
  designation: "Assistant Commissioner",
  department: Department.create!(organisation: ward_a_office, name: "Ward Office"),
  email: "ac.a@mcgm.gov.in",
  level: "senior",
  person: jaydeep,
  active: true,
  started_on: Date.new(2022, 6, 1)
)
```

### ALM (Advanced Locality Management)

```ruby
colaba_alm = Organisation.create!(
  name: "Colaba Residents ALM",
  org_type: "alm",
  organisable: Prabhag.find_by(number: 227)
)

Position.create!(
  designation: "President",
  department: Department.create!(organisation: colaba_alm, name: "Committee"),
  person: Person.create!(name: "Rajan Mehta", phone: "9820123456"),
  active: true
)
```

### MMRDA (standalone, no ward)

```ruby
mmrda = Organisation.create!(
  name: "MMRDA",
  org_type: "development_authority",
  website: "https://mmrda.maharashtra.gov.in"
)
```

### Elected Corporator

```ruby
prabhag_225 = Prabhag.find_by(number: 225)
prabhag_org = Organisation.create!(
  name: "Prabhag 225",
  org_type: "prabhag",
  organisable: prabhag_225
)

elected_dept = Department.create!(organisation: prabhag_org, name: "Elected Representatives")
Position.create!(
  designation: "Corporator",
  department: elected_dept,
  person: Person.create!(name: "Smt. Sneha Patil"),
  elected: true,
  political_party: "BJP",
  active: true,
  started_on: Date.new(2026, 2, 1)
)
```

## Transfers

When Jaydeep More transfers from Ward A to Ward D:

```ruby
# End tenure at Ward A
old_position = Position.find_by(email: "ac.a@mcgm.gov.in", active: true)
old_position.update!(active: false, ended_on: Date.current, person: nil)

# Start tenure at Ward D
new_position = Position.find_by(email: "ac.d@mcgm.gov.in", active: true)
new_position.update!(person: jaydeep, started_on: Date.current)
```

Person record untouched. Bio, LinkedIn, news — all preserved.

## Additional Charge

Manish Valanju is AC of both K East and K North:

```ruby
manish = Person.find_by(name: "Shri. Manish Valanju")

# Two active positions, same person
Position.find_by(email: "ac.ke@mcgm.gov.in").update!(person: manish, active: true)
Position.find_by(email: "ac.kn@mcgm.gov.in").update!(person: manish, active: true)
# K North might not have its own email, in which case just designation-based
```

## Querying

```ruby
# Who runs Ward A?
ward_a_org = Organisation.find_by(organisable: ward, org_type: "ward_office")
ward_a_org.departments.flat_map { |d| d.positions.where(active: true).includes(:person) }

# All organisations operating in Ward A (BMC office + ALMs + NGOs)
Organisation.where(organisable: ward)

# Where has a person served?
person.positions.order(started_on: :desc)
person.positions.where(active: true)  # current roles

# All ACs across all wards
Position.where(designation: "Assistant Commissioner", active: true).includes(:person)

# History of a position (who has been AC of Ward A?)
Position.where(email: "ac.a@mcgm.gov.in").includes(:person).order(started_on: :desc)
```

Wait — that last query won't work because we're reusing the same Position record. We need to decide:

**Option A**: One Position row per seat, person_id changes on transfer (current approach)
- Pro: Simple. `active` scope just works.
- Con: Lose history unless we archive separately.

**Option B**: New Position row per tenure, keeping old ones with `ended_on`
- Pro: Full history. "Who was AC of Ward A in 2024?"
- Con: Need to be careful with uniqueness.

**Recommendation: Option B** — create a new Position row for each tenure. The Position table becomes a ledger of assignments.

```ruby
# History of Ward A AC
Position.joins(:department)
  .where(departments: { organisation: ward_a_org }, designation: "Assistant Commissioner")
  .includes(:person)
  .order(started_on: :desc)
# => [
#   {person: "Jaydeep More", started: 2022-06, ended: nil, active: true},
#   {person: "Kiran Dighavkar", started: 2019-03, ended: 2022-06, active: false},
#   ...
# ]
```

## API

### POST /wards/:ward_id/officers

```json
{
  "officers": [
    {
      "designation": "Assistant Commissioner",
      "person_name": "Shri. Jaydeep More",
      "phone": "9969666505",
      "email": "ac.a@mcgm.gov.in",
      "section": "Ward Office",
      "level": "senior",
      "bio": "...",
      "linkedin_url": "...",
      "profile_data": { "news": [...] }
    }
  ]
}
```

The endpoint:
1. Finds or creates Person by name (+ phone for disambiguation)
2. Finds active Position by functional email or designation+department
3. If same person → update contact info on Person
4. If different person → end old tenure (new Position row), start new one
5. If no existing position → create new Position + Person

### Data Flow

```
Parallel AI → Claude Code (enrich-ward skill) → POST /wards/:id/officers → App
                                                          ↓
                                   Person ←── person_id ── Position
                                   (human)                  (seat + tenure)
                                       ↑
                                   Reused across transfers
```

## Migration Path

1. Add `person_id` FK to positions table
2. For each Position with `person_name`, find_or_create Person, set `person_id`
3. Move `bio`, `linkedin_url`, `twitter_handle`, `profile_data` from Position to Person
4. Drop those columns from Position (keep `person_name` as denormalized cache? or drop)
5. Update views: `position.person.name` instead of `position.person_name`
