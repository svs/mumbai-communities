# Admin Boundary Review Workflow Specification

## Overview
Admins review and approve/reject boundary submissions from users. The workflow starts from the admin dashboard and flows through review to approval/rejection.

## User Story
As an admin, I want to review submitted prabhag boundaries so that I can approve accurate boundaries and reject incorrect ones.

## Complete Workflow

### 1. Dashboard Access
**Given** I am an admin user who is signed in
**When** I visit `/admin/prabhags`
**Then** I should see:
- Page title "Admin Panel - Boundary Review"
- A link back to the main site
- Three statistics cards showing:
  - Number of pending review prabhags (yellow card)
  - Number of approved prabhags (green card)
  - Number of rejected prabhags (red card)

### 2. Viewing Pending Submissions
**Given** there are prabhags with pending boundary submissions
**When** I am on the admin dashboard
**Then** I should see a "Pending Review" section with:
- A table listing all submitted prabhags
- For each prabhag, I should see:
  - Prabhag number
  - Ward code
  - Assigned user name/email
  - Time since submission
  - "View" link
  - "Review" button with count of pending boundaries

**And** if there are no pending submissions
**Then** I should see "No prabhags pending review."

### 3. Reviewing a Boundary Submission
**Given** I click "Review" on a pending prabhag
**When** I am taken to the boundary review page
**Then** I should see:
- The prabhag number and ward code
- A map displaying the submitted boundary
- The PDF reference for comparison
- Boundary metadata:
  - Submitted by (user name/email)
  - Submission date/time
  - Source type (user_submission)
  - Status (pending)
- Action buttons:
  - "✅ Approve" button
  - "❌ Reject" button

### 4. Approving a Boundary
**Given** I am reviewing a boundary submission
**When** I click the "✅ Approve" button
**Then** I should see a confirmation dialog "Approve this boundary?"
**When** I confirm
**Then**:
- The boundary status changes to "approved"
- The prabhag status changes to "approved"
- I am redirected to the admin prabhag show page
- I see a success notice "Prabhag boundary approved successfully!"
- The prabhag no longer appears in the "Pending Review" section
- The prabhag appears in the "Recently Approved" section

### 5. Rejecting a Boundary
**Given** I am reviewing a boundary submission
**When** I click the "❌ Reject" button
**Then** I should see a confirmation dialog "Reject this boundary?"
**When** I confirm
**Then**:
- The boundary status changes to "rejected"
- The prabhag status changes to "available"
- The prabhag is unassigned (assigned_to becomes nil)
- I am redirected to the admin prabhag show page
- I see a notice "Prabhag boundary rejected. It has been made available for reassignment."
- The prabhag no longer appears in the "Pending Review" section
- The prabhag appears in the "Recently Rejected" section

### 6. Viewing Approved Prabhags
**Given** there are approved prabhags
**When** I am on the admin dashboard
**Then** I should see a "Recently Approved" section with:
- Cards showing the most recent 6 approved prabhags
- For each prabhag:
  - Prabhag number
  - Ward code
  - Approved by user name/email
  - Time since approval
  - "View" link

### 7. Viewing Rejected Prabhags
**Given** there are rejected prabhags
**When** I am on the admin dashboard
**Then** I should see a "Recently Rejected" section with:
- Cards showing the most recent 6 rejected prabhags
- For each prabhag:
  - Prabhag number
  - Ward code
  - Rejected user name/email (if any)
  - Time since rejection
  - "View" link

### 8. Viewing Admin Prabhag Details
**Given** I click "View" on any prabhag
**When** I am taken to `/admin/prabhags/:id`
**Then** I should see:
- Prabhag number and ward code
- Current status (submitted/approved/rejected)
- Assigned user (if any)
- A map showing the best available boundary
- Boundary metadata (if available):
  - Status
  - Submitted by
  - Submission date
  - Approved by (if approved)
  - Approval date (if approved)
  - Rejection reason (if rejected)
- Navigation links

## Edge Cases

### No Pending Boundary Found
**Given** I am on a prabhag show page in the admin panel
**When** I click "Approve" or "Reject"
**And** there is no pending boundary
**Then** I should see an alert "No pending boundary found to approve/reject."

### Boundary Already Processed
**Given** a boundary has already been approved or rejected
**When** I try to approve/reject it again
**Then** I should see an error message
**And** the action should not be performed

### Non-Admin Access
**Given** I am not an admin user
**When** I try to access `/admin/prabhags`
**Then** I should be denied access
**And** I should be redirected with an "Access denied" message

## Technical Notes

### Routes
- `GET /admin/prabhags` - Admin dashboard (index)
- `GET /admin/prabhags/:id` - Admin prabhag show page
- `GET /admin/prabhags/:id/boundaries` - Boundary review page
- `POST /admin/prabhags/:prabhag_id/boundaries/:id/approve` - Approve boundary
- `POST /admin/prabhags/:prabhag_id/boundaries/:id/reject` - Reject boundary

### Models Involved
- `User` (with admin flag)
- `Prabhag` (with status: available/assigned/submitted/approved/rejected)
- `Boundary` (with status: pending/approved/rejected/canonical)

### Status Transitions
**Prabhag:**
- `submitted` → `approved` (on boundary approval)
- `submitted` → `available` (on boundary rejection)

**Boundary:**
- `pending` → `approved` (on admin approval)
- `pending` → `rejected` (on admin rejection)

### Business Rules
1. Only pending boundaries can be approved/rejected
2. Approving a boundary also approves the prabhag
3. Rejecting a boundary makes the prabhag available and unassigns it
4. Admins can access any prabhag regardless of assignment
5. The admin panel is read-only for already processed boundaries
