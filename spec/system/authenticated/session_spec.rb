require 'rails_helper'

RSpec.describe "Authenticated - Session", type: :system do
  describe "signing in with email" do
    it "accepts valid credentials" do
      skip "Not yet implemented"
    end

    it "redirects to root path after sign in" do
      skip "Not yet implemented"
    end

    describe "tracking sign in activity" do
      it "records current sign in timestamp" do
        skip "Not yet implemented"
      end

      it "records last sign in timestamp" do
        skip "Not yet implemented"
      end

      it "increments sign in count" do
        skip "Not yet implemented"
      end

      it "records current sign in IP" do
        skip "Not yet implemented"
      end

      it "records last sign in IP" do
        skip "Not yet implemented"
      end
    end
  end

  describe "signing in with Google OAuth2" do
    it "processes OAuth callback" do
      skip "Not yet implemented"
    end

    it "creates account if new user" do
      skip "Not yet implemented"
    end

    it "signs in existing user" do
      skip "Not yet implemented"
    end

    it "saves OAuth provider and uid" do
      skip "Not yet implemented"
    end
  end

  describe "signing out" do
    it "logs user out" do
      skip "Not yet implemented"
    end

    it "redirects to root path" do
      skip "Not yet implemented"
    end
  end

  describe "maintaining session" do
    it "persists across page navigation" do
      skip "Not yet implemented"
    end

    it "expires after timeout" do
      skip "Not yet implemented"
    end
  end
end
