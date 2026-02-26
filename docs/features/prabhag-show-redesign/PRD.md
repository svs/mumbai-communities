# Prabhag Home Page — Product Requirements Document

## What is a Prabhag Page?

A prabhag is a neighborhood of ~50,000–60,000 people. The prabhag page is the **home page for that neighborhood** on this platform. It is the place where civic engagement begins.

The platform's thesis: citizen observation, auditing, reporting, journalism, and activism all happen at the prabhag level. But a prabhag can't do any of that until it's been geocoded — until someone traces its boundary from the official MCGM PDF into a digital polygon. Once that happens, everything unlocks.

## The Prabhag Lifecycle

A prabhag progresses through stages. Each stage unlocks the next. **You cannot skip stages.**

```
UNMAPPED → PENDING → MAPPED → ENRICHED → ACTIVE
```

### Stage 0: Unmapped
- We have: a number, a ward code, a PDF from MCGM
- We can do: nothing — no facilities, no audits, no discussions
- The page should: make someone want to map it

### Stage 1: Pending
- Someone traced the boundary and submitted it
- We have: a pending boundary awaiting admin review
- We can do: show the submitted boundary, compare with PDF
- The page should: let admins approve/reject inline; show submitter credit

### Stage 2: Mapped
- Boundary is approved (user submission, official import, or legacy KML)
- We can now: query OSM for what's inside (via `HasPois` concern) — schools, hospitals, parks, etc.
- The page should: show the boundary on a map with POIs, invite discussion
- **Legacy KML special case:** boundary exists but is from 2017, needs remapping from 2025 PDF

### Stage 3: Enriched
- Boundary exists AND facility data has been imported (BMC/OSM)
- We can now: compare data sources, identify gaps, verify on the ground
- The page should: show facility details, data source comparison

### Stage 4: Active
- Boundary + facilities + community participation (discussions, guardians)
- The page should: be a living neighborhood hub

## Who Visits This Page?

Four personas, with different needs at each stage:

### Anonymous Visitor
A Mumbaikar who found this page via search or a link. They want to understand their neighborhood. They might be converted into a contributor.

### Logged-in Resident
Lives in or near this prabhag. Wants to see what's here, what needs attention, and how to help. Potential mapper, discussant, or facility guardian.

### Volunteer Mapper
Came specifically to help digitize boundaries. Needs the PDF reference and a clear path to the trace page.

### Admin
Reviews boundary submissions, manages data quality. Needs to approve/reject boundaries without leaving the page.

## Page Behavior by Stage × User

### UNMAPPED

