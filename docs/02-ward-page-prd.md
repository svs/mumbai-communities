# Ward/Prabhag Page PRD - Mumbai Ward Civic Engagement Platform

## Overview

The Ward/Prabhag page is the community hub for each of Mumbai's 227 electoral wards. It evolves from a simple "help map this ward" call-to-action to a comprehensive civic engagement platform once boundaries are mapped. This page serves as the primary interface for ward-specific community building, issue tracking, and local governance interaction.

## User Stories

### Primary Users
- **Ward residents** want to report issues, participate in discussions, and stay informed about their area
- **Community activists** want to organize events, track issues, and build neighborhood networks
- **Local representatives** want to understand constituent concerns and communicate updates
- **New residents** want to learn about their ward's characteristics, issues, and community

### Core User Stories

#### Pre-Mapping (Unmapped Ward)
- As a **ward resident**, I want to help map my ward so I can unlock community features
- As a **mapper**, I want to see if anyone else is working on this ward so I can coordinate or find another
- As a **visitor**, I want to understand why this ward needs mapping so I can decide whether to contribute

#### Post-Mapping (Active Ward)
- As a **resident**, I want to report problems in my ward so they can be tracked and addressed
- As a **community member**, I want to see ongoing issues so I can add support or additional information
- As a **activist**, I want to organize meetups so I can build local engagement
- As a **representative**, I want to respond to community concerns so I can show accountability
- As a **newcomer**, I want to learn about my ward's character so I can integrate into the community

## Functional Requirements

### Must Have - All States
1. **Ward Identity**: Clear display of ward number, name, zone, and boundaries
2. **Status Indicator**: Whether ward is unmapped, mapped, or fully active
3. **Basic Information**: Demographics, area coverage, representative details
4. **Navigation**: Links back to city map and other ward pages

### Must Have - Unmapped Ward
1. **Mapping Call-to-Action**: Prominent button to start mapping process
2. **Progress Tracking**: If mapping in progress, show completion status
3. **Contributor Recognition**: Display who is currently mapping (if any)

### Must Have - Mapped Ward
1. **Issue Reporting**: Form to submit new problems with photo and location
2. **Issue Display**: List/map view of reported issues with status
3. **Discussion Threads**: Community conversations about ward topics
4. **Representative Contact**: Easy access to elected official information
5. **Photo Gallery**: Community-shared images (problems and positive aspects)

### Should Have - Mapped Ward
1. **Events Calendar**: Upcoming community meetups and activities
2. **Activity Feed**: Recent actions (issues reported, discussions, photos)
3. **Ward Statistics**: Issue resolution rates, community engagement metrics
4. **Resource Links**: Important contacts, services, government forms

### Could Have - Mapped Ward
1. **Comparison Tools**: How this ward compares to neighboring wards
2. **Historical Data**: Track changes over time
3. **Volunteer Opportunities**: Ways to get more involved
4. **Integration**: Links to WhatsApp groups, social media

## UI/UX Specifications

### Page Header (All States)
```
← Back to Map                                      Share Ward | Follow

Ward 72 - Jogeshwari West
K-North Zone | Population: 59,055 | Area: 2.3 km²

[Ward boundary map thumbnail]    Status: ⚪ Unmapped / 🟡 Mapping / 🟢 Active

Representative: Councilor Name | 📞 Contact | 📧 Email
```

### Unmapped Ward State
```
┌─────────────────────────────────────────────────┐
│                HELP MAP THIS WARD               │
│                                                 │
│  This ward needs community mapping to unlock    │
│  issue reporting, discussions, and events       │
│                                                 │
│  📍 Current Status: Unmapped                    │
│  👥 Contributors Needed: You could be first!    │
│  ⏱️  Estimated Time: 30-45 minutes               │
│                                                 │
│         [Start Mapping This Ward]               │
│                                                 │
└─────────────────────────────────────────────────┘

Ward Demographics
├─ Total Population: 59,055
├─ SC Population: 1,666
├─ ST Population: 355
└─ Primary Area: Jogeshwari West

What happens after mapping?
• Report and track local issues
• Join community discussions
• Organize neighborhood meetups
• Connect with neighbors and representatives
```

