# Boundary Approval Workflow - Product Requirements Document

## Executive Summary

The Boundary Approval Workflow feature enhances the existing MCGM Ward Boundary Rails application by implementing a comprehensive two-step admin review process for user-submitted prabhag boundaries. This feature enables administrators to efficiently review, edit, and approve boundary submissions while maintaining data integrity and providing a smooth user experience.

## Problem Statement

Currently, the application has basic admin functionality to view boundary submissions, but lacks a structured workflow for reviewing and approving boundaries. Administrators need:

1. **Quick Visual Review**: A way to rapidly compare PDF sources with traced boundaries across multiple submissions
2. **Detailed Editing Capability**: Ability to make corrections to user-submitted boundaries before approval
3. **Efficient Batch Processing**: Tools to handle multiple boundary submissions systematically
4. **Audit Trail**: Clear tracking of who edited/approved boundaries and when

## Goals and Objectives

### Primary Goals
- Implement a two-step boundary approval workflow (Quick Review → Detailed Edit/Approve)
- Reduce administrative overhead in boundary review process
- Maintain high boundary accuracy through admin oversight
- Preserve existing user tracing functionality and admin infrastructure

### Success Criteria
- Boundaries are easy to approve with or without edits.

### Non-Goals
- Complex versioning system for boundary histories
- Public access to admin review interfaces
- Automated boundary validation/approval
- Integration with external GIS systems

## User Stories

### Must Have

**US-1: Quick Visual Review**
- **Story**: As an admin, I want to view all pending boundary submissions for a prabhag in a single page with PDF and map side-by-side, so that I can quickly assess submission quality.
- **Acceptance Criteria**:
  - Navigate to `/admin/prabhags/:id/boundaries?for_review=true`
  - See all pending boundaries for that prabhag in a list format
  - Each row shows: PDF thumbnail/image + boundary overlay map
  - Click any row to navigate to detailed review page
  - Quick "Approve" button on each row for submissions that need no editing
  - Page loads within 3 seconds with up to 10 boundary submissions

**US-2: Detailed Boundary Editing**
- **Story**: As an admin, I want to edit user-submitted boundaries using the same interface users have, so that I can make corrections before approval.
- **Acceptance Criteria**:
  - Access detailed edit page from review list
  - Interface pre-populated with submitted boundary data
  - Same tracing tools available as in `/prabhags/:id/trace`
  - Changes overwrite original boundary data (no separate versioning)
  - "Save Changes" updates boundary, sets `edited_by` field, keeps status as 'pending'
  - "Approve" button changes status to 'approved' and sets approval metadata

**US-3: Administrative Actions**
- **Story**: As an admin, I want to approve, reject, or request revisions for boundary submissions, so that I can control boundary quality.
- **Acceptance Criteria**:
  - Approve: Sets status to 'approved', records admin user and timestamp
  - Reject: Sets status to 'rejected', allows rejection reason input
  - Admin actions only visible to users with admin role
  - All actions create audit log entries
  - Status changes reflect immediately in all admin interfaces

**US-4: Admin Access Control**
- **Story**: As a system administrator, I want only authorized admins to access review workflows, so that boundary data integrity is maintained.
- **Acceptance Criteria**:
  - All admin routes require `current_user.admin?` to return true
  - Non-admin users redirected to root path with error message
  - Admin status visible in user interface when logged in as admin
  - No public access to admin boundary endpoints

### Should Have

**US-6: Review Progress Tracking**
- **Story**: As an admin, I want to see my review progress across all prabhags, so that I can prioritize my work.
- **Acceptance Criteria**:
  - Admin dashboard shows pending review counts by ward
  - Highlight prabhags with oldest pending submissions
  - Show admin's recent review activity
  - Filter by submission date, ward, or status

### Could Have


## Functional Requirements

### Review List Page (`/admin/prabhags/:id/boundaries?for_review=true`)

**Layout & Navigation**
- Two-column layout: PDF reference (left) + Map preview (right)
- Header showing prabhag information and navigation breadcrumbs
- Each boundary submission as a distinct row/card
- Pagination for more than 10 submissions
- Sort options: submission date, submitter name, boundary complexity

**PDF Display**
- Static image representation of prabhag PDF
- Rails pdf representation image should work for this. Is generated automatically for PDFs.
- Fallback to PDF URL if image not available
- Click to open full PDF in new tab

**Map Preview**
- Leaflet.js map showing submitted boundary overlay. Use the existing component ward_boundary_controller I think it is called.
- Boundary colored by status. The show.json for the boundary should take care of this. This might be in the show.json of the prabhag. you can refactor to a _boundary partial.
- Centered and zoomed to boundary extents
- Non-interactive (display only)
- Consistent styling with existing boundary displays

