require 'rails_helper'

RSpec.describe "Admin - Prabhags", type: :system do
  fixtures :users, :wards

  let(:admin) { users(:admin_2) }
  let(:regular_user) { users(:user_one) }
  let(:ward) { wards(:ward_one) }

  describe "dashboard access" do
    before do
      create(:prabhag, :submitted, assigned_to: regular_user, ward_code: ward.ward_code, ward: ward)
      create(:prabhag, :approved, assigned_to: regular_user, ward_code: ward.ward_code, ward: ward)
      create(:prabhag, :rejected, ward_code: ward.ward_code, ward: ward)
    end

    it "shows admin panel with statistics" do
      login_as(admin, scope: :user)
      visit admin_prabhags_path

      expect(page).to have_text("Admin Panel")
      expect(page).to have_text("Boundary Review")
    end

    it "denies access to non-admin users" do
      login_as(regular_user, scope: :user)
      visit admin_prabhags_path

      expect(page).to have_text("Access denied")
    end

    it "shows pending review count" do
      login_as(admin, scope: :user)
      visit admin_prabhags_path

      expect(page).to have_text("Pending Review")
      expect(page).to have_text("1")
    end

    it "shows approved count" do
      login_as(admin, scope: :user)
      visit admin_prabhags_path

      expect(page).to have_text("Approved")
      expect(page).to have_text("1")
    end

    it "shows rejected count" do
      login_as(admin, scope: :user)
      visit admin_prabhags_path

      expect(page).to have_text("Rejected")
      expect(page).to have_text("1")
    end
  end

  describe "pending submissions" do
    let!(:submitted_prabhag) do
      create(:prabhag, :submitted, :with_pending_boundary,
             assigned_to: regular_user,
             ward_code: ward.ward_code,
             ward: ward)
    end

    it "shows prabhag details" do
      login_as(admin, scope: :user)
      visit admin_prabhags_path

      expect(page).to have_text(submitted_prabhag.number)
      expect(page).to have_text(ward.ward_code)
      expect(page).to have_text(regular_user.email)
    end

    it "shows review button" do
      login_as(admin, scope: :user)
      visit admin_prabhags_path

      expect(page).to have_link("Review", href: boundaries_admin_prabhag_path(submitted_prabhag))
    end

    it "shows empty state when no submissions" do
      submitted_prabhag.destroy

      login_as(admin, scope: :user)
      visit admin_prabhags_path

      expect(page).to have_text("No prabhags pending review")
    end
  end

  describe "approved prabhags" do
    let!(:approved_prabhag) do
      create(:prabhag, :approved, :with_approved_boundary,
             assigned_to: regular_user,
             ward_code: ward.ward_code,
             ward: ward)
    end

    it "shows in recently approved section" do
      login_as(admin, scope: :user)
      visit admin_prabhags_path

      expect(page).to have_text("Recently Approved")
      expect(page).to have_text(approved_prabhag.number)
    end

    it "has view link" do
      login_as(admin, scope: :user)
      visit admin_prabhags_path

      within(".approved-prabhags") do
        expect(page).to have_link("View", href: admin_prabhag_path(approved_prabhag))
      end
    end
  end

  describe "rejected prabhags" do
    let!(:rejected_prabhag) do
      create(:prabhag, :rejected,
             ward_code: ward.ward_code,
             ward: ward)
    end

    it "shows in recently rejected section" do
      login_as(admin, scope: :user)
      visit admin_prabhags_path

      expect(page).to have_text("Recently Rejected")
      expect(page).to have_text(rejected_prabhag.number)
    end

    it "has view link" do
      login_as(admin, scope: :user)
      visit admin_prabhags_path

      within(".rejected-prabhags") do
        expect(page).to have_link("View", href: admin_prabhag_path(rejected_prabhag))
      end
    end
  end

  describe "prabhag details page" do
    let!(:prabhag) { create(:prabhag, :submitted, assigned_to: regular_user, ward_code: ward.ward_code, ward: ward) }

    it "shows prabhag information" do
      login_as(admin, scope: :user)
      visit admin_prabhag_path(prabhag)

      expect(page).to have_text(prabhag.number)
      expect(page).to have_text(ward.ward_code)
      expect(page).to have_text("submitted")
      expect(page).to have_text(regular_user.email)
    end

    context "with pending boundary" do
      let!(:boundary) { create(:boundary, :pending, boundable: prabhag, submitted_by: regular_user) }

      it "renders map" do
        login_as(admin, scope: :user)
        visit admin_prabhag_path(prabhag)

        expect(page).to have_css("#map")
      end
    end

    context "with malformed geojson" do
      let!(:boundary) do
        create(:boundary, :pending,
               boundable: prabhag,
               submitted_by: regular_user,
               geojson: "invalid json {{{")
      end

      it "handles gracefully without crashing" do
        login_as(admin, scope: :user)
        visit admin_prabhag_path(prabhag)

        expect(page).to have_text(prabhag.number)
      end
    end
  end

  describe "boundary review page" do
    let!(:prabhag) { create(:prabhag, :submitted, assigned_to: regular_user, ward_code: ward.ward_code, ward: ward) }
    let!(:boundary) { create(:boundary, :pending, boundable: prabhag, submitted_by: regular_user) }

    it "shows boundary metadata" do
      login_as(admin, scope: :user)
      visit boundaries_admin_prabhag_path(prabhag)

      expect(page).to have_text(prabhag.number)
      expect(page).to have_text(ward.ward_code)
      expect(page).to have_text(regular_user.email)
      expect(page).to have_text("pending")
    end

    it "shows approve and reject buttons" do
      login_as(admin, scope: :user)
      visit boundaries_admin_prabhag_path(prabhag)

      expect(page).to have_button("Approve")
      expect(page).to have_button("Reject")
    end
  end

  describe "approving boundary" do
    let!(:prabhag) { create(:prabhag, :submitted, assigned_to: regular_user, ward_code: ward.ward_code, ward: ward) }
    let!(:boundary) { create(:boundary, :pending, boundable: prabhag, submitted_by: regular_user) }

    it "changes status and redirects" do
      login_as(admin, scope: :user)
      visit boundaries_admin_prabhag_path(prabhag)

      click_button "Approve"

      expect(page).to have_text("approved successfully")
      expect(current_path).to eq(admin_prabhag_path(prabhag))

      prabhag.reload
      boundary.reload
      expect(prabhag.status).to eq("approved")
      expect(boundary.status).to eq("approved")
    end

    it "moves to approved section on dashboard" do
      login_as(admin, scope: :user)
      visit boundaries_admin_prabhag_path(prabhag)

      click_button "Approve"
      visit admin_prabhags_path

      within(".pending-review") do
        expect(page).not_to have_text(prabhag.number)
      end

      within(".approved-prabhags") do
        expect(page).to have_text(prabhag.number)
      end
    end
  end

  describe "rejecting boundary" do
    let!(:prabhag) { create(:prabhag, :submitted, assigned_to: regular_user, ward_code: ward.ward_code, ward: ward) }
    let!(:boundary) { create(:boundary, :pending, boundable: prabhag, submitted_by: regular_user) }

    it "changes status and unassigns prabhag" do
      login_as(admin, scope: :user)
      visit boundaries_admin_prabhag_path(prabhag)

      click_button "Reject"

      expect(page).to have_text("rejected")
      expect(page).to have_text("available for reassignment")
      expect(current_path).to eq(admin_prabhag_path(prabhag))

      prabhag.reload
      boundary.reload
      expect(prabhag.status).to eq("available")
      expect(boundary.status).to eq("rejected")
      expect(prabhag.assigned_to).to be_nil
    end

    it "moves to rejected section on dashboard" do
      login_as(admin, scope: :user)
      visit boundaries_admin_prabhag_path(prabhag)

      click_button "Reject"
      visit admin_prabhags_path

      expect(page).not_to have_text("Pending Review")

      within(".rejected-prabhags") do
        expect(page).to have_text(prabhag.number)
      end
    end
  end

  describe "edge cases" do
    let!(:prabhag) { create(:prabhag, :submitted, assigned_to: regular_user, ward_code: ward.ward_code, ward: ward) }

    it "handles missing pending boundary" do
      login_as(admin, scope: :user)
      visit boundaries_admin_prabhag_path(prabhag)

      expect(page).to have_text("No pending boundary found")
    end

    it "prevents double approval" do
      boundary = create(:boundary, :approved, boundable: prabhag, submitted_by: regular_user)

      login_as(admin, scope: :user)
      visit boundaries_admin_prabhag_path(prabhag)

      expect(page).not_to have_button("Approve")
      expect(page).not_to have_button("Reject")
    end
  end

  describe "public page protection" do
    it "does not show approve/reject buttons" do
      prabhag = create(:prabhag, :submitted, assigned_to: admin, ward_code: ward.ward_code, ward: ward)
      create(:boundary, :pending, boundable: prabhag, submitted_by: admin)

      login_as(admin, scope: :user)
      visit prabhag_path(prabhag)

      expect(page).to have_text("Submitted for Review")
      expect(page).not_to have_button("Approve")
      expect(page).not_to have_button("Reject")
    end
  end
end
