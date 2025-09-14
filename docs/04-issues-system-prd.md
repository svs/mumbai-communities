# Issues System PRD - Mumbai Ward Civic Engagement Platform

## Overview

The Issues System is the heart of civic engagement on the platform, enabling ward residents to report local problems, track resolution progress, and coordinate community action. This system transforms individual complaints into organized community advocacy, providing transparency, accountability, and collective voice for neighborhood improvements.

## User Stories

### Primary Users
- **Ward residents** who encounter daily problems and want effective channels for reporting and resolution
- **Community activists** who need to organize collective action around persistent issues
- **Local representatives** who want to understand constituent priorities and demonstrate responsiveness
- **Concerned citizens** who want to support neighbors' issues and build community solidarity

### Core User Stories
- As a **resident**, I want to report a pothole with photo and location so it gets proper attention and tracking
- As a **community member**, I want to see all active issues in my ward so I can understand neighborhood priorities and add my voice
- As a **supporter**, I want to upvote and comment on others' issues so problems get more visibility and community backing
- As a **representative**, I want to respond to issues publicly so residents can see accountability and progress
- As a **activist**, I want to organize community action around unresolved issues so we can collectively pressure for solutions
- As a **new resident**, I want to see historical issue patterns so I understand my neighborhood's challenges and successes

## Functional Requirements

### Must Have
1. **Issue Reporting Form**: Category selection, description, photo upload, location marking
2. **Issue Display**: List and map views of all ward issues with filtering and sorting
3. **Status Tracking**: Clear progression from Reported → Acknowledged → In Progress → Resolved → Verified
4. **Community Support**: Upvoting, commenting, and sharing mechanisms
5. **Photo Documentation**: Before/during/after images with timestamps
6. **Location Integration**: Precise issue mapping within ward boundaries
7. **Representative Response**: Official status updates and communication channel

### Should Have
1. **Issue Categories**: Structured classification (Roads, Cleanliness, Sanitation, Law & Order, Water, Electricity, Health, Transport, Parks, Education)
2. **Notification System**: Updates to issue reporters and supporters
3. **Duplicate Detection**: Identify and merge similar/duplicate issues
4. **Resolution Verification**: Community confirmation of completed work
5. **Issue History**: Track all updates, comments, and status changes
6. **Mobile Optimization**: Full functionality on mobile devices with camera integration

### Could Have
1. **Issue Analytics**: Trends, response times, resolution rates by category
2. **Batch Actions**: Report multiple related issues efficiently
3. **Issue Templates**: Quick reporting for common problems
4. **Integration**: Connection with official BMC complaint systems
5. **Social Sharing**: External sharing to increase pressure and awareness

## UI/UX Specifications

### Issue Reporting Form
```
REPORT ISSUE IN WARD 72

┌─────────────────────────────────────────────────────────┐
│ What type of issue? (Required)                          │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                │
│ │🛣️   │ │🗑️   │ │🚰   │ │⚡   │ │🏥   │                │
│ │Roads│ │Clean│ │Water│ │Elect│ │Health│                │
│ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                │
│                                                         │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                │
│ │🚨   │ │🚌   │ │🌳   │ │📚   │ │⚠️   │                │
│ │Law  │ │Trans│ │Parks│ │Educ │ │Other│                │
│ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                │
└─────────────────────────────────────────────────────────┘

Brief Description (Required)
┌─────────────────────────────────────────────────────────┐
│ Large pothole on SV Road near McDonald's               │
└─────────────────────────────────────────────────────────┘

Detailed Description
┌─────────────────────────────────────────────────────────┐
│ The pothole is about 2 feet wide and causes traffic    │
│ problems. During rain it collects water and makes      │
│ the situation worse. Several bikes have been damaged.  │
│                                                         │
└─────────────────────────────────────────────────────────┘

📷 Add Photos (Recommended)
[📸 Take Photo] [🖼️ Upload Images]
Current: IMG_001.jpg, IMG_002.jpg

📍 Mark Location (Required)
┌─────────────────────────────────────────────────────────┐
│ [Interactive Map]                                       │
│ 📍 Pin placed at: SV Road, Jogeshwari West            │
│ 🎯 Accuracy: ±5 meters                                 │
└─────────────────────────────────────────────────────────┘
[📍 Use GPS Location] [🔍 Search Address]

Contact Information (Optional)
┌─────────────────────────────────────────────────────────┐
│ Phone: +91 98765 43210                                 │
│ ☑️ Allow representatives to contact me                  │
│ ☑️ Notify me of updates via email                      │
└─────────────────────────────────────────────────────────┘

[Submit Issue] [Save Draft]
```

