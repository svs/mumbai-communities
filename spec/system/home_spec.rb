require 'rails_helper'

RSpec.describe "Home", type: :system do
  let(:user) { users(:user_one) }
  let(:ward) { wards(:ward_one) }
  let(:prabhag) { prabhags(:prabhag_one) }

  describe "anonymous user" do
    it "sees landing page" do
      visit root_path

      expect(page).to have_text("MAKE REAL CHANGE")
      expect(page).to have_text("IN YOUR WARD")
      expect(page).to have_text("Join Your Ward Community")

      expect(page).to have_text("Active Ward Communities")
      expect(page).to have_text("Issues Resolved")
      expect(page).to have_text("Events This Month")

      expect(page).to have_button("Sign in with Google")
      expect(page).to have_link("Sign In")
      expect(page).to have_link("Sign Up")

      expect(page).to have_text("How It Works")
      expect(page).to have_text("Find your ward")
      expect(page).to have_text("Report issues")
      expect(page).to have_text("Join events")
      expect(page).to have_text("Build change")

      expect(page).not_to have_text("Welcome back")
      expect(page).not_to have_text("Your Active Contributions")
    end
  end

  describe "authenticated user without location" do
    it "sees dashboard" do
      skip "Requires proper sign_in helper configuration"

      sign_in user
      visit root_path

      expect(page).to have_text("Welcome back, #{user.name&.split&.first}!")
      expect(page).to have_text("Ready to continue making a difference")

      expect(page).to have_button("All Communities")
      expect(page).to have_button("New Issue")

      expect(page).to have_text("Your Recent Activity")
      expect(page).to have_text("Community Impact")

      expect(page).not_to have_button("Sign in with Google")
      expect(page).not_to have_text("Ready to Make a Difference?")
    end
  end

  describe "authenticated user with location" do
    it "gets redirected" do
      skip "Requires proper sign_in helper configuration"

      user.update!(ward_code: ward.ward_code, prabhag_id: prabhag.id)
      sign_in user

      visit root_path

      expect(page).to have_current_path(ward_prabhag_path(ward, prabhag))
    end
  end

  describe "navigation" do
    it "user can navigate to ward exploration" do
      visit root_path

      click_link "Explore Communities"

      expect(page).to have_current_path(wards_path)
    end

    it "authenticated user can access quick actions" do
      skip "Requires proper sign_in helper configuration"

      sign_in user
      visit root_path

      click_button "All Communities"
      expect(page).to have_current_path(wards_path)

      visit root_path
      click_button "New Issue"
      expect(page).to have_current_path(new_ticket_path)
    end
  end

  describe "interactive map" do
    it "is present and functional" do
      visit root_path

      expect(page).to have_css("[data-controller='leaflet-map']")
      expect(page).to have_css("[data-leaflet-map-target='container']")

      expect(page).to have_text("Active")
      expect(page).to have_text("Growing")
      expect(page).to have_text("Inactive")

      expect(page).to have_link("See Which Wards Need Help")
      expect(page).to have_link("Learn About Mapping")
    end
  end

  describe "statistics" do
    it "display correctly" do
      Ward.create!(ward_code: 998, name: "Test Ward A")
      Ward.create!(ward_code: 997, name: "Test Ward B")

      visit root_path

      within ".space-y-4" do
        expect(page).to have_text(/\d+ Active Ward Communities/)
        expect(page).to have_text(/\d+ Issues Resolved/)
        expect(page).to have_text(/\d+ Citizens Engaged/)
      end
    end
  end

  describe "authentication flow" do
    it "works" do
      visit root_path

      click_link "Sign In"
      expect(page).to have_current_path(new_user_session_path)

      visit root_path
      click_link "Sign Up"
      expect(page).to have_current_path(new_user_registration_path)
    end
  end

  describe "accessibility" do
    it "page is accessible" do
      visit root_path

      expect(page).to have_css("h1")
      expect(page).to have_css("h2")

      expect(page).to have_css("img[alt]")

      expect(page).to have_css("button:not([aria-label=''])")
    end
  end
end