**Quick Actions**
- "Review in Detail" link to editing interface
- "Quick Approve" button with confirmation dialog
- Bulk selection checkboxes (should have)
- Rejection option with inline reason input

### Detailed Review/Edit Page (based on `/prabhags/:id/trace`)

**Interface Reuse**
- Copy existing boundary tracer interface structure and styling
- Reuse `boundary_tracer_controller.js` Stimulus controller
- Maintain same PDF + Map split-screen layout
- All existing tracing tools available (undo, clear, close polygon, etc.)

**Pre-population**
- Load submitted boundary data into map on page load
- Same data format as `@existing_boundary` in current trace interface
- Boundary immediately visible and editable

**Admin-Specific Actions**
- "Save Changes" button (overwrites boundary data, sets `edited_by`)
- "Approve Boundary" button (changes status to approved)
- "Reject Boundary" button (changes status to rejected + reason)
- "Back to Review List" navigation

**Data Handling**
- Changes overwrite original `boundaries.geojson` field
- Set `boundaries.edited_by_id` to current admin user ID
- Preserve original `boundaries.submitted_by_id`
- Update `boundaries.updated_at` timestamp
- Admin edit information visible only in admin interfaces

### Integration Points

**Existing Boundary Model**
- Utilize current `status` field workflow: 'pending' → 'approved'/'rejected'
- Leverage existing `approved_by` and `approved_at` fields
- Add new `edited_by` field (belongs_to :edited_by, class_name: 'User'). Validate that it's an admin.
- Use existing semantic scopes (`pending`, `approved`, etc.)

**Current Admin Infrastructure**
- Extend existing `Admin::PrabhagsController`
- Build on current admin access control (`ensure_admin!`)
- Integrate with existing admin navigation and styling
- Maintain Tailwind CSS design system consistency

**User Interface Continuity**
- Consistent with current admin panel visual design
- Same iconography and color scheme as existing admin pages
- Mobile-responsive design (though primarily desktop workflow)
- Proper flash message handling for user feedback

## Non-Functional Requirements


### Security Requirements
- All admin routes protected by authentication and authorization
- CSRF protection on all form submissions
- Admin role verification on every admin action
- Audit logging for all boundary modifications
- No exposure of admin functionality to non-admin users

### Accessibility Requirements
- Keyboard navigation support for all interactive elements
- ARIA labels on map controls and action buttons
- High contrast color scheme for boundary status indicators
- Screen reader compatible status updates and error messages
- Zoom functionality maintains accessibility

### Compatibility Requirements
- Compatible with existing Leaflet.js and Google Maps integrations
- Works with current RGeo + GeoJSON data format
- Maintains compatibility with existing boundary tracer interface
- Supports modern browsers (Chrome 90+, Firefox 88+, Safari 14+)
- Mobile responsive (though optimized for desktop)

## Edge Cases and Error Handling

### Data Integrity Edge Cases
- **Orphaned boundaries**: Handle prabhags with boundaries but no valid GeoJSON
- **Malformed GeoJSON**: Graceful error handling with clear error messages
- **Missing submitted_by**: Display "Unknown submitter" with system handling
- **Concurrent editing**: Last-save-wins with warning if multiple admins edit simultaneously
- **Large boundary datasets**: Pagination and performance optimization for 100+ points

### User Experience Edge Cases
- **No pending boundaries**: Show empty state with helpful messaging
- **PDF unavailable**: Fallback to "PDF not available" message with link
- **Map loading failure**: Error message with manual refresh option
- **Slow network**: Loading indicators and progressive enhancement
- **Session timeout**: Redirect to login with return path preservation

### Administrative Edge Cases
- **Non-admin access attempt**: Redirect with clear error message
- **Invalid prabhag ID**: 404 error with navigation back to admin dashboard
- **Boundary approval conflicts**: Handle multiple admins approving same boundary
- **Bulk operation failures**: Partial success reporting with retry options
- **Audit log failures**: Log errors but don't block user operations

### System Edge Cases
- **Database connection issues**: Graceful degradation with error reporting
- **File system issues**: Handle missing PDF images with fallbacks
- **Google Maps API failures**: Fallback to static map or error message
- **Memory constraints**: Efficient boundary data loading and cleanup
- **Rate limiting**: Respect Google Maps API limits with user feedback

## Technical Considerations

### Architecture Impact
- Minimal changes to existing models (add `edited_by` field to Boundary)
- New controller actions in existing `Admin::PrabhagsController`
- New views following existing admin panel patterns
- Reuse existing Stimulus controllers with minor modifications

### Database Changes
```ruby
# Migration: Add edited_by to boundaries table
add_reference :boundaries, :edited_by, null: true, foreign_key: { to_table: :users }
add_column :boundaries, :admin_notes, :text
```

### API Modifications
- No new API endpoints required
- Existing JSON format handlers work with new admin workflows
- Maintain backward compatibility with current boundary JSON responses

