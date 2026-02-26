# MCGM Civic Monitor

## What This App Does

A civic monitoring and engagement platform for Mumbai's municipal wards. Citizens can:

- **Map** their ward's civic infrastructure — hospitals, schools, construction sites, public facilities
- **Monitor** these facilities over time — track conditions, changes, data snapshots
- **Discuss** — community conversations about what's happening in their ward
- **Act** — create issues, raise tickets, drive accountability

The app is organized around Mumbai's 227 administrative wards (grouped into zones A-K). Each ward contains prabhags (sub-ward units) and has mapped facilities, social media activity (tweets from ward handles), community discussions, and issue tracking.

Geographic boundaries (GeoJSON) provide the spatial scaffolding — wards and prabhags are displayed on interactive Leaflet maps with their facilities plotted as markers.

## Rails Philosophy & Architecture

This application follows Rails conventions with modern Hotwire patterns and minimal JavaScript complexity.

### Core Principles

**Hotwire-First Frontend**
- Uses Turbo and Stimulus exclusively - no additional frontend frameworks
- No separate API namespace - all JSON responses via format handlers
- Progressive enhancement with Stimulus controllers for interactive components

**Testing Philosophy**
- RSpec for testing
- All new features must include comprehensive tests
- NEVER use mocks - use fixtures and real objects for testing

**API Design**
- RESTful routes with format-based responses (`format.html` and `format.json`)
- JSON responses embedded in controller actions, not separate API controllers
- Send all required data in original template render to avoid subsequent API calls
- JBuilder templates for structured JSON output with embedded rendering data

**Development Tools**
- Use Tidewave instead of `rails runner` for console/evaluation tasks
- All code evaluation should use the Tidewave project_eval tool

### Development Workflow

- ALWAYS run the specs first to understand what the application does. we have comprehensive feature specs. `ls -al spec/features` to find the appropriate spec and `bundle exec rspec ....` to run them and see what features exist. 
-  After running the specs, understand whether we need to
   - update an existing spec OR
   - add a new spec
   
   In either case it should be a minimal change. it is an antipattern to make very large changes and if the changeset is huge you should break it down into smaller pieces. 
- We first make changes to the feature spec. We most prefer writing feature specs that don't use javascript, relying on Rails, Turbo and so on to ensure our application works without js as far as practicable. Since this app has a mapping component this will not always be possible to avoid js but for other user workflows we should try.
- After we write the correct feature spec, it should fail. from now we only write code in response to a failing test. 
  - we see if the failure is in the route, controller, service, model or view
  - we write the appropriate spec. for view specs we can depend on controller specs rendering views and the feature spec. separate view specs might be overkill.
  
- We keep writing specs into the lower levels of the stack. Maximum logic and specs should be for models and services. Then a few scenarios for controllers/request specs. The controller spec should mostly verify that we called the correct service/model method. Feature specs should be least in number and should read like the actual business/behaviour of the application.


### Technology Stack

**Backend**
- Rails 8.0.2+ with modern Rails patterns
- SQLite3 for development/testing
- Devise with Google OAuth2 for authentication
- RGeo + RGeo-GeoJSON for spatial data handling
- Solid Cache/Queue/Cable for Rails infrastructure
- Kamal for deployment

**Frontend**
- Hotwire (Turbo + Stimulus) for SPA-like experience
- Tailwind CSS for styling with custom Google Fonts (Inter + Barlow)
- FontAwesome for icons
- Leaflet.js for interactive maps (loaded dynamically)
- Propshaft asset pipeline

**Development Tools**
- Tidewave for Rails console/evaluation
- RuboCop Rails Omakase for code style
- Brakeman for security analysis
- Rails Live Reload for development
- Dotenv for environment variables

### Architecture Patterns

**Semantic Model Finders**
Models implement semantic finder methods for business logic clarity:

```ruby
# Ward and Prabhag models include:
def boundary          # Best available boundary
def approved_boundary # Approved or canonical boundary
def canonical_boundary # Official boundary only
def latest_user_boundary # Most recent user submission
```

**Format-Based JSON Responses**
Controllers respond to both HTML and JSON requests without separate API namespaces:

```ruby
def index
  @wards = Ward.includes(:boundaries, :prabhags).order(:ward_code)

  respond_to do |format|
    format.html # renders wards/index.html.erb
    format.json # renders wards/index.json.jbuilder
  end
end
```

**JBuilder Templates with Embedded Rendering Data**
JSON responses include all necessary data for frontend rendering, eliminating subsequent API calls:

```ruby
# app/views/wards/index.json.jbuilder
feature['properties'].merge!({
  'type' => 'ward',
  'ward_code' => ward.ward_code,
  'color' => '#22c55e',
  'fillOpacity' => 0.3,
  'popup_title' => "Ward #{ward.ward_code}",
  'popup_details' => "#{percentage}% mapped"
})
```

**Stimulus Controllers for Interactions**
JavaScript organized as Stimulus controllers with clear responsibilities:

- `leaflet_map_controller.js` - Home page ward map (Leaflet), loads wards.json, renders boundaries with popups
- `ward_controller.js` - Ward detail map showing ward boundary + prabhag overlays color-coded by source/status
- `boundary_tracer_controller.js` - Interactive polygon drawing (Google Maps) with PDF reference panel, dual-view trace interface
- `places_autocomplete_controller.js` - Google Places autocomplete for location search
- `ward_list_controller.js` - Ward filtering and selection on index page

