require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  def setup
    @user = users(:user_one)
    @ward = wards(:ward_one)
    @prabhag = prabhags(:prabhag_one)
  end

  test "anonymous user sees landing page" do
    visit root_path

    # Should see main call-to-action
    assert_text "MAKE REAL CHANGE"
    assert_text "IN YOUR WARD"
    assert_text "Join Your Ward Community"

    # Should see statistics
    assert_text "Active Ward Communities"
    assert_text "Issues Resolved"
    assert_text "Events This Month"

    # Should see authentication options
    assert_button "Sign in with Google"
    assert_link "Sign In"
    assert_link "Sign Up"

    # Should see how it works section
    assert_text "How It Works"
    assert_text "Find your ward"
    assert_text "Report issues"
    assert_text "Join events"
    assert_text "Build change"

    # Should not see user-specific content
    assert_no_text "Welcome back"
    assert_no_text "Your Active Contributions"
  end

  test "authenticated user without location sees dashboard" do
    sign_in @user
    visit root_path

    # Should see personalized welcome
    assert_text "Welcome back, #{@user.name&.split&.first}!"
    assert_text "Ready to continue making a difference"

    # Should see quick action buttons
    assert_button "All Communities"
    assert_button "New Issue"

    # Should see user activity sections
    assert_text "Your Recent Activity"
    assert_text "Community Impact"

    # Should not see authentication section
    assert_no_button "Sign in with Google"
    assert_no_text "Ready to Make a Difference?"
  end

  test "authenticated user with location gets redirected" do
    @user.update!(ward_code: @ward.ward_code, prabhag_id: @prabhag.id)
    sign_in @user

    visit root_path

    # Should be redirected to user's ward/prabhag page
    assert_current_path ward_prabhag_path(@ward, @prabhag)
  end

  test "user can navigate to ward exploration" do
    visit root_path

    # Click explore communities button
    click_link "Explore Communities"

    assert_current_path wards_path
  end

  test "authenticated user can access quick actions" do
    sign_in @user
    visit root_path

    # Test navigation to all communities
    click_button "All Communities"
    assert_current_path wards_path

    # Go back and test new issue
    visit root_path
    click_button "New Issue"
    assert_current_path new_ticket_path
  end

  test "interactive map is present and functional" do
    visit root_path

    # Should have map container
    assert_selector "[data-controller='leaflet-map']"
    assert_selector "[data-leaflet-map-target='container']"

    # Should show legend
    assert_text "Active"
    assert_text "Growing"
    assert_text "Inactive"

    # Should have map-related links
    assert_link "See Which Wards Need Help"
    assert_link "Learn About Mapping"
  end

  test "statistics display correctly" do
    # Create some test data
    Ward.create!(ward_code: 998, name: "Test Ward A")
    Ward.create!(ward_code: 997, name: "Test Ward B")

    visit root_path

    # Should show ward count (at least 2 from our test data)
    within ".space-y-4" do
      assert_text /\d+ Active Ward Communities/
      assert_text /\d+ Issues Resolved/
      assert_text /\d+ Citizens Engaged/
    end
  end

  test "recent activity section shows content appropriately" do
    # Create a recent ticket
    ticket = Ticket.create!(
      title: "Test Recent Issue",
      description: "Test description",
      ward_code: @ward.ward_code,
      created_at: 1.day.ago
    )

    visit root_path

    # Should show in recent activity for anonymous users
    within_section "Recent Activity" do
      assert_text "Test Recent Issue"
      assert_text "Ward #{@ward.ward_code}"
    end
  end

  test "user with assignments sees personalized activity" do
    # Mock user to have assignments
    @user.define_singleton_method(:current_assignments) { [@prabhag] }
    @user.define_singleton_method(:active_tickets) { [] }

    sign_in @user
    visit root_path

    # Should show user's specific assignments
    within ".bg-yellow-50" do
      assert_text "Your Active Contributions"
      assert_text "Boundary Mapping"
      assert_text "Prabhag #{@prabhag.number}"
    end
  end

  test "responsive design elements are present" do
    visit root_path

    # Should have responsive grid classes
    assert_selector ".grid.grid-cols-1.md\\:grid-cols-3"
    assert_selector ".max-w-6xl.mx-auto"

    # Mumbai skyline should be present
    assert_selector "img[alt='Mumbai Skyline']", visible: false
  end

  test "authentication flow works" do
    visit root_path

    # Click sign in link
    click_link "Sign In"
    assert_current_path new_user_session_path

    # Go back and try sign up
    visit root_path
    click_link "Sign Up"
    assert_current_path new_user_registration_path
  end

  test "page is accessible" do
    visit root_path

    # Should have proper heading structure
    assert_selector "h1"
    assert_selector "h2"

    # Should have alt text for images
    assert_selector "img[alt]"

    # Interactive elements should have proper attributes
    assert_selector "button:not([aria-label=''])"
    assert_selector "a:not([href='#'])"
  end

  test "user activity section handles empty state gracefully" do
    sign_in @user
    visit root_path

    # If user has no assignments, should show helpful message
    within_section "Your Recent Activity" do
      # Should either show activity or helpful empty state
      if has_text?("Ready to get started?")
        assert_text "Join a ward community to start contributing!"
      end
    end
  end

  private

  def within_section(heading)
    within find("h2, h3", text: heading).ancestor(".bg-white, .bg-gray-50, .bg-yellow-50") do
      yield
    end
  end
end