| Element | Anonymous | Logged-in | Admin |
|---------|-----------|-----------|-------|
| Header | Prabhag #, Ward name, "Unmapped" badge | Same | Same + Admin link |
| Progress bar | Step 1 highlighted: "Map the boundary" | Same | Same |
| Main content | Pitch: "This neighborhood needs to be put on the map." What mapping unlocks (schools, hospitals, parks, discussions). | Same + "Volunteer to Map" CTA → assigns & redirects to trace page | Same |
| If assigned to someone | "Being mapped by [name]" | Same (or "Continue Mapping" if it's them) | Same |
| PDF | Displayed prominently — this IS the content at this stage | Same | Same |
| Facilities | Not shown — cannot exist without boundary | Same | Same |
| Discussions | Not shown — no point discussing a location we can't define | Same | Same |
| Boundary history | Not shown (no boundaries) | Same | Same |

### PENDING

| Element | Anonymous | Logged-in | Admin |
|---------|-----------|-----------|-------|
| Header | Prabhag #, Ward name, "Under review" badge | Same | Same + Admin link |
| Progress bar | Step 1 highlighted: "Boundary under review" | Same | Same |
| Status banner | "Boundary submitted by [name]. Awaiting review." | Same | Same + **Approve / Reject buttons inline** |
| Map | Shows the submitted boundary polygon | Same | Same — admin reviews it right here |
| PDF | Collapsible — admin uses it to compare with submitted boundary | Same | **Open by default** for comparison |
| Rejection | N/A | N/A | Reject button with reason text field |
| After approval | Page reloads as "Mapped" stage | Same | Redirects or reloads to show new state |
| After rejection | Page reloads as "Unmapped" stage (prabhag becomes available again) | Same | Same |
| Facilities | Not shown — boundary not yet approved | Same | Same |
| Discussions | Not shown yet | Same | Same |

### MAPPED (approved boundary — including legacy KML)

| Element | Anonymous | Logged-in | Admin |
|---------|-----------|-----------|-------|
| Header | Prabhag #, Ward name, status badge (varies by source type) | Same | Same + Admin link |
| Progress bar | Step 1 done, Step 2 highlighted: "Discover facilities" | Same | Same |
| Legacy KML banner | "This boundary is from 2017. It needs remapping from the 2025 PDF." + remap CTA | Same | Same |
| Map | Boundary polygon + **POI markers from `@prabhag.pois`** (live OSM query via HasPois concern) | Same | Same |
| POI list | Schools, hospitals, parks, etc. grouped by type below the map | Same | Same |
| PDF | Collapsible reference | Same | Same |
| Discussions | Shown — people can discuss their neighborhood now | Same + "Start a discussion" link | Same |
| Boundary history | Collapsible — shows all submissions with status | Same | Same |

### ENRICHED (has imported Facility records)

Same as Mapped, plus:
- Facility details with names, addresses, data sources (BMC vs OSM)
- Data source comparison (BMC count vs OSM count per type)
- "Verify this facility" future CTA

### ACTIVE (has community participation)

Same as Enriched, plus:
- Active discussions shown prominently
- Facility guardians listed
- Recent activity feed
- Issue reports

## Key Design Decisions

### 1. Admin approves/rejects boundaries inline

The admin is looking at the boundary on the map. The PDF is right there for comparison. Don't make them navigate to a separate admin page. Put the Approve/Reject buttons right on the prabhag page when:
- User is admin AND
- There is a pending boundary

This uses the existing `Admin::BoundariesController#approve` and `#reject` actions. The form posts to those endpoints and redirects back to the prabhag page.

### 2. Use HasPois for live OSM data, not stored Facility records

For the "What's here" section on mapped prabhags, use `@prabhag.pois` which queries the Overpass API in real-time using the boundary polygon. This means:
- No dependency on facility import pipelines
- Data is always current
- Works for ANY mapped prabhag immediately after approval
- Graceful degradation if Overpass is down (show "Facility data temporarily unavailable")

Cache the result (Rails.cache, 24h TTL) to avoid hammering Overpass on every page load.

If stored Facility records also exist (Stage: Enriched), prefer those and supplement with live POI data for types not covered.

### 3. Discussions unlock after mapping

You can't meaningfully discuss a location you can't define. Discussions are shown only for mapped+ prabhags. The `Discussable` concern is already on the Prabhag model — just gate the UI.

### 4. PDF display varies by stage

- **Unmapped:** PDF is the main content — displayed prominently, full height
- **Pending:** PDF is a comparison tool — collapsible, open by default for admins
- **Mapped+:** PDF is historical reference — collapsible, closed by default

### 5. Progress indicator is always visible

A simple 3-step bar at the top shows where this prabhag is in its journey:
1. Map the boundary
2. Discover facilities
3. Organize & improve

Steps light up green as they're completed. The current step is highlighted. This gives visitors context and motivation.

### 6. Empty sections are not shown

If a prabhag is unmapped, don't show "Facilities: none" and "Discussions: none." That's depressing. Only show sections that have content or are actionable at the current stage.

## Functional Requirements

### FR-1: Lifecycle Stage Computation

Add to Prabhag model:

```ruby
def lifecycle_stage
  best = boundary
  return :unmapped unless best
  return :pending if best.status == 'pending'

  has_facilities = Facility.where(ward_code: ward_code).exists? || pois.any?
  has_discussions = discussions.exists?

  if has_discussions && has_facilities
    :active
  elsif has_facilities
    :enriched
  else
    :mapped
  end
end
```

Note: the `pois` call hits Overpass API. For lifecycle computation, use cached/stored facility data only. The live POI query is for display, not stage computation.

### FR-2: Inline Admin Boundary Review

When admin views a prabhag with a pending boundary:

```erb
<% if user_signed_in? && current_user.admin? && boundary&.status == 'pending' %>
  <div class="admin-review-panel">
    <%= button_to "Approve", approve_admin_prabhag_boundary_path(@prabhag, boundary),
                  method: :post, class: "..." %>
    <%= form_with url: reject_admin_prabhag_boundary_path(@prabhag, boundary) do |f| %>
      <%= f.text_field :rejection_reason, placeholder: "Reason for rejection" %>
      <%= f.submit "Reject", class: "..." %>
    <% end %>
  </div>
<% end %>
```

### FR-3: POI Display for Mapped Prabhags

Controller loads POIs for mapped prabhags:

```ruby
def show
  # ... existing code ...
  if boundary&.geojson.present? && boundary.status != 'pending'
    @pois = Rails.cache.fetch("prabhag/#{@prabhag.id}/pois", expires_in: 24.hours) do
      @prabhag.pois
    end
  else
    @pois = []
  end
end
```

Group by type for display:

```ruby
@poi_groups = @pois.group_by { |poi| poi[:type] }
```

### FR-4: Computed Status Badge

Already implemented via `computed_mapping_status` and `mapping_status_badge` on the model. Use these instead of raw `prabhag.status`.

### FR-5: Discussion Integration

For mapped+ prabhags, show recent discussions and a "Start a discussion" link. Uses existing `Discussable` concern, `Prabhags::DiscussionsController`, and routes.

## Edge Cases

### Boundary Edge Cases

| Case | Behavior |
|------|----------|
| No boundaries at all | Stage: unmapped. Show PDF + mapping CTA. |
| Only rejected boundaries | Stage: unmapped. Show "Previous submission rejected" with reason. Show PDF + remap CTA. |
| Pending boundary | Stage: pending. Show boundary on map + admin review panel. |
| Multiple pending boundaries | Show the most recent. Admin reviews one at a time. |
| Legacy KML (approved, 2017) | Stage: mapped. Show boundary but with "needs remapping" banner. |
| Approved user submission | Stage: mapped. Show boundary + POIs + discussions. |
| Canonical official import | Stage: mapped. Show boundary + POIs + discussions. "Official" badge. |
| Boundary with malformed GeoJSON | Catch parse error. Show "Boundary data could not be rendered." Fall back to unmapped display. |
| Boundary submitted by deleted user | Show "Unknown mapper" instead of crashing. |

### POI/Facility Edge Cases

| Case | Behavior |
|------|----------|
| Overpass API timeout | Show "Facility data temporarily unavailable. Try again later." |
| Overpass API down | Same graceful degradation. Don't break the page. |
| Zero POIs found | "No facilities found in this area from OpenStreetMap." |
| Very many POIs (100+) | Show summary counts by type, collapse full list. |
| POI has no name | Display as "Unnamed [type]" |
| Both stored Facility records and live POIs exist | Show stored Facility data (richer), note OSM as supplementary source. |

### Admin Review Edge Cases

| Case | Behavior |
|------|----------|
| Admin approves | Boundary → approved. Prabhag → approved (via PrabhagStatusService). Page reloads as mapped stage. Flash: "Boundary approved." |
| Admin rejects without reason | Allow but show warning "Consider adding a reason." |
| Admin rejects with reason | Boundary → rejected. Prabhag → available. Page reloads as unmapped. Flash: "Boundary rejected." |
| Non-admin tries to approve | Buttons not shown. POST returns 403. |
| Boundary already approved (race condition) | Admin sees mapped page, no approve/reject buttons. |
| Admin views mapped prabhag (no pending) | Normal mapped view, no review panel. |

### Discussion Edge Cases

| Case | Behavior |
|------|----------|
| Unmapped prabhag | Discussions section not shown. |
| Mapped, no discussions | Show "No discussions yet. Start one about your neighborhood." |
| Mapped, has discussions | Show recent 5, link to full list. |
| User not signed in, wants to discuss | "Sign in to start a discussion" |

## Implementation Plan

### Phase 1: Lifecycle stage + stage-aware view
1. Refine `lifecycle_stage` on model (don't call Overpass for stage computation)
2. Rewrite view with stage-based rendering
3. Proper empty states (no showing empty sections)
4. Progress indicator

### Phase 2: Inline admin review
1. Add approve/reject forms to the pending stage view
2. POST to existing admin boundary endpoints
3. Redirect back to prabhag page
4. Flash messages for success/failure

### Phase 3: POI display for mapped prabhags
1. Load POIs via HasPois concern in controller
2. Cache with 24h TTL
3. Group by type, display below map
4. Graceful degradation if Overpass fails

### Phase 4: Discussions integration
1. Show recent discussions for mapped+ prabhags
2. "Start a discussion" CTA
3. Links to existing discussion routes

### Phase 5: Enrichment (future)
1. Facility import at prabhag level
2. Data source comparison
3. Facility guardian assignment
4. Verification workflows