### Issues List View
```
ISSUES IN WARD 72 - JOGESHWARI WEST                    [🗺️ Map View]

Filters: [All] [Roads] [Cleanliness] [Water] [Active Only] [🔍 Search]
Sort: [Most Recent] [Most Supported] [Status] [Category]

┌─────────────────────────────────────────────────────────────────┐
│ 🔴 REPORTED • Roads & Infrastructure                           │
│ Large pothole on SV Road                               👍 12   │
│ Reported 2 days ago by Priya Shah                             │
│ 💬 5 comments • 📍 SV Road, Jogeshwari West                   │
│ [Support] [Comment] [Share] [View Details]                     │
├─────────────────────────────────────────────────────────────────┤
│ 🟡 IN PROGRESS • Cleanliness                          👍 8    │
│ Garbage collection missed for 3 days                          │
│ Reported 1 week ago by Raj Kumar                              │
│ 💬 12 comments • 📍 Station Road Area                         │
│ 🏛️ BMC Response: "Collection truck assigned, will resolve"   │
│ [Support] [Comment] [Share] [View Details]                     │
├─────────────────────────────────────────────────────────────────┤
│ 🟢 RESOLVED • Electricity                             👍 15   │
│ Streetlight not working                                        │
│ Reported 2 weeks ago by Maya Patel                            │
│ 💬 8 comments • 📍 Station Road                               │
│ ✅ Verified by community 3 days ago                           │
│ [View Resolution] [Thank Reporter]                             │
└─────────────────────────────────────────────────────────────────┘

📊 Ward 72 Issue Stats:
Active: 23 issues | Resolved this month: 15 | Average response: 4.2 days
```

### Issue Detail Page
```
← Back to Ward 72 Issues                    [Share] [Follow] [Report Problem]

🔴 Large pothole on SV Road                                Status: REPORTED
Category: Roads & Infrastructure            Support: 👍 12 residents

📅 Reported: March 10, 2025, 2:30 PM
👤 Reporter: Priya Shah (Ward 72 resident)
📍 Location: SV Road near McDonald's Junction              [View on Map]

┌─────────────────────────────────────────────────────────────────┐
│ Photos (3)                                                      │
│ [🖼️ Before Image 1] [🖼️ Before Image 2] [🖼️ Context Shot]      │
└─────────────────────────────────────────────────────────────────┘

Description:
Large pothole about 2 feet wide causing traffic issues and vehicle damage.
Water collects here during rains making it worse. Several bikes damaged.

📈 Status Timeline:
✅ Issue reported to platform (March 10, 2:30 PM)
🕐 Forwarded to BMC (March 10, 6:00 PM)
🕐 Awaiting acknowledgment
🕐 Site inspection pending
🕐 Repair work not scheduled

🏛️ Official Response: None yet
📞 BMC Reference: Pending

Community Support (12 supporters)
👥 [Avatar] [Avatar] [Avatar] +9 others support this issue

Recent Comments (5)
💬 Raj Kumar (3 hours ago): "I damaged my bike tire here yesterday"
💬 Maya Patel (1 day ago): "BMC should prioritize this, very dangerous"
💬 Local Activist (1 day ago): "Similar pothole on next street needs attention too"
💬 Anonymous (2 days ago): "This has been a problem for months"

[👍 Support This Issue] [💬 Add Comment] [📸 Add Photo] [📋 Report to BMC]

Related Issues in Area:
• Road flooding during rain (50m away)
• Missing manholes cover (200m away)
```

