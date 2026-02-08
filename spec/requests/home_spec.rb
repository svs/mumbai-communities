require 'rails_helper'

RSpec.describe "Home", type: :request do
  fixtures :users, :wards, :prabhags, :boundaries

  let(:user) { users(:admin_2) }
  let(:ward) { wards(:ward_A) }
  let(:prabhag) { prabhags(:prabhag_A_225) }

  describe "GET /" do
    context "for anonymous users" do
      it "shows the index page" do
        get root_path
        expect(response).to have_http_status(:success)

        expect(response.body).to match(/\d+ Active Ward Communities/)
        expect(response.body).to match(/\d+ Issues Resolved/)

        expect(response.body).not_to match(/Welcome back/)
      end

      it "loads statistics correctly" do
        get root_path
        expect(response).to have_http_status(:success)

        expect(response.body).to match(/\d+/)
      end

      it "loads recent activity feed" do
        get root_path
        expect(response).to have_http_status(:success)

        expect(response.body).to include('bg-white')
      end

      it "loads featured wards" do
        get root_path
        expect(response).to have_http_status(:success)

        expect(response.body).to include("data-controller='leaflet-map'")
      end

      it "renders interactive ward map" do
        get root_path
        expect(response).to have_http_status(:success)

        expect(response.body).to include("data-controller='leaflet-map'")
        expect(response.body).to include("data-leaflet-map-data-url-value='/wards.json'")
        expect(response.body).to include("data-leaflet-map-static-value='true'")
      end

      it "shows authentication options" do
        get root_path
        expect(response).to have_http_status(:success)

        expect(response.body).to include(user_google_oauth2_omniauth_authorize_path)
        expect(response.body).to include(new_user_session_path)
        expect(response.body).to include(new_user_registration_path)
      end
    end

    context "for authenticated users with location" do
      it "redirects to their prabhag" do
        sign_in user
        get root_path

        expect(response).to have_http_status(:redirect)
      end

      it "does not show auth section" do
        sign_in user
        get root_path

        expect(response.body).not_to include("Ready to Make a Difference?")
        expect(response.body).not_to include("Sign in with Google")
      end
    end

    context "for authenticated users with assignments" do
      it "handles user with assignments" do
        sign_in user
        get root_path

        expect(response).to have_http_status(:redirect)
      end

      it "handles user without assignments gracefully" do
        sign_in user
        get root_path

        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
