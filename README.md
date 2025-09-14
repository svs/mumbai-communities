# Mumbai Civic Action Platform

A Rails 8 platform empowering Mumbai citizens to take direct action on civic issues in their communities. This application enables residents to identify problems, organize solutions, execute improvement projects, and track real change happening in their neighborhoods.

*Note: This is an independent civic platform and is not affiliated with or endorsed by the Mumbai Municipal Corporation (MCGM) or any government entity.*

## Overview

This platform focuses on getting civic work done, enabling citizens to:

- **Problem Identification** - Document specific issues that need addressing in your area
- **Solution Development** - Collaborate on practical approaches to fix identified problems
- **Action Coordination** - Organize volunteer efforts and resource mobilization
- **Project Execution** - Track active improvement projects from start to completion
- **Impact Measurement** - Document real changes achieved through community action
- **Knowledge Sharing** - Learn from successful initiatives across different wards

## Features

- 🛠️ **Action Projects** - Create and manage civic improvement initiatives with clear goals
- 🎯 **Problem Solving** - Move beyond reporting to developing and implementing solutions
- 📊 **Impact Tracking** - Measure real changes achieved through community-driven projects
- 👥 **Volunteer Coordination** - Organize people and resources for actual civic work
- 📝 **User Authentication** via Google OAuth2 for accountable civic participation
- 📱 **Responsive Design** - Mobile-optimized interface with Mumbai skyline branding
- 🔄 **Hotwire Integration** - SPA-like experience without complex JavaScript
- 🗺️ **Ward-based Organization** - Local focus for maximum community impact

## Technology Stack

**Backend**
- Ruby on Rails 8.0.2+
- SQLite3 (development/testing)
- RGeo + RGeo-GeoJSON for spatial data
- Devise + Google OAuth2 for authentication
- Solid Cache/Queue/Cable for Rails infrastructure

**Frontend**
- Hotwire (Turbo + Stimulus)
- Tailwind CSS with Google Fonts (Inter + Barlow)
- Leaflet.js for interactive maps
- FontAwesome icons
- Propshaft asset pipeline

**Development & Deployment**
- Tidewave for Rails console/evaluation
- MiniTest for testing (no mocks)
- RuboCop Rails Omakase for code style
- Kamal for deployment
- Docker containerization

## Quick Start

### Prerequisites

- Ruby 3.2+
- Node.js 16+ (for asset compilation)
- SQLite3
- ImageMagick (for image processing)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mcgm_app
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your Google OAuth credentials:
   ```env
   GOOGLE_CLIENT_ID=your_google_client_id
   GOOGLE_CLIENT_SECRET=your_google_client_secret
   ```

4. **Set up the database**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

5. **Start the development server**
   ```bash
   bin/dev
   ```

The application will be available at `http://localhost:3000`

### Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 Client ID (Web application)
5. Add authorized redirect URI: `http://localhost:3000/users/auth/google_oauth2/callback`
6. Copy Client ID and Secret to your `.env` file

## Development

### Architecture Philosophy

This application follows Rails conventions with modern Hotwire patterns:

- **No separate API namespace** - JSON responses via format handlers
- **Hotwire-first** - Turbo + Stimulus only, no additional frontend frameworks
- **Format-based responses** - Controllers respond to both HTML and JSON
- **Comprehensive testing** - MiniTest with fixtures, no mocks
- **Semantic model finders** - Clear business logic methods

### Running Tests

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/boundary_test.rb

# Run system tests
rails test:system
```

### Code Style

```bash
# Check code style
bundle exec rubocop

# Auto-fix style issues
bundle exec rubocop -a
```

### Using Tidewave Console

Instead of `rails runner`, use Tidewave for code evaluation:

```ruby
# In Tidewave console
Ward.count
Boundary.canonical.count
```

## Data Model

### Core Entities

- **Ward** - Mumbai's 227 administrative areas, each with focused civic action initiatives
- **User** - Verified citizens committed to taking action in their communities
- **Ticket** - Civic action items (road repair projects, infrastructure improvements, etc.)
- **Prabhag** - Sub-ward units for hyper-local community action
- **Boundary** - Geographic context for location-specific civic work

### Action Project Workflow

```
open → assigned → in_progress → submitted → under_review
                                              ↓
                                         approved/completed
                                              ↓
                                          rejected
```

### Civic Action Types

- Project types: `road_repair`, `infrastructure`, `community_improvement`, `photo_documentation`, `boundary_mapping`, `other`
- Priority levels: `low`, `medium`, `high`, `urgent`
- Success tracking with completion rates and community impact metrics

## API Design

Controllers return both HTML and JSON responses without separate API endpoints:

```ruby
def index
  @wards = Ward.includes(:boundaries, :prabhags).order(:ward_code)

  respond_to do |format|
    format.html # renders wards/index.html.erb
    format.json # renders wards/index.json.jbuilder
  end
end
```

JSON responses include all rendering data to eliminate subsequent API calls.

## Deployment

### Using Kamal

```bash
# Deploy to production
kamal deploy

# Check deployment status
kamal status
```

### Docker

```bash
# Build image
docker build -t mcgm-app .

# Run container
docker run -p 3000:3000 mcgm-app
```

## Civic Action Platform Features

### Solution-Focused Project System
- Citizens create actionable improvement projects with defined outcomes
- Photo documentation of problems AND solutions implemented
- Community-driven project assignment and resource mobilization
- Status tracking from problem identification to completed solution

### Direct Action Coordination
- Ward-based action groups focused on getting things done
- Project collaboration tools for planning and execution
- Volunteer matching for specific skills and availability
- Resource sharing and community tool libraries

### Impact Measurement
- Before/after documentation of community improvements
- Success metrics and completion rate tracking
- Knowledge sharing from completed projects
- Best practices database for replicating successful initiatives

## Contributing

1. Follow Rails conventions and existing patterns
2. Write tests for all new features (MiniTest, no mocks)
3. Use semantic naming for business logic methods
4. Ensure responsive design works on mobile devices
5. Run code style checks before committing

### Key Conventions

- Use Tidewave instead of `rails runner` for console work
- Avoid separate API namespaces - use format handlers
- Include all data needed for rendering in JSON responses
- Follow the semantic boundary finder pattern in models

## Zone Coverage

The application covers all Mumbai electoral zones:

- **Zone A**: 3 wards (225-227)
- **Zone B**: 2 wards (223-224)
- **Zone C**: 3 wards (220-222)
- **Zone D**: 6 wards (214-219)
- **Zone E**: 7 wards (207-213)
- **Zone F NORTH**: 10 wards (172-181)
- **Zone F SOUTH**: 7 wards (200-206)
- **Zone G NORTH**: 11 wards (182-192)
- **Zone K NORTH**: 8 wards (72-79)
- **Zone R/Central**: 10 wards (9-18)

## License

This is an independent civic platform created to empower Mumbai citizens to take direct action on community issues. Not affiliated with any government entity.

## Support

For technical issues or questions about the codebase, refer to the `CLAUDE.md` file for detailed architectural documentation.