### Active Ward State
```
Quick Actions
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ 🚨 Report     │ │ 💬 Discuss   │ │ 📅 Events    │ │ 📷 Gallery   │
│   Issue       │ │              │ │              │ │              │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘

Issues in Ward 72                                    [View All] [Report New]
┌─────────────────────────────────────────────────┐
│ 🔴 Pothole on SV Road                           │ Status: Reported
│ Reported 2 days ago by Priya S. | 👍 12 votes   │
├─────────────────────────────────────────────────┤
│ 🟡 Garbage collection missed                    │ Status: In Progress
│ Reported 1 week ago by Raj K. | 👍 8 votes      │
├─────────────────────────────────────────────────┤
│ 🟢 Streetlight fixed on Station Road            │ Status: Resolved
│ Reported 2 weeks ago by Maya P. | 👍 15 votes   │ ✓ Verified
└─────────────────────────────────────────────────┘

Recent Activity                           Community Stats
• New issue: Water leakage (2 hours ago)   📊 23 active issues
• Discussion: Park maintenance started     👥 156 community members
• Event: Clean-up drive scheduled          🎯 72% issue resolution rate
• Photo added: New mural completed         📈 +12 new members this week

Upcoming Events                                     [View All] [Create Event]
📅 Saturday Clean-up Drive
   March 15, 9:00 AM at Community Garden
   12 attending | Organized by Local Green Group

📅 Ward Issues Discussion
   March 20, 6:00 PM at Community Hall
   5 attending | Organized by Residents Association
```

### Issue Detail View (Modal/Page)
```
🔴 Pothole on SV Road - Near McDonald's

📍 Location: Linking Road Junction [View on Map]
📅 Reported: March 10, 2024 by Priya Shah
🏷️  Category: Roads & Infrastructure
👍 Support: 12 residents support this issue

[Photo of pothole]

Description:
Large pothole causing traffic issues and vehicle damage.
Water collects here during rains making it worse.

Status Updates:
✓ Issue reported to BMC (March 10)
✓ Site inspection completed (March 12)
🕐 Repair work scheduled (March 18)

Community Discussion (8 comments)
💬 Raj Kumar: "I damaged my bike tire here yesterday"
💬 Maya Patel: "BMC said they'll fix it by week-end"
💬 Local Activist: "Similar issue on next street too"

[Add Your Comment] [Support This Issue] [Update Status]
```

## Information Architecture

### Page Structure

1. **Ward Header**
   - Ward identification (number, name, zone)
   - Basic demographics and area info
   - Representative contact information
   - Status and mapping attribution

2. **Action Bar** (mapped wards)
   - Primary actions: Report Issue, Join Discussion, Create Event, Add Photo
   - Quick navigation to major sections

3. **Main Content Area**
   - **Issues Section**: Active problems, resolution tracking
   - **Discussions Section**: Community conversations
   - **Events Section**: Upcoming meetups and activities
   - **Gallery Section**: Photo sharing (problems and positives)

4. **Sidebar/Secondary**
   - Ward statistics and metrics
   - Recent activity feed
   - Community member highlights
   - Quick links and resources

### Data Organization

#### Ward Information
- **Identity**: Number, name, zone designation
- **Demographics**: Population (total, SC, ST), area size
- **Boundaries**: GeoJSON polygon data
- **Representatives**: Councilor, MLA contact information
- **Status**: Mapping status, activity level

#### Issue Tracking
- **Categories**: Roads, Cleanliness, Sanitation, Law & Order, Water, Electricity, Health, Transport, Parks, Education
- **Status Flow**: Reported → Acknowledged → In Progress → Resolved → Verified
- **Metadata**: Reporter, date, location, photos, votes, comments

#### Community Content
- **Discussions**: Topics, threads, comments, moderation
- **Events**: Title, date/time, location, organizer, attendees
- **Gallery**: Photos with categories (problems, improvements, culture, events)
- **Activity**: Time-ordered feed of all ward actions

## User Flows