### Issue Map View
```
WARD 72 ISSUE MAP                                       [📋 List View]

┌─────────────────────────────────────────────────────────────────┐
│                        Map Controls                             │
│ Filters: [🔴 Active] [🟡 In Progress] [🟢 Resolved]           │
│ Categories: [All] [Roads] [Water] [Cleanliness]                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     Interactive Map                             │
│                                                                 │
│  🔴 ← Large pothole (12 👍)                                    │
│        📍                                                       │
│           🟡 ← Garbage issue (8 👍)                           │
│                 📍                                              │
│  🟢 ← Fixed streetlight (15 👍)                               │
│     📍                                                          │
│                                                                 │
│  [Ward 72 boundary outline]                                    │
│  [Street names and landmarks]                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

Click any pin for details • Zoom in for more precise locations
Heat map showing issue density across ward areas

Legend:
🔴 Reported (needs attention)   🟡 In Progress (being addressed)
🟢 Resolved (completed work)    📊 Issue density areas
```

## Information Architecture

### Issue Data Structure
```
Issue Object:
├── Basic Information
│   ├── ID (unique identifier)
│   ├── Ward ID (geographic assignment)
│   ├── Title (brief description)
│   ├── Category (predefined list)
│   └── Description (detailed explanation)
├── Location Data
│   ├── Coordinates (lat/lng)
│   ├── Address (human readable)
│   ├── Accuracy (GPS precision)
│   └── Landmark references
├── Media Attachments
│   ├── Photos (before/during/after)
│   ├── Videos (if applicable)
│   └── Documents (supporting evidence)
├── Tracking Information
│   ├── Status (reported/acknowledged/in-progress/resolved/verified)
│   ├── Reporter (user who submitted)
│   ├── Created date/time
│   ├── Last updated
│   └── Resolution date (if completed)
├── Community Engagement
│   ├── Support count (upvotes)
│   ├── Comments thread
│   ├── Followers (notification subscribers)
│   └── Shares/mentions
└── Official Response
    ├── BMC reference number
    ├── Official status updates
    ├── Representative comments
    └── Resolution verification
```

### Issue Categories (10 Core Categories)
1. **Roads & Infrastructure** - Potholes, broken footpaths, traffic signals, street repairs
2. **Cleanliness** - Garbage collection, street sweeping, littering, waste management
3. **Sanitation** - Public toilets, sewage problems, drainage issues, waste water
4. **Law & Order** - Encroachment, noise complaints, safety concerns, illegal activities
5. **Water Supply** - Water shortage, leakage, quality issues, pressure problems
6. **Electricity** - Streetlight issues, power cuts, dangerous wiring, meter problems
7. **Health & Safety** - Mosquito breeding, stray animals, hospital/clinic issues, pollution
8. **Transport** - Bus stop conditions, auto/taxi stands, parking issues, traffic problems
9. **Parks & Recreation** - Garden maintenance, playground conditions, sports facilities
10. **Education** - School infrastructure, library conditions, educational facility problems

### Status Progression Flow
```
REPORTED → ACKNOWLEDGED → IN PROGRESS → RESOLVED → VERIFIED
    ↓           ↓              ↓            ↓         ↓
Community   Official     Work Started   Work Done  Community
Reports     Recognition   by Authority   Claimed    Confirms
```

## User Flows

### Issue Reporting Flow
1. **Access reporting** → From ward page "Report Issue" button
2. **Select category** → Choose from 10 predefined categories
3. **Describe problem** → Brief title + detailed description
4. **Add location** → GPS detection or manual pin placement
5. **Upload photos** → Camera capture or file upload
6. **Review submission** → Preview all information
7. **Submit issue** → Issue goes live immediately
8. **Receive confirmation** → Email notification + platform notification
9. **Track progress** → Follow updates and community response