### Integration Points
- Extend existing `Admin::PrabhagsController` with boundary-specific actions
- New route: `get '/admin/prabhags/:id/boundaries', to: 'admin/prabhags#boundary_review'`
- New route: `get '/admin/prabhags/:prabhag_id/boundaries/:id/edit', to: 'admin/prabhags#boundary_edit'`
- Integrate with existing admin layout and navigation patterns

## User Interface

### Review List Page Layout
```
[Header: Admin > Prabhag 123 > Boundary Review]
[Statistics: 3 pending, 12 approved, 1 rejected]

┌─────────────────┬─────────────────┐
│ PDF Reference   │ Boundary Map    │
├─────────────────┼─────────────────┤
│ [PDF Preview]   │ [Leaflet Map]   │
│ Submission #1   │ with boundary   │
│ by User A       │ overlay         │
│ [Quick Approve] │ [Review Detail] │
├─────────────────┼─────────────────┤
│ [PDF Preview]   │ [Leaflet Map]   │
│ Submission #2   │ with boundary   │
│ by User B       │ overlay         │
│ [Quick Approve] │ [Review Detail] │
└─────────────────┴─────────────────┘
```

### Detailed Edit Page Layout
- Reuses existing `/prabhags/:id/trace` layout exactly
- Additional admin buttons in toolbar area
- Admin-specific styling cues (admin badge, different color scheme)
- Breadcrumb navigation showing admin context

### Status Indicators
- **Pending**: Yellow indicators, clock icon
- **Approved**: Green indicators, checkmark icon
- **Rejected**: Red indicators, X icon
- **Edited by Admin**: Blue badge with admin username
- **Canonical**: Purple indicators, star icon

## Dependencies

### External Dependencies
- Google Maps API (existing)
- Leaflet.js library (existing)
- Current authentication system (Devise + Google OAuth)
- Existing admin role infrastructure

### Internal Dependencies
- Boundary model with status workflow
- Prabhag model with boundary associations
- User model with admin role capability
- Existing admin controller base class
- Current Stimulus boundary tracer controller

### Blocking Factors
- Admin role implementation must be functional
- Boundary model status workflow must be working
- Existing PDF-to-image conversion process must be operational
- Google Maps API key must be configured for admin usage


## Risks and Mitigations

### High Risk: Data Loss During Admin Editing
- **Risk**: Admin edits could overwrite user submissions incorrectly
- **Mitigation**: Comprehensive testing, audit logging, and backup procedures
- **Contingency**: Database backup recovery and manual data restoration process

### Medium Risk: Performance Issues with Large Boundary Datasets
- **Risk**: Pages become slow with complex boundaries or many submissions
- **Mitigation**: Pagination, lazy loading, and boundary simplification options
- **Contingency**: Fallback to simplified views and server-side processing

### Medium Risk: Admin User Training and Adoption
- **Risk**: Admins may resist new workflow or make errors during review
- **Mitigation**: Clear documentation, training sessions, and intuitive interface design
- **Contingency**: Fallback to existing admin interface and gradual migration

### Low Risk: Google Maps API Rate Limiting
- **Risk**: Excessive admin usage could hit API limits
- **Mitigation**: Caching, static fallbacks, and usage monitoring
- **Contingency**: Alternative mapping providers or static map generation

## Open Questions

### Stakeholder Input Required

1. **Approval Threshold**: What defines an acceptable boundary? Should there be specific accuracy requirements?

2. **Admin Notification**: Should admins receive email notifications for new boundary submissions?

3. **User Feedback**: Should users be notified when their boundaries are edited by admins? What level of detail?

4. **Rejection Workflow**: When boundaries are rejected, should users be able to resubmit immediately or is there a waiting period?

5. **Performance Standards**: What is the acceptable response time for loading 50+ boundary submissions on the review page?

6. **Historical Data**: Should existing boundaries in the system be migrated through this new approval workflow?

7. **Multiple Admin Coordination**: How should the system handle multiple admins working on the same prabhag boundaries simultaneously?

8. **Escalation Process**: What happens if admins cannot reach consensus on boundary approval/rejection?

### Technical Clarifications Needed

1. **PDF Image Generation**: Is the PDF-to-image conversion process reliable enough for production admin workflows?

2. **Mobile Admin Usage**: What percentage of admin usage will be on mobile devices, and what are the minimum supported screen sizes?

3. **Backup Strategy**: What is the current backup and recovery strategy for boundary data, and does it need enhancement?

4. **Monitoring Requirements**: What specific metrics should be tracked for admin boundary review performance?

---

*This PRD serves as the definitive requirements document for implementing the boundary approval workflow feature, ensuring all stakeholders have a clear understanding of scope, functionality, and success criteria.*
