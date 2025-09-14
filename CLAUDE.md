# MCGM Ward Boundary Rails Application

## Rails Philosophy & Architecture

This application follows Rails conventions with modern Hotwire patterns and minimal JavaScript complexity.

### Core Principles

**Hotwire-First Frontend**
- Uses Turbo and Stimulus exclusively - no additional frontend frameworks
- No separate API namespace - all JSON responses via format handlers
- Progressive enhancement with Stimulus controllers for interactive components

**Testing Philosophy**
- MiniTest for all testing (no RSpec)
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

- `ward_boundary_controller.js` - Map rendering and interaction
- `boundary_tracer_controller.js` - Boundary tracing interface
- `places_autocomplete_controller.js` - Location search
- `ward_list_controller.js` - Ward filtering and selection

### Domain Model

**Core Entities**
- `Ward` - Administrative wards with boundary mapping completion tracking
- `Prabhag` - Sub-ward units with individual boundary tracing workflow
- `Boundary` - Polymorphic spatial boundaries with approval workflow
- `Ticket` - Work items for boundary verification and corrections
- `User` - Authentication with Google OAuth2 and role-based permissions

**Boundary Management System**
- Polymorphic `Boundary` model supporting both Ward and Prabhag boundaries
- Status workflow: `pending` → `approved` → `canonical`
- Source tracking: `user_submission`, `kml_import`, `official_import`
- Semantic scopes: `best`, `approved`, `canonical`, `user_submitted`, `official`

**Spatial Data Handling**
- GeoJSON storage with RGeo geometry processing
- Boundary validation and area calculations
- Map visualization with Leaflet.js integration
- Progressive enhancement for non-JavaScript clients

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

**Interactive Boundary Mapping**
- Ward and Prabhag boundary visualization with Leaflet.js
- User-submitted boundary tracing from PDF sources
- Approval workflow for boundary submissions
- Legacy data migration from KML imports

**Authentication & Authorization**
- Google OAuth2 integration with Devise
- Role-based access control for admin functions
- User assignment workflow for boundary tracing tasks

**Responsive Design**
- Mobile-first Tailwind CSS implementation
- Progressive enhancement with Stimulus
- Mumbai skyline branding elements
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

*This application demonstrates modern Rails development practices with minimal JavaScript complexity, comprehensive testing, and clear architectural patterns.*