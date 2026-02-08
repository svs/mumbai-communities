require 'rails_helper'

RSpec.describe "Authenticated - Prabhags", type: :system do
  describe "self-assigning" do
    describe "viewing available prabhag" do
      it "shows 'Assign to me' button when available" do
        skip "Not yet implemented"
      end

      it "hides button when already assigned" do
        skip "Not yet implemented"
      end

      it "hides button when not available" do
        skip "Not yet implemented"
      end
    end

    describe "assigning prabhag to self" do
      it "updates prabhag status to 'assigned'" do
        skip "Not yet implemented"
      end

      it "sets current user as assigned_to" do
        skip "Not yet implemented"
      end

      it "redirects to trace page" do
        skip "Not yet implemented"
      end

      it "shows success notice 'Prabhag assigned to you'" do
        skip "Not yet implemented"
      end
    end

    describe "preventing invalid assignments" do
      it "blocks assignment if already assigned" do
        skip "Not yet implemented"
      end

      it "blocks assignment if not available" do
        skip "Not yet implemented"
      end
    end

    describe "viewing assignments" do
      it "displays current assignments on dashboard" do
        skip "Not yet implemented"
      end

      it "shows assigned prabhags in 'assigned' status" do
        skip "Not yet implemented"
      end

      it "shows submitted prabhags in 'submitted' status" do
        skip "Not yet implemented"
      end
    end
  end
end
