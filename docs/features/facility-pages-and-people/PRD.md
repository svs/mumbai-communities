# Facility Pages, People Directory, and Wiki-Style Contributions
# Product Requirements Document

## Executive Summary

This platform tracks Mumbai's civic infrastructure at the prabhag (neighborhood) level. Today, facilities appear as dots on a map and names in a list. People -- corporators, ward officers -- are either absent or shown as static text on the ward info page. There is no way for a citizen to say "this school's phone number is ..." or "this park has been closed for months."

This PRD covers three interconnected features that turn the platform from a read-only map into a living, citizen-contributed wiki of civic infrastructure:

1. **Facility Pages** -- every school, hospital, park, and toilet gets its own page with a map, discussions, photos, and wiki-editable contact information.
2. **People Directory** -- every prabhag shows its corporator; every ward shows its ward officer. Citizens can contribute missing contact details.
3. **Wiki-Style Contributions** -- a generic edit-tracking system that lets logged-in users add or correct information, with full audit history.

The design philosophy is Wikimapia: if official data is missing, citizens fill the gaps. The platform becomes more useful the more people contribute.

---

## Problem Statement

Citizens of Mumbai have no single place to:
- Look up a specific civic facility (school, hospital, toilet) and see its contact details, hours, or current status
- Find out who their elected corporator is, or how to reach the ward officer
- Contribute corrections when official data is wrong or missing

The existing platform has facility data (imported from OSM and BMC sources via `OsmFacilityImporter`) but only displays it as map markers and list items within the ward context. There are no individual facility pages, no way to discuss a specific facility, and no mechanism for citizen contributions.

The `Person` and `Role` models exist in the database but are only surfaced in a minimal "Ward Directory" section on the ward info tab. There is no people display at the prabhag level, and no way for citizens to add missing information.

---

## Goals and Objectives

### Primary Goals
- Every persisted `Facility` record gets a publicly accessible page
- Every prabhag page shows its corporator; every ward page shows its ward officer and key staff
- Logged-in users can add/edit facility details and people contact information
- All edits are tracked with full audit history (who, when, what changed)

### Success Metrics
- Number of facility pages viewed per week
- Number of wiki contributions per week
- Percentage of prabhags with corporator information filled in
- Percentage of facilities with at least one citizen-contributed field (phone, hours, photo)

### Non-Goals
- Real-time facility status monitoring (e.g., "hospital has 3 beds available") -- out of scope
- Automated data syncing between wiki edits and OSM -- out of scope
- User reputation or karma systems -- out of scope for this phase
- Mobile app -- the responsive web interface is sufficient
- Replacing the OSM or BMC data pipeline -- wiki contributions supplement, not replace, imported data

---

## User Personas

### Anonymous Visitor
A Mumbaikar searching for a specific facility. Found the page via Google or a shared link. Wants: name, location, phone number, hours. Does not want to sign up just to see basic information. May be converted into a contributor if the "Help us add the phone number" CTA is compelling.

### Logged-in Resident
Lives in or near a prabhag. Knows things the platform does not: the school's actual name (the OSM data says "Unnamed School"), the toilet's hours, the corporator's office address. Wants: to contribute what they know, see their contributions acknowledged, and feel like they are building something useful for their neighborhood.

### Civic Journalist / Activist
Uses the platform to research and monitor civic infrastructure. Wants: to see who is responsible for a ward, compare facility coverage across wards, identify gaps, and use the discussion system to raise issues about specific facilities.

### Admin
Manages data quality. Wants: to see a queue of recent contributions, approve or flag edits, and ensure the wiki does not fill up with spam or incorrect data.

---

## Feature 1: Facility Pages

### Current State

The `Facility` model exists with these fields:
- `name`, `facility_type`, `source`, `external_id`
- `ward_code`, `prabhag_number`
- `latitude`, `longitude`, `address`
- `raw_data` (JSON), `content_hash`, `last_seen_at`

Facilities are imported by `OsmFacilityImporter` (from Overpass API) and from BMC data sources. They appear in:
- The ward facilities index (`/wards/:ward_id/facilities`) as a list and GeoJSON for map markers
- The ward info tab as filter checkboxes and a scrollable list
- The ward scorecard comparing OSM vs BMC counts

There is no `show` action, no individual facility page, and no way to interact with a specific facility.

### What Changes

Each facility gets its own page. The Facility model gains:
- `include Discussable` -- discussions about this specific facility
- ActiveStorage attachments for photos
- Wiki-editable fields tracked via the Contribution system (Feature 3)

### Page Layout: `/facilities/:id`

**Breadcrumb:** Ward K North > Prabhag 74 > Facilities > Vile Parle Municipal School

**Header Section:**
- Facility name (large)
- Facility type badge (e.g., "School" in blue, "Hospital" in red -- reuse existing color scheme from `index.json.jbuilder`)
- Data source badge: "OSM", "BMC", or "Citizen-contributed"
- If name is "Unnamed [type]": prominent "Help us name this facility" CTA