### Domain Model

**Core Entities**
- `Ward` - Administrative wards (227 total across zones A-K), each with geographic boundaries, a Twitter handle, contact officers
- `Prabhag` - Sub-ward units within wards, with their own boundaries and assignment workflow
- `Facility` - Civic infrastructure (hospitals, schools, construction sites, etc.) mapped within wards with lat/lng coordinates
- `Boundary` - Polymorphic spatial boundaries (GeoJSON) with approval workflow for both wards and prabhags
- `Tweet` - Social media activity from ward Twitter handles, displayed as ward news
- `Discussion` - Community forum threads, polymorphically attached to wards or prabhags
- `Post` - Threaded replies within discussions (supports nesting via parent_id)
- `Ticket` - Issues and work items raised by citizens, tied to wards/prabhags with priority and assignment
- `User` - Authentication with Google OAuth2, role-based permissions, location-aware (ward/prabhag assignment)
- `WardDataSnapshot` - Periodic snapshots of external ward data for change monitoring
- `Person` / `Role` - People associated with wards/prabhags in various capacities (officers, representatives)

**Prabhag Lifecycle**
Prabhags progress through stages that drive what the show page displays and what actions are available:
- `unmapped` — no boundary exists; page shows compelling pitch, PDF reference, sign-in CTA
- `pending` — boundary submitted, awaiting admin review; shows submitted boundary on map, admin inline approve/reject
- `mapped` — boundary approved; shows boundary on map, OSM POIs via HasPois, discussions
- `enriched` — mapped + facility data exists in DB
- `active` — enriched + community discussions exist

Key model methods: `lifecycle_stage`, `computed_mapping_status`, `mapping_status_badge`

**Boundary Management**
- Polymorphic `Boundary` model supporting both Ward and Prabhag boundaries
- `include Approvable` concern provides status predicates and transition methods (`approve!`, `reject!`, `make_canonical!`)
- Status workflow: `pending` → `approved` → `canonical`
- Source tracking: `user_submission`, `kml_import`, `official_import`
- Semantic scopes: `best`, `approved`, `canonical`, `user_submitted`, `official`
- Admin inline review: approve/reject buttons on prabhag show page for admins, POST to admin routes with `return_to` redirect

**Model Concerns**
- `HasPois` — adds `pois(categories:)` method that queries Overpass API via OsmService for OSM POIs within boundary polygon. Included by Prabhag and Ward.
- `Discussable` — polymorphic `has_many :discussions` for community threads. Included by Ward and Prabhag.
- `Approvable` — status predicates (`approved?`, `pending?`, `rejected?`), transition methods, scopes. Included by Boundary.

**Services**
- `OsmService` — queries OpenStreetMap Overpass API for POIs within a GeoJSON boundary polygon. Supports 14 categories (hospital, school, police, etc.). 30s timeout.
- `PrabhagStatusService` — manages prabhag status transitions after boundary approval/rejection. Called by admin boundary controller.
- `BoundaryUpdateService` — handles admin edits to boundaries with `edited_by` tracking.

**Spatial Data**
- GeoJSON storage with RGeo geometry processing
- Boundary geometry methods: `boundary_geometry`, `boundary_area_sqm`, `boundary_center`, `contains_point?`
- Facility mapping with lat/lng coordinates per ward
- Map visualization with Leaflet.js integration
- POI results cached 24h to avoid hammering Overpass API
- Ward-level facility fallback when prabhag-level Overpass returns empty

### Development Conventions

**File Organization**
- Follow Rails conventions strictly
- Stimulus controllers in `app/javascript/controllers/`
- JBuilder templates alongside ERB views
- No separate API directory structure

**Testing Requirements**
- Model tests with comprehensive coverage (see `test/models/boundary_test.rb`)
- Controller tests for both HTML and JSON responses
- System tests for user workflows
- All new features require tests before merge

**Code Style**
- RuboCop Rails Omakase configuration
- No mocks in tests (use fixtures and factories)
- Semantic naming for business logic methods
- Clear separation of concerns between models and controllers

### Key Features

**Civic Infrastructure Mapping**
- Interactive ward maps with Leaflet.js showing facilities (hospitals, schools, construction sites)
- Ward and prabhag boundary visualization from GeoJSON data
- Facility scorecards per ward — what exists, what's missing

**Ward News & Social Monitoring**
- Tweets from ward Twitter handles displayed as ward news
- Track citizen mentions and conversations about ward issues

**Community Engagement**
- Discussion forums attached to wards and prabhags
- Threaded posts with nested replies
- Issue/ticket creation for civic problems with priority and assignment tracking

**Ward Data & Change Monitoring**
- Periodic data snapshots from external sources
- Track changes over time in ward infrastructure and services

**Authentication & Authorization**
- Google OAuth2 integration with Devise
- Location-aware users (auto-assigned to ward/prabhag based on address)
- Role-based access control for admin functions

**Responsive Design**
- Mobile-first Tailwind CSS implementation
- Progressive enhancement with Stimulus
- FontAwesome icon system

### Deployment

**Infrastructure**
- Kamal deployment configuration
- Docker containerization
- Thruster for HTTP acceleration
- Solid* suite for Rails infrastructure services

**Environment Management**
- Dotenv for local development
- Secrets management via Rails credentials
- Production-ready asset pipeline with Propshaft

---

*A civic monitoring platform built with modern Rails practices — map, monitor, discuss, act.*