### Community Support Flow
1. **Discover issue** → Through browse, search, or notification
2. **Review details** → Read description, view photos, check location
3. **Show support** → Upvote to indicate agreement/priority
4. **Add information** → Comment with additional context or similar experiences
5. **Follow updates** → Subscribe to status change notifications
6. **Share externally** → Social media or messaging to increase awareness
7. **Verify resolution** → Confirm when work is actually completed

### Representative Response Flow
1. **Monitor issues** → Dashboard of all ward issues by status/priority
2. **Acknowledge issue** → Official recognition and initial response
3. **Provide updates** → Status changes with explanatory comments
4. **Coordinate resolution** → Work with relevant departments/agencies
5. **Announce completion** → Mark resolved with official confirmation
6. **Engage community** → Respond to questions and thank supporters

## Edge Cases

### Content Quality Issues
- **Spam/fake reports**: Moderation system to identify and remove false issues
- **Inappropriate content**: Community flagging and LLM screening
- **Duplicate issues**: Detection and merging of similar problems
- **Vague descriptions**: Prompts for more specific information

### Location Accuracy Issues
- **GPS errors**: Allow manual correction and address-based location
- **Privacy concerns**: Option to report general area instead of exact location
- **Outside ward boundaries**: Detection and suggestion of correct ward
- **Moving issues**: Handle problems that affect multiple locations

### Resolution Verification Issues
- **False resolution claims**: Community verification system
- **Temporary fixes**: Track if problems recur
- **Partial solutions**: Status for incomplete work
- **Disputed resolutions**: Escalation process for disagreements

## Success Metrics

### Engagement Metrics
- **Reports per ward**: Average issues reported monthly (target: >5 per active ward)
- **Community support**: Average upvotes and comments per issue (target: >3 supporters)
- **Response time**: Time from report to first official acknowledgment (target: <48 hours)
- **Resolution rate**: Percentage of reported issues marked resolved (target: >70%)

### Quality Metrics
- **Issue accuracy**: Community verification of reported problems (target: >90% accurate)
- **Resolution verification**: Community confirmation of completed work (target: >80% verified)
- **Duplicate rate**: Percentage of issues marked as duplicates (target: <10%)
- **Category usage**: Distribution across all issue categories (no category >40% of total)

### Impact Metrics
- **Official engagement**: Percentage of issues receiving official response (target: >60%)
- **Resolution time**: Average days from report to verified resolution (target: <14 days)
- **User retention**: Issue reporters who remain active on platform (target: >50%)
- **Cross-issue engagement**: Users supporting issues beyond their own reports (target: >40%)

## Technical Considerations

### Performance Requirements
- **Mobile photo upload**: Efficient image compression and upload
- **Map rendering**: Fast loading of issue locations and ward boundaries
- **Search functionality**: Quick filtering and searching across all issues
- **Real-time updates**: Live status changes and new comment notifications

### Data Management
- **Photo storage**: Efficient storage and CDN delivery of issue images
- **Location indexing**: Geographic queries for map-based issue discovery
- **History tracking**: Complete audit trail of all issue changes
- **Privacy protection**: Secure handling of user contact information

### Integration Points
- **BMC systems**: Potential integration with official complaint systems
- **Notification service**: Email, SMS, and push notification delivery
- **Social sharing**: Links and previews for external platform sharing
- **Analytics system**: Data collection for issue trend analysis

## Implementation Notes

### Phase 1 (MVP)
- Basic issue reporting with categories and photos
- Simple list and map views
- Community upvoting and commenting
- Email notifications for updates

### Phase 2 (Enhanced Features)
- Official response system integration
- Advanced filtering and search
- Issue analytics and trending
- Resolution verification workflow

### Phase 3 (Full Integration)
- BMC complaint system connection
- Automated duplicate detection
- Advanced mobile features
- Comprehensive analytics dashboard

### Success Definition
The Issues System succeeds when:
1. **Regular usage**: Citizens actively report neighborhood problems
2. **Community engagement**: Issues receive support and discussion from neighbors
3. **Official responsiveness**: Representatives use the system to communicate with constituents
4. **Visible improvements**: Real-world problems get resolved through platform coordination
5. **Trust building**: Community confidence in the system as effective advocacy tool