**Map Section:**
- Small Leaflet map centered on the facility's coordinates
- Single marker for this facility
- Shows the prabhag boundary polygon as context (if the facility's prabhag has an approved boundary)

**Details Section (wiki-editable):**
- Address (pre-filled from `address` field if present)
- Phone number
- Email
- Operating hours
- Description / notes
- Each field shows: current value (or "Not yet added"), a pencil icon for edit (logged-in only), and "Last edited by [name] on [date]" if it has been contributed

**Photos Section:**
- Grid of citizen-uploaded photos
- "Add a photo" button (logged-in only)
- Each photo shows uploader name and date

**Verification Section:**
- "Last verified: [date] by [name]" or "This facility has not been verified"
- "I visited this facility -- it still exists and is operational" button (logged-in only)
- "Report an issue" button -- opens a short form (what's wrong: closed/demolished/incorrect-info/other + free text)

**Discussions Section:**
- Recent discussions about this facility (reuse the existing Discussable pattern)
- "Start a discussion" link (logged-in only)
- Identical behavior to ward/prabhag discussions

**Edit History Section (collapsible):**
- Chronological list of all contributions to this facility
- Shows: field changed, old value, new value, who, when

### Functional Requirements

**FR-F1: Facility Show Action**

Add a `show` action to a new top-level `FacilitiesController` (not nested under wards -- facilities have their own identity):

```ruby
# app/controllers/facilities_controller.rb
class FacilitiesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @facility = Facility.find(params[:id])
    @ward = @facility.ward
    @prabhag = Prabhag.find_by(number: @facility.prabhag_number, ward_code: @facility.ward_code)
    @contributions = @facility.contributions.includes(:user).order(created_at: :desc)
    @discussions = @facility.discussions.not_archived.recent.limit(5)
  end
end
```

**FR-F2: Facility Model Changes**

```ruby
class Facility < ApplicationRecord
  include Discussable

  has_many :contributions, as: :contributable, dependent: :destroy
  has_many :verifications, dependent: :destroy
  has_many_attached :photos

  belongs_to :ward, foreign_key: "ward_code", primary_key: "ward_code", optional: true
  belongs_to :prabhag, foreign_key: "prabhag_number", primary_key: "number", optional: true

  # Existing code unchanged...

  # Wiki-editable fields -- these are the fields citizens can contribute
  WIKI_FIELDS = %w[phone email operating_hours description].freeze

  def display_name
    name.presence || "Unnamed #{facility_type.humanize}"
  end

  def last_verified_at
    verifications.order(created_at: :desc).first&.created_at
  end

  def last_verified_by
    verifications.order(created_at: :desc).first&.user
  end

  def wiki_value(field_name)
    # Most recent approved contribution for this field
    contributions
      .where(field_name: field_name)
      .order(created_at: :desc)
      .first
      &.new_value
  end
end
```

**FR-F3: Add Columns to Facilities Table**

New migration adds wiki-editable fields directly on the facility:

```ruby
add_column :facilities, :phone, :string
add_column :facilities, :email, :string
add_column :facilities, :operating_hours, :string
add_column :facilities, :description, :text
add_column :facilities, :last_verified_at, :datetime
add_column :facilities, :last_verified_by_id, :integer
add_column :facilities, :photos_count, :integer, default: 0
```

**Decision: store wiki values on the Facility record directly, not only in Contributions.** The Contribution table is the audit log. The Facility table holds the current values. When a user submits a contribution, we update the facility field AND create a Contribution record. This keeps reads fast (no joins to get current phone number) while maintaining full history.

**FR-F4: Facility Discussions**

Adding `include Discussable` to Facility gives it `has_many :discussions, as: :discussable`. Routes:

```ruby
resources :facilities, only: [:show] do
  scope module: :facilities do
    resources :discussions, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :posts, only: [:create, :edit, :update, :destroy]
    end
  end
end
```

The discussion controllers for facilities follow the exact same pattern as `Wards::DiscussionsController` and `Prabhags::DiscussionsController`. Extract a shared concern or use STI? No -- keep it simple. Copy the pattern. Three small controllers are clearer than one abstract one.

**FR-F5: Facility Photos**

Use ActiveStorage:

```ruby
class Facility < ApplicationRecord
  has_many_attached :photos
end
```

Photos controller action (nested under facility):

```ruby
# POST /facilities/:facility_id/photos
class Facilities::PhotosController < ApplicationController
  def create
    @facility = Facility.find(params[:facility_id])
    @facility.photos.attach(params[:photo])
    # Also create a Contribution record for the photo upload
    @facility.contributions.create!(
      user: current_user,
      field_name: 'photo',
      new_value: @facility.photos.last.filename.to_s,
      contribution_type: 'photo_upload'
    )
    redirect_to @facility, notice: "Photo added."
  end
end
```

**FR-F6: Facility Verification**

A verification is a citizen confirming "I was here, it exists." Simple model:

```ruby
class Verification < ApplicationRecord
  belongs_to :facility
  belongs_to :user

  validates :user_id, uniqueness: {
    scope: [:facility_id],
    conditions: -> { where("created_at > ?", 30.days.ago) },
    message: "can only verify a facility once per 30 days"
  }
end
```

Migration:

```ruby
create_table :verifications do |t|
  t.references :facility, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.text :notes
  t.timestamps
end
```

**FR-F7: Issue Reporting**

"Report an issue" creates a Ticket (existing model) with `ticket_type: 'facility_issue'` linked to the facility's ward and prabhag:

```ruby
# POST /facilities/:facility_id/issues
class Facilities::IssuesController < ApplicationController
  def create
    @facility = Facility.find(params[:facility_id])
    @ticket = Ticket.create!(
      title: "Issue with #{@facility.display_name}",
      description: params[:description],
      ticket_type: 'facility_issue',
      ward_code: @facility.ward_code,
      prabhag_number: @facility.prabhag_number,
      created_by: current_user,
      location_latitude: @facility.latitude,
      location_longitude: @facility.longitude
    )
    redirect_to @facility, notice: "Issue reported. Thank you."
  end
end
```

### Routes

```ruby
# Top-level facility pages
resources :facilities, only: [:show] do
  scope module: :facilities do
    resources :discussions, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :posts, only: [:create, :edit, :update, :destroy]
    end
    resources :photos, only: [:create, :destroy]
    resources :issues, only: [:new, :create]
  end
  member do
    post :verify
    post :contribute  # wiki edit submission
  end
end

# Keep existing ward-scoped facilities index
resources :wards, only: [:index, :show] do
  # ... existing routes ...
  scope module: :wards do
    resources :facilities, only: [:index] do
      collection do
        get :scorecard
      end
    end
  end
end
```

**Why top-level `/facilities/:id` instead of nested?**

- A facility belongs to a ward, but its page is about the facility, not the ward
- `/facilities/42` is cleaner and more shareable than `/wards/k-north/facilities/42`
- The breadcrumb provides navigational context back to the ward/prabhag
- SEO: facility pages are independently valuable content

The existing ward-scoped index (`/wards/:ward_id/facilities`) remains for the ward context view (list + map markers). The new top-level route is for the individual facility show page.

---

## Feature 2: People Directory

### Current State

The `Person` model has: `name`, `phone`, `email`, `notes`, `metadata` (JSON).

The `Role` model is polymorphic on `roleable` (Ward or Prabhag) with: `role_name`, `started_at`, `ended_at`, `metadata` (JSON). It has an `active` scope.

Ward already has `has_many :roles, as: :roleable` and `has_many :people, through: :roles`. Prabhag has the same. The ward info page (`info.html+newspaper.erb`) already displays ward roles in a "Ward Directory" section.

What is missing:
- No people display on prabhag pages
- No way for citizens to add/edit people information
- No individual person pages
- No "Help us find this information" CTA when data is absent
- Person records may not exist for most prabhags (corporators not yet seeded)

### What Changes

**Prabhag pages** gain a "Your Representatives" section showing the corporator and any other roles.

**Ward pages** keep the existing "Ward Directory" section, enhanced with wiki-edit capabilities.

**Person model** gains wiki-editable fields tracked via Contributions.

Both Ward and Prabhag pages gain a "Help us add this information" CTA when people data is missing.

### Prabhag Show Page: Representatives Section

Displayed after the map/POI sections, before discussions. Only shown for mapped+ prabhags (consistent with the lifecycle stage philosophy from the prabhag-show-redesign PRD).

```
Your Representatives

  Corporator
  [Photo placeholder]  Rajesh Sharma
                       Shiv Sena (UBT)
                       Office: 104, Municipal Building, Vile Parle
                       Phone: 022-2614-XXXX
                       Last updated by Priya M. on Jan 15, 2026

  -- or, if no corporator record exists --

  Corporator
  [Empty state]  "Who is your corporator? Help us add this information."
                 [Add Corporator Info] button (logged-in only)
```

### Ward Info Page: Enhanced Directory

The existing "Ward Directory" section already shows roles. Enhance it with:
- Edit buttons next to each field (logged-in only)
- "Last updated by [name] on [date]" provenance
- "Help us add" CTAs for missing fields (phone, email)
- Add a party affiliation display for corporators (stored in Role metadata)

### Functional Requirements

**FR-P1: Prabhag People Display**

In `PrabhagsController#show`, load roles:

```ruby
def show
  # ... existing code ...
  @prabhag_roles = @prabhag.roles.active.includes(:person).order(:role_name)
  @corporator = @prabhag_roles.find { |r| r.role_name == 'corporator' }
end
```

**FR-P2: Add Party Affiliation to Role**

The Role model's `metadata` JSON field can store `party_affiliation`. No schema change needed. Add a convenience method:

```ruby
class Role < ApplicationRecord
  # ... existing code ...

  def party_affiliation
    metadata&.dig('party_affiliation')
  end

  def party_affiliation=(value)
    self.metadata = (metadata || {}).merge('party_affiliation' => value)
  end
end
```

**FR-P3: Person Wiki Edits**

Person records are wiki-editable via the Contribution system (Feature 3). When a citizen adds a corporator's phone number, this creates:
1. An update to the Person record's `phone` field
2. A Contribution record tracking the change

```ruby
class Person < ApplicationRecord
  has_many :contributions, as: :contributable, dependent: :destroy

  WIKI_FIELDS = %w[phone email notes].freeze
end
```

**FR-P4: Creating New Person + Role Records**

When a prabhag has no corporator, a logged-in user can submit one. This is a wiki contribution that creates both records:

```ruby
# POST /prabhags/:prabhag_id/people
class Prabhags::PeopleController < ApplicationController
  def create
    @prabhag = Prabhag.find(params[:prabhag_id])

    person = Person.find_or_initialize_by(name: params[:name])
    person.update!(
      phone: params[:phone],
      email: params[:email]
    )

    role = @prabhag.roles.find_or_initialize_by(
      person: person,
      role_name: params[:role_name]
    )
    role.update!(
      started_at: params[:started_at],
      metadata: { party_affiliation: params[:party_affiliation] }
    )

    Contribution.create!(
      contributable: person,
      user: current_user,
      field_name: 'new_person',
      new_value: person.name,
      contribution_type: 'person_creation'
    )

    redirect_to @prabhag, notice: "Thank you! The information has been added."
  end
end
```

**FR-P5: Person Show Page (Optional, Phase 2)**

Individual person pages (`/people/:id`) showing:
- Name, photo, contact details
- All roles (current and past)
- Contributions history
- Link to each associated ward/prabhag

This is a "Could Have" -- the primary display is on prabhag/ward pages.

### Routes

```ruby
resources :prabhags, only: [:index, :show] do
  # ... existing routes ...
  scope module: :prabhags do
    resources :people, only: [:new, :create, :edit, :update]
    # ... existing discussion routes ...
  end
end

resources :wards, only: [:index, :show] do
  # ... existing routes ...
  scope module: :wards do
    resources :people, only: [:new, :create, :edit, :update]
    # ... existing routes ...
  end
end

# Optional: top-level person pages
resources :people, only: [:show]
```

---

## Feature 3: Wiki-Style Contributions

### Design Philosophy

Every piece of citizen-contributed data goes through the same system:
- A logged-in user edits a field
- The system records what changed, who changed it, and when
- The new value is applied immediately (auto-approve by default)
- Admins can review recent contributions and revert bad edits
- Edit history is visible on every page

This is not a complex CMS. It is a simple append-only audit log with the current value stored directly on the model.

### The Contribution Model

```ruby
# app/models/contribution.rb
class Contribution < ApplicationRecord
  belongs_to :contributable, polymorphic: true
  belongs_to :user

  validates :field_name, presence: true
  validates :contribution_type, presence: true,
    inclusion: { in: %w[field_edit photo_upload person_creation verification] }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_field, ->(field) { where(field_name: field) }
  scope :by_user, ->(user) { where(user: user) }
end
```

Migration:

```ruby
create_table :contributions do |t|
  t.string :contributable_type, null: false
  t.integer :contributable_id, null: false
  t.references :user, null: false, foreign_key: true
  t.string :field_name, null: false
  t.text :old_value
  t.text :new_value
  t.string :contribution_type, null: false  # field_edit, photo_upload, person_creation, verification
  t.text :admin_notes                        # for moderation
  t.boolean :reverted, default: false
  t.integer :reverted_by_id
  t.datetime :reverted_at
  t.timestamps

  t.index [:contributable_type, :contributable_id], name: 'index_contributions_on_contributable'
  t.index [:user_id, :created_at]
  t.index [:contribution_type]
end
```

### The Contributable Concern

```ruby
# app/models/concerns/contributable.rb
module Contributable
  extend ActiveSupport::Concern

  included do
    has_many :contributions, as: :contributable, dependent: :destroy
  end

  # Apply a wiki edit: update the field and record the contribution
  def wiki_update!(field_name, new_value, user:)
    raise ArgumentError, "#{field_name} is not wiki-editable" unless self.class::WIKI_FIELDS.include?(field_name)

    old_value = send(field_name)
    return if old_value == new_value

    transaction do
      update!(field_name => new_value)
      contributions.create!(
        user: user,
        field_name: field_name,
        old_value: old_value.to_s,
        new_value: new_value.to_s,
        contribution_type: 'field_edit'
      )
    end
  end

  # Get the last contribution for a specific field
  def last_edit_for(field_name)
    contributions.for_field(field_name).recent.first
  end
end
```

Models that include Contributable:

```ruby
class Facility < ApplicationRecord
  include Contributable
  WIKI_FIELDS = %w[name phone email operating_hours description address].freeze
end

class Person < ApplicationRecord
  include Contributable
  WIKI_FIELDS = %w[phone email notes].freeze
end
```

### Contribution Controller

A single polymorphic controller handles all wiki edits:

```ruby
# app/controllers/contributions_controller.rb
class ContributionsController < ApplicationController
  before_action :set_contributable

  def create
    @contributable.wiki_update!(
      params[:field_name],
      params[:new_value],
      user: current_user
    )

    redirect_back fallback_location: @contributable, notice: "Updated. Thank you for contributing!"
  rescue ArgumentError => e
    redirect_back fallback_location: @contributable, alert: e.message
  end

  private

  def set_contributable
    @contributable = params[:contributable_type].constantize.find(params[:contributable_id])
    # Security: only allow whitelisted types
    unless %w[Facility Person].include?(@contributable.class.name)
      raise ActiveRecord::RecordNotFound
    end
  end
end
```

### Admin Moderation

Admins see a contributions queue:

```ruby
# app/controllers/admin/contributions_controller.rb
module Admin
  class ContributionsController < ApplicationController
    before_action :require_admin

    def index
      @contributions = Contribution.includes(:user, :contributable)
                                   .recent
                                   .page(params[:page])
                                   .per(50)
    end

    def revert
      @contribution = Contribution.find(params[:id])
      @contributable = @contribution.contributable

      @contributable.update!(@contribution.field_name => @contribution.old_value)
      @contribution.update!(reverted: true, reverted_by_id: current_user.id, reverted_at: Time.current)

      redirect_to admin_contributions_path, notice: "Contribution reverted."
    end
  end
end
```

### Wiki Edit UI Pattern

Every wiki-editable field follows the same UI pattern. This should be a shared partial:

```erb
<%# app/views/shared/_wiki_field.html.erb %>
<%# locals: contributable, field_name, label, value, field_type: 'text' %>

<div class="flex items-start justify-between py-2 border-b border-stone-100">
  <div class="flex-1">
    <div class="text-xs uppercase tracking-wider text-stone-400"><%= label %></div>
    <% if value.present? %>
      <div class="text-stone-800 mt-0.5"><%= value %></div>
      <% last_edit = contributable.last_edit_for(field_name) %>
      <% if last_edit %>
        <div class="text-xs text-stone-400 mt-0.5">
          Updated by <%= last_edit.user.name %> on <%= last_edit.created_at.strftime("%b %d, %Y") %>
        </div>
      <% end %>
    <% else %>
      <div class="text-stone-400 italic mt-0.5">Not yet added</div>
    <% end %>
  </div>

  <% if user_signed_in? %>
    <!-- Inline edit form, toggled by Stimulus controller -->
    <button data-action="click->wiki-edit#toggle" class="text-stone-400 hover:text-stone-600">
      <i class="fas fa-pencil-alt text-xs"></i>
    </button>
    <div data-wiki-edit-target="form" class="hidden mt-2 w-full">
      <%= form_with url: contributions_path, method: :post, class: "flex gap-2" do |f| %>
        <%= f.hidden_field :contributable_type, value: contributable.class.name %>
        <%= f.hidden_field :contributable_id, value: contributable.id %>
        <%= f.hidden_field :field_name, value: field_name %>
        <% if field_type == 'textarea' %>
          <%= f.text_area :new_value, value: value, class: "flex-1 text-sm border rounded px-2 py-1", rows: 3 %>
        <% else %>
          <%= f.text_field :new_value, value: value, class: "flex-1 text-sm border rounded px-2 py-1" %>
        <% end %>
        <%= f.submit "Save", class: "text-sm bg-stone-800 text-white px-3 py-1 rounded" %>
      <% end %>
    </div>
  <% else %>
    <span class="text-xs text-stone-400">
      <%= link_to "Sign in to edit", new_user_session_path, class: "underline" %>
    </span>
  <% end %>
</div>
```

### Stimulus Controller for Inline Editing

```javascript
// app/javascript/controllers/wiki_edit_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  toggle() {
    this.formTarget.classList.toggle("hidden")
  }
}
```

This is minimal JavaScript -- just toggling form visibility. The form submission is a standard Rails POST with redirect, using Turbo for seamless page updates.

---

## Data Model Changes Summary

### New Tables

| Table | Purpose |
|-------|---------|
| `contributions` | Audit log for all wiki edits |
| `verifications` | Citizens confirming a facility still exists |

### Modified Tables

| Table | Changes |
|-------|---------|
| `facilities` | Add `phone`, `email`, `operating_hours`, `description`, `last_verified_at`, `last_verified_by_id` |

### New Concerns

| Concern | Applied to |
|---------|-----------|
| `Contributable` | Facility, Person |

### Model Changes

| Model | Change |
|-------|--------|
| `Facility` | Add `include Discussable`, `include Contributable`, ActiveStorage photos |
| `Person` | Add `include Contributable` |
| `Role` | Add convenience methods for `party_affiliation` from metadata |

### No Changes Needed

| Model | Why |
|-------|-----|
| `Ward` | Already has `has_many :roles` and Discussable |
| `Prabhag` | Already has `has_many :roles` and Discussable |
| `Discussion` | Already polymorphic -- works with Facility out of the box |
| `Ticket` | Already has `ticket_type` -- use 'facility_issue' for reports |
| `Boundary` | No changes |

---

## Routes Summary

```ruby
# New top-level facility pages
resources :facilities, only: [:show] do
  scope module: :facilities do
    resources :discussions, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :posts, only: [:create, :edit, :update, :destroy]
    end
    resources :photos, only: [:create, :destroy]
    resources :issues, only: [:new, :create]
  end
  member do
    post :verify
  end
end

# Wiki contributions (polymorphic)
resources :contributions, only: [:create]

# People on prabhag pages
resources :prabhags, only: [:index, :show] do
  scope module: :prabhags do
    resources :people, only: [:new, :create, :edit, :update]
    # existing discussion routes unchanged
  end
end

# People on ward pages
resources :wards, only: [:index, :show] do
  scope module: :wards do
    resources :people, only: [:new, :create, :edit, :update]
    # existing routes unchanged
  end
end

# Admin moderation
namespace :admin do
  resources :contributions, only: [:index] do
    member do
      post :revert
    end
  end
  # existing admin routes unchanged
end

# Optional: top-level person pages
resources :people, only: [:show]
```

---

## User Stories

### Must Have

**US-1: View a facility page**
As an anonymous visitor, I want to visit a facility page and see its name, type, location on a map, and any available contact information, so that I can find what I need about a civic facility.

Acceptance criteria:
- `/facilities/:id` renders an HTML page with facility name, type badge, and map
- Breadcrumb shows: Ward > Prabhag > Facility name
- If the facility has no name, show "Unnamed [type]"
- Data source badge shows "OSM", "BMC", or "Citizen" based on `source` field
- All wiki fields are shown, even if empty (with "Not yet added" placeholder)
- Page is accessible without login

**US-2: Edit a facility's contact information**
As a logged-in resident, I want to add or edit a facility's phone number, email, hours, or description, so that other citizens can find this information.

Acceptance criteria:
- Each wiki field shows an edit icon (pencil) when logged in
- Clicking the edit icon reveals an inline form
- Submitting the form updates the field and creates a Contribution record
- The page shows "Updated by [my name] on [today]" after the edit
- Edit history is visible in a collapsible section

**US-3: View edit history for a facility**
As a visitor, I want to see who has edited a facility's information and when, so that I can assess the reliability of the data.

Acceptance criteria:
- Each wiki field shows "Updated by [name] on [date]" if it has been edited
- A collapsible "Edit history" section shows all contributions in reverse chronological order
- Each history entry shows: field changed, old value, new value, who, when

**US-4: See my corporator on the prabhag page**
As an anonymous visitor, I want to see who my corporator is when I visit my prabhag page, so that I know who represents me.

Acceptance criteria:
- Prabhag show page has a "Your Representatives" section (visible for mapped+ prabhags)
- Shows corporator name, party affiliation (if available), and contact details
- If no corporator record exists, shows "Who is your corporator? Help us add this information."

**US-5: Add a corporator to a prabhag**
As a logged-in resident, I want to add corporator information for my prabhag when it is missing, so that other residents can find their representative.

Acceptance criteria:
- "Add Corporator Info" button visible on prabhag page when no corporator exists and user is logged in
- Form collects: name, party affiliation, phone, email, office address
- Submitting creates a Person record, a Role record (role_name: 'corporator', roleable: prabhag), and a Contribution record
- The prabhag page immediately shows the new corporator

**US-6: Facility links from ward/prabhag pages**
As a visitor viewing a ward's facility list, I want to click on a facility name and go to its individual page, so that I can see details about that specific facility.

Acceptance criteria:
- Facility names in the ward facilities index are links to `/facilities/:id`
- Facility names in the prabhag POI list are links to facility pages (for persisted Facility records; live POIs without persisted records show as non-linked text)
- Map popup for a facility marker includes a "View details" link

### Should Have

**US-7: Upload a photo of a facility**
As a logged-in resident, I want to upload a photo of a facility I visited, so that others can see what it looks like.

Acceptance criteria:
- "Add a photo" button on facility page (logged-in only)
- Accepts JPEG, PNG, WebP; max 10MB
- Photo appears in the photos grid after upload
- Shows uploader name and date
- Creates a Contribution record of type 'photo_upload'

**US-8: Verify a facility exists**
As a logged-in resident, I want to confirm that a facility I visited still exists and is operational, so that the data stays current.

Acceptance criteria:
- "Verify this facility" button on facility page (logged-in only)
- Updates `last_verified_at` and `last_verified_by`
- Shows "Last verified [date] by [name]" on the page
- A user can verify the same facility at most once per 30 days

**US-9: Report an issue with a facility**
As a logged-in resident, I want to report that a facility is closed, demolished, or has incorrect information, so that the data can be corrected.

Acceptance criteria:
- "Report an issue" button on facility page (logged-in only)
- Form with issue type dropdown (closed/demolished/incorrect-info/other) and free text description
- Creates a Ticket with `ticket_type: 'facility_issue'`
- Confirmation message after submission

**US-10: Ward directory with wiki edits**
As a logged-in resident, I want to edit ward officer contact details on the ward info page, so that the information stays current.

Acceptance criteria:
- Existing ward directory section gains edit icons for phone and email fields
- Edits follow the same wiki contribution pattern as facility edits
- "Last updated by" provenance shown per field

**US-11: Admin contributions moderation queue**
As an admin, I want to see a list of recent wiki contributions and revert bad edits, so that data quality is maintained.

Acceptance criteria:
- `/admin/contributions` shows recent contributions with: contributable link, field, old value, new value, user, date
- "Revert" button restores the old value and marks the contribution as reverted
- Reverted contributions show "Reverted by [admin] on [date]" in the edit history

### Could Have

**US-12: Individual person pages**
As a visitor, I want to click on a person's name and see all their roles and contact details on a dedicated page.

**US-13: Top contributors display**
As a visitor, I want to see who the most active contributors are, so that the wiki contribution effort is recognized.

**US-14: Facility search**
As a visitor, I want to search for facilities by name or type across all wards, so that I can find a specific facility.

**US-15: Facility comparison across prabhags**
As a civic activist, I want to compare facility counts across prabhags within a ward, so that I can identify underserved areas.

### Won't Have (this phase)

- Automated moderation or spam detection
- User reputation/karma system
- Real-time facility status (beds available, waiting time)
- OSM writeback (syncing wiki edits back to OpenStreetMap)
- Mobile app
- Notification system for edit conflicts or contributions

---

## Non-Functional Requirements

### Performance
- Facility show page must load in under 500ms (no Overpass API calls on the facility page -- all data is from the database)
- Contribution creation must be a single database transaction (update + insert)
- Facility photos served via ActiveStorage with CDN-friendly URLs
- Admin contributions list must handle 10,000+ records with pagination

### Security
- Wiki edits require authentication (`authenticate_user!`)
- Contributable type whitelist prevents arbitrary model updates (only Facility and Person)
- `field_name` validated against model's `WIKI_FIELDS` constant
- Photo uploads validated: type whitelist (JPEG, PNG, WebP), size limit (10MB)
- Admin-only access for contribution revert and moderation queue
- Rate limiting: no more than 20 contributions per user per hour (application-level, not infrastructure)

### Accessibility
- All facility pages have meaningful page titles: "[Facility Name] - [Type] in [Ward Name]"
- Map is supplementary -- all information is available in text below the map
- Photo alt text: "[Facility type] photo uploaded by [user] on [date]"
- Wiki edit forms have proper labels and are keyboard-navigable
- Color is not the only indicator for data source badges (text label always present)

### Compatibility
- Works without JavaScript (facility page content renders server-side; inline edit forms degrade to full-page navigation)
- Turbo-compatible: contributions submitted via Turbo form result in Turbo redirect
- Mobile-responsive layout (Tailwind responsive classes)

---

## Edge Cases and Error Handling

### Facility Page Edge Cases

| Case | Handling |
|------|----------|
| Facility has no coordinates | Do not show map section. Show address if available, otherwise "Location unknown." |
| Facility has no ward association | Breadcrumb shows only "Facilities > [Name]". No ward/prabhag links. |
| Facility has no prabhag_number | Breadcrumb shows "Ward [code] > [Name]". No prabhag link. |
| Facility with prabhag_number but prabhag record does not exist | Treat same as no prabhag. Do not crash. |
| Facility name is nil | Display as "Unnamed [type]" everywhere: page title, breadcrumb, map popup. |
| Facility deleted from OSM but still in our DB | Show facility page normally. `last_seen_at` indicates staleness. Future: flag as "not seen in latest import." |
| Facility has no source badge mapping | Display source string as-is, with neutral gray badge. |
| Multiple facilities at same coordinates | Each gets its own page. Map shows overlapping markers. |
| Facility with malformed raw_data JSON | Ignore raw_data display. Do not crash. Log warning. |

### Wiki Contribution Edge Cases

| Case | Handling |
|------|----------|
| User submits empty value for a field | Treat as clearing the field. Store old value in Contribution. Set field to nil. |
| User submits same value as current | No-op. Do not create a Contribution record. (Checked in `wiki_update!`) |
| Two users edit the same field simultaneously | Last write wins. Both contributions are recorded. No merge conflict -- this is a wiki, not a VCS. |
| User edits a field that was just reverted by admin | Normal edit flow. The revert was just another state change; the new edit overrides it. |
| User tries to edit a non-wiki field via parameter tampering | `wiki_update!` raises ArgumentError for non-WIKI_FIELDS. Controller rescues and shows error. |
| User submits HTML/script in a wiki field | Sanitize all wiki field values on display (Rails auto-escapes in ERB). Store raw. |
| Very long value submitted (e.g., 10,000 character description) | Validate max length at model level: description 2000 chars, other fields 500 chars. |
| Contribution for a deleted contributable | `dependent: :destroy` on the association handles this. Orphan contributions should not exist. |
| Rapid successive edits by same user | Rate limiting: 20 contributions per hour per user. Return 429 if exceeded. |

### People/Role Edge Cases

| Case | Handling |
|------|----------|
| Prabhag has no corporator role | Show "Who is your corporator?" CTA. "Add Corporator Info" button for logged-in users. |
| Prabhag has a corporator with ended_at in the past | Show "Former corporator: [name]" in gray. Show "Current corporator unknown" CTA. |
| User creates a duplicate person (same name, different record) | `find_or_initialize_by(name:)` attempts dedup. If name matches are ambiguous, create new. Admin can merge later. |
| Role with missing person (person deleted) | `belongs_to :person` is required. If person is destroyed, roles cascade delete. Should not happen. If it does, skip display with nil check. |
| Multiple active corporators for one prabhag | Display all. This is a data quality issue flagged for admin review. |
| User adds a corporator with no phone/email | Allow it. Any data is better than none. Show fields with "Not yet added." |
| Ward officer changes (transfer) | End the old role (`ended_at = Time.current`), create new role. Both appear in history. Only active role displays. |

### Photo Edge Cases

| Case | Handling |
|------|----------|
| User uploads invalid file type | Validate content type. Reject with error message. |
| User uploads oversized file (>10MB) | Validate file size. Reject with error message. |
| Photo uploaded for wrong facility | Admin can delete photos. No user self-delete in Phase 1. |
| ActiveStorage service unavailable | Rescue and show "Photo upload temporarily unavailable." Do not break facility page. |
| Facility with 50+ photos | Show first 6 in grid, "View all photos" link for rest. |

### Verification Edge Cases

| Case | Handling |
|------|----------|
| User verifies same facility twice in 30 days | Validation prevents it. Show "You verified this facility on [date]." |
| Facility verified 2 years ago, never since | Show "Last verified 2 years ago" in amber/warning color. Prompt re-verification. |
| Facility reported as demolished but also verified recently | Both are valid data points. Show both. Admin resolves. |

---

## Technical Considerations

### Architecture Impact
- **No new patterns introduced.** Contributable concern follows the same pattern as Discussable. Polymorphic associations already used throughout the codebase (Boundary, Discussion, Role).
- **No API changes.** All interactions are standard Rails form submissions with Turbo redirects. The existing JSON format responses for facilities are not affected.
- **No new JavaScript frameworks.** The wiki-edit Stimulus controller is ~10 lines. The facility show page map reuses the existing leaflet-map controller.

### Database Changes
- Two new tables: `contributions` (audit log) and `verifications` (citizen confirmations)
- Six new columns on `facilities`: `phone`, `email`, `operating_hours`, `description`, `last_verified_at`, `last_verified_by_id`
- No changes to `people`, `roles`, `wards`, `prabhags`, `discussions`, or `boundaries` tables
- Indexes on `contributions` for polymorphic lookup and user queries

### Integration Points
- **ActiveStorage:** Required for facility photos. Already available in Rails 8.0.2 but may need storage service configuration if not already set up. Check `config/storage.yml`.
- **Overpass API / OsmService:** Not called on facility pages. Facility pages read from the database only. The existing import pipeline (`OsmFacilityImporter`) continues to populate facilities.
- **Existing Discussion system:** Facility discussions use the exact same Discussion and Post models. The polymorphic `discussable` association handles it. Discussion controllers for facilities follow the ward/prabhag pattern.
- **Existing Ticket system:** Facility issue reports create Tickets. No changes to the Ticket model needed.

### Caching Considerations
- Facility pages are database-driven, fast by default. No caching needed initially.
- If contribution history queries become slow, add a `contributions_count` counter cache on Facility and Person.
- Photo variant generation (thumbnails) should use ActiveStorage variants with eager processing.

---

## Implementation Phases

### Phase 1: Facility Show Page (Foundation)
**Goal:** Every facility gets a page with basic info and a map.

1. Add `show` action to a new top-level `FacilitiesController`
2. Create facility show view with: name, type badge, source badge, map, address, breadcrumb
3. Add route: `resources :facilities, only: [:show]`
4. Link facility names in ward facility list to the new show page
5. Update map popups with "View details" link

**Tests:**
- Request spec: GET `/facilities/:id` returns success
- Request spec: facility page shows name, type, source badge
- Request spec: facility page works for facility with no name, no coordinates
- Request spec: breadcrumb links to ward and prabhag

**No database migrations needed for this phase.**

### Phase 2: Wiki Contributions System
**Goal:** Logged-in users can edit facility details with full audit trail.

1. Create `contributions` migration and model
2. Create `Contributable` concern with `wiki_update!` method
3. Add `include Contributable` to Facility
4. Add wiki-editable columns to facilities: `phone`, `email`, `operating_hours`, `description`
5. Create `ContributionsController#create` (polymorphic)
6. Create `_wiki_field.html.erb` shared partial
7. Create `wiki_edit_controller.js` Stimulus controller
8. Add wiki fields to facility show page
9. Add edit history section

**Tests:**
- Model spec: `Facility#wiki_update!` updates field and creates Contribution
- Model spec: `wiki_update!` rejects non-WIKI_FIELDS
- Model spec: `wiki_update!` is a no-op for same value
- Request spec: POST `/contributions` requires authentication
- Request spec: POST `/contributions` updates facility and redirects
- Request spec: edit history visible on facility page

### Phase 3: Facility Discussions and Photos
**Goal:** Citizens can discuss facilities and upload photos.

1. Add `include Discussable` to Facility
2. Create `Facilities::DiscussionsController` (copy pattern from Wards::DiscussionsController)
3. Add discussion routes nested under facilities
4. Add discussion section to facility show page
5. Set up ActiveStorage for photos on Facility
6. Create `Facilities::PhotosController`
7. Add photo grid to facility show page

**Tests:**
- Request spec: facility discussions CRUD
- Request spec: photo upload creates attachment and Contribution
- Feature spec: user starts a discussion on a facility page

### Phase 4: People Directory
**Goal:** Prabhag pages show corporators; ward pages show enhanced directory with wiki edits.

1. Add `include Contributable` to Person
2. Load prabhag roles in PrabhagsController#show
3. Create "Your Representatives" section on prabhag show page
4. Create `Prabhags::PeopleController` for adding/editing people
5. Add party affiliation convenience methods to Role
6. Enhance ward info page directory with edit icons and contribution tracking
7. Add "Help us add this information" CTAs for missing data

**Tests:**
- Model spec: Person#wiki_update! works
- Request spec: prabhag page shows corporator when present
- Request spec: prabhag page shows CTA when corporator missing
- Request spec: POST to create person/role requires authentication
- Request spec: ward directory shows edit icons for logged-in users

### Phase 5: Verification, Issue Reporting, and Admin Moderation
**Goal:** Citizens can verify facilities and report issues. Admins can moderate contributions.

1. Create `verifications` migration and model
2. Add verify action to FacilitiesController
3. Add issue reporting via Facilities::IssuesController (creates Tickets)
4. Create `Admin::ContributionsController` with index and revert actions
5. Add admin routes for contribution moderation

**Tests:**
- Model spec: Verification enforces 30-day uniqueness
- Request spec: POST verify updates last_verified_at
- Request spec: POST issue creates Ticket
- Request spec: admin contributions list shows recent edits
- Request spec: admin revert restores old value

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Wiki spam/vandalism | Medium | Medium | Rate limiting (20 edits/hour/user). Admin revert capability. Auto-approve initially; add moderation queue if needed. All edits tracked and reversible. |
| Incorrect corporator information | Medium | High | Show "contributed by [user]" provenance. Admin can revert. Future: verified vs unverified badge. |
| Low contribution volume | High | Medium | Start with the facility page (useful even without contributions). Add "Help us add" CTAs. Consider seeding some data manually to demonstrate the pattern. |
| ActiveStorage configuration for photos | Low | Low | Check if storage service is configured. Use local disk for development, S3 or equivalent for production. |
| Performance of contributions polymorphic queries | Low | Low | Indexed by `[contributable_type, contributable_id]`. Counter cache if needed later. |
| Person name deduplication | Medium | Low | `find_or_initialize_by(name:)` handles exact matches. Fuzzy dedup is Phase 2. Admin can merge duplicates. |
| Contribution/edit conflicts with OsmFacilityImporter | Medium | Medium | OsmFacilityImporter updates `name`, `address`, `raw_data`, `content_hash`, `last_seen_at`. It does NOT touch wiki fields (`phone`, `email`, `operating_hours`, `description`). No conflict. If importer updates `name` and a citizen also edited `name`, the importer's write wins but the Contribution history preserves the citizen's value. Decide: should importer skip name updates if a citizen has edited it? Flag for Phase 2. |

---

## Open Questions

1. **Should wiki edits be auto-approved or require admin review?** This PRD assumes auto-approve for speed and to match the Wikimapia philosophy. If spam becomes a problem, add a moderation queue. The Contribution model already supports this with an optional `status` field.

2. **Should the OsmFacilityImporter skip fields that have been wiki-edited?** If a citizen corrects a facility name and then the importer runs, should the importer overwrite the citizen's correction? A flag like `name_contributed: true` on the facility could signal "do not overwrite this field from import." Deferred to Phase 2.

3. **Should there be a separate "Facility Guardian" role?** A citizen who adopts a facility and is responsible for keeping its data current. This is mentioned in the prabhag-show-redesign PRD as a future concept. Deferred to a later phase.

4. **Person photo storage.** Person model does not have a photo field. Should it use ActiveStorage (like Facility) or a URL field? Deferred to Phase 2 when person pages are built.

5. **Rate limiting implementation.** Application-level (check Contribution count in controller) or infrastructure-level (Rack::Attack)? Application-level is simpler and sufficient initially.

6. **Should facility discussions be visible to anonymous users?** This PRD assumes yes, consistent with ward/prabhag discussions. Anonymous users can read but not post.
