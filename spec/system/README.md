# System Test Outline

This directory contains a comprehensive BDD test outline for the MCGM Ward Boundary Application. All tests are currently **skipped** and serve as a specification for implementation.

## Overview

**Total Examples: 326 (all pending)**

The test suite is organized into three main user types with domain/feature-based structure:

## Directory Structure

```
spec/system/
├── admin/                    # 3 files, ~100 examples
│   ├── access_spec.rb
│   ├── boundaries_spec.rb     # reviewing, approving, rejecting, editing, deleting, managing index
│   └── prabhags_spec.rb
│
├── authenticated/            # 8 files, ~140 examples
│   ├── dashboard_spec.rb
│   ├── session_spec.rb
│   ├── password_spec.rb
│   ├── profile_spec.rb
│   ├── location_spec.rb
│   ├── prabhags_spec.rb       # self-assigning
│   ├── boundaries_spec.rb     # tracing, submitting
│   └── tickets_spec.rb
│
└── anonymous/                # 4 files, ~86 examples
    ├── home_spec.rb
    ├── wards_spec.rb
    ├── prabhags_spec.rb
    └── authentication_spec.rb
```

## Organization Philosophy

The structure follows an "onion" or hierarchical approach:

- **Top level**: User type (`admin/`, `authenticated/`, `anonymous/`)
- **Files**: Domain objects/features (`boundaries_spec.rb`, `prabhags_spec.rb`, etc.)
- **Inside files**: Behaviors/actions as nested `describe` blocks
- **Leaf nodes**: Assertions as `it` blocks

### Example:
```ruby
# spec/system/admin/boundaries_spec.rb
RSpec.describe "Admin - Boundaries" do
  describe "approving" do
    describe "initiating approval" do
      it "clicking approve button" do
        # ...
      end
    end
  end
end
```

This produces output like:
```
Admin - Boundaries
  approving
    initiating approval
      clicking approve button
```

## Running Tests

### Run all system tests:
```bash
bundle exec rspec spec/system
```

### Run by user type:
```bash
bundle exec rspec spec/system/admin
bundle exec rspec spec/system/authenticated
bundle exec rspec spec/system/anonymous
```

### Run specific domain:
```bash
bundle exec rspec spec/system/admin/boundaries_spec.rb
bundle exec rspec spec/system/authenticated/prabhags_spec.rb
```

### Show test outline (dry-run):
```bash
bundle exec rspec spec/system --dry-run --format documentation
```

## Implementation Strategy

1. **Start with Anonymous Users** - These are the most basic flows and don't require authentication
   - `anonymous/home_spec.rb` - Landing page
   - `anonymous/wards_spec.rb` - Browsing wards
   - `anonymous/prabhags_spec.rb` - Browsing prabhags
   - `anonymous/authentication_spec.rb` - Auth flows

2. **Move to Authenticated Users** - Build on anonymous user tests, add authentication
   - `authenticated/session_spec.rb` - Sign in/out
   - `authenticated/dashboard_spec.rb` - Personalized dashboard
   - `authenticated/location_spec.rb` - Location setup
   - `authenticated/prabhags_spec.rb` - Self-assignment
   - `authenticated/boundaries_spec.rb` - Tracing & submitting
   - `authenticated/password_spec.rb` - Password management
   - `authenticated/profile_spec.rb` - Profile management
   - `authenticated/tickets_spec.rb` - Ticket management

3. **Finish with Admin Users** - Most complex, requires full authentication and authorization
   - `admin/access_spec.rb` - Admin authorization
   - `admin/prabhags_spec.rb` - Prabhag management
   - `admin/boundaries_spec.rb` - Complete boundary workflow (review, approve, reject, edit, delete)

## TDD Workflow

For each skipped test:

1. **Unskip the test** - Remove the `skip` line
2. **Run the test** - It should fail (red)
3. **Write minimum code** - Make it pass (green)
4. **Refactor** - Clean up while keeping tests green
5. **Commit** - Commit the passing test and implementation

### Example:
```ruby
# Before (skipped):
it "shows 'MAKE REAL CHANGE IN YOUR WARD' heading" do
  skip "Not yet implemented"
end

# After (implemented):
it "shows 'MAKE REAL CHANGE IN YOUR WARD' heading" do
  visit root_path
  expect(page).to have_text("MAKE REAL CHANGE IN YOUR WARD")
end
```

## Notes

- All tests use Capybara for system testing
- Tests are written in RSpec
- No mocks should be used (per project guidelines)
- Tests should read like specifications
- Each test should be independent and idempotent
- Files are organized by domain/feature, not by action
- Multiple related behaviors live in the same file under different `describe` blocks

## Related Documentation

- `spec/SPEC.md` - Complete behavioral specification
- Main project `CLAUDE.md` - Development conventions and architecture

---

*This test suite was auto-generated from the behavioral specification. Implement tests one at a time following TDD principles.*
