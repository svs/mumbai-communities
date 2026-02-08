require 'rails_helper'

RSpec.describe "Authenticated - Password", type: :system do
  describe "requesting password reset" do
    it "sends password reset email" do
      skip "Not yet implemented"
    end

    it "generates reset token" do
      skip "Not yet implemented"
    end
  end

  describe "resetting password" do
    describe "with valid token" do
      it "updates password" do
        skip "Not yet implemented"
      end

      it "redirects to sign in" do
        skip "Not yet implemented"
      end
    end

    describe "with invalid token" do
      it "shows error" do
        skip "Not yet implemented"
      end

      it "does not update password" do
        skip "Not yet implemented"
      end
    end

    describe "with expired token" do
      it "shows error" do
        skip "Not yet implemented"
      end

      it "does not update password" do
        skip "Not yet implemented"
      end
    end
  end

  describe "changing password from profile" do
    it "requires current password" do
      skip "Not yet implemented"
    end

    it "updates password on success" do
      skip "Not yet implemented"
    end

    it "sends notification email after change" do
      skip "Not yet implemented"
    end
  end
end