### Unmapped Ward Discovery Flow
1. **Find ward** (via homepage map/search)
2. **View unmapped state** → See mapping call-to-action
3. **Decision point**: Start mapping OR explore other wards OR leave
4. **Start mapping** → Redirect to mapping interface
5. **Complete mapping** → Ward changes to mapped state
6. **Return to ward** → See unlocked features

### Issue Reporting Flow (Mapped Ward)
1. **Access ward page** → See current issues
2. **Click "Report Issue"** → Open issue form
3. **Fill details**: Category, description, location, photo
4. **Submit** → Issue appears in ward feed
5. **Community engagement**: Others vote, comment, add info
6. **Official response**: Status updates from representatives
7. **Resolution**: Issue marked resolved, community verification

### Community Building Flow
1. **Join ward community** → Follow/subscribe to ward
2. **Participate in discussions** → Comment on topics
3. **Organize event** → Create meetup
4. **Build reputation** → Gain trust through contributions
5. **Become ward champion** → Earn moderation privileges

## Edge Cases

### Mapping Transition Issues
- **Multiple mappers**: Handle conflicts when multiple users map same ward simultaneously
- **Incomplete mapping**: What to show if mapping is abandoned partway through
- **Verification delays**: User expectations while waiting for mapping verification

### Content Management
- **Spam/abuse**: Users reporting fake issues or inappropriate content
- **Representative absence**: What to show if no official contact information available
- **Low activity**: How to encourage engagement in quiet wards
- **High volume**: Managing wards with overwhelming activity

### Technical Issues
- **Slow loading**: Progressive loading for wards with lots of content
- **Mobile optimization**: Complex interface simplified for small screens
- **Offline access**: Core information available without internet

## Success Metrics

### Engagement Metrics
- **Page views per ward**: Average daily/weekly traffic
- **Time on page**: User engagement depth (target: > 3 minutes)
- **Return visits**: Users coming back to check updates (target: > 40%)
- **Action conversion**: Visitors who take actions like reporting issues (target: > 15%)

### Community Building
- **Issue reports per ward**: Community problem identification (target: > 2 per week for active wards)
- **Discussion participation**: Comments and thread engagement
- **Event creation**: Community organizing activity
- **Resolution rate**: Issues moving from reported to resolved (target: > 60%)

### Content Quality
- **Issue verification**: Community or official confirmation of problems
- **Photo contributions**: Visual documentation of ward conditions
- **Representative engagement**: Official responses to community issues
- **Moderation efficiency**: Time to address inappropriate content

## Technical Considerations

### Performance
- **Lazy loading**: Issues, photos, and discussions load as needed
- **Caching**: Ward static information cached aggressively
- **Database optimization**: Efficient queries for activity feeds and issue lists
- **Image optimization**: Compressed photos with progressive loading

### Real-time Features
- **Activity updates**: Live feed of new issues, comments, events
- **Notification system**: Alerts for ward updates and responses
- **Collaborative editing**: Multiple users contributing to discussions
- **Status synchronization**: Real-time issue status updates

### Mobile Optimization
- **Touch interface**: Large buttons for reporting, commenting, voting
- **Camera integration**: Direct photo capture for issue reports
- **GPS integration**: Automatic location detection for issues
- **Offline capability**: Core ward info available without connection

### Privacy & Security
- **Location privacy**: General area only, not exact addresses for issues
- **User anonymity**: Option to report issues without public attribution
- **Content moderation**: LLM filtering plus community flagging
- **Data protection**: User personal information secured

## Implementation Notes

### Phase 1 (Mapping Campaign)
- Simple unmapped state with mapping call-to-action
- Basic ward information display
- Attribution for mapper
- Status tracking (unmapped → mapping → mapped)

### Phase 2 (Basic Community Features)
- Issue reporting and display
- Simple discussion threads
- Representative contact information
- Basic photo gallery

### Phase 3 (Advanced Community)
- Event creation and management
- Advanced discussion moderation
- Community statistics and comparisons
- Integration with external systems

### Integration Points
- **Mapping tool**: Seamless transition to/from boundary tracing
- **User profiles**: Show user's activity across platform
- **Search system**: Ward content discoverable city-wide
- **Notification system**: Updates delivered via multiple channels
- **Admin tools**: Moderation and management interfaces