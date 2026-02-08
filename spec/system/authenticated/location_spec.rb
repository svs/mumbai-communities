require 'rails_helper'

RSpec.describe "Authenticated - Location", type: :system do
  describe "initial location setup" do
    it "redirects to setup when no location" do
      skip "Not yet implemented"
    end

    it "displays location setup form at /setup_location" do
      skip "Not yet implemented"
    end
  end

  describe "searching for location" do
    describe "using autocomplete" do
      it "shows address suggestions" do
        skip "Not yet implemented"
      end

      it "populates address field on selection" do
        skip "Not yet implemented"
      end

      it "populates coordinates on selection" do
        skip "Not yet implemented"
      end
    end

    describe "selecting on map" do
      it "captures latitude" do
        skip "Not yet implemented"
      end

      it "captures longitude" do
        skip "Not yet implemented"
      end
    end
  end

  describe "submitting location" do
    describe "with valid coordinates" do
      it "determines ward and prabhag" do
        skip "Not yet implemented"
      end

      it "saves street address" do
        skip "Not yet implemented"
      end

      it "saves ward code" do
        skip "Not yet implemented"
      end

      it "saves prabhag ID" do
        skip "Not yet implemented"
      end

      it "saves coordinates (lat/lng)" do
        skip "Not yet implemented"
      end

      it "sets location_confirmed_at timestamp" do
        skip "Not yet implemented"
      end

      it "redirects to root" do
        skip "Not yet implemented"
      end
    end

    describe "with invalid coordinates" do
      it "shows error" do
        skip "Not yet implemented"
      end

      it "stays on setup page" do
        skip "Not yet implemented"
      end

      it "does not save location" do
        skip "Not yet implemented"
      end
    end
  end

  describe "viewing location information" do
    it "displays location summary" do
      skip "Not yet implemented"
    end

    it "shows current ward" do
      skip "Not yet implemented"
    end

    it "shows current prabhag" do
      skip "Not yet implemented"
    end

    it "indicates if location is set" do
      skip "Not yet implemented"
    end

    it "indicates if location is confirmed" do
      skip "Not yet implemented"
    end
  end
end
