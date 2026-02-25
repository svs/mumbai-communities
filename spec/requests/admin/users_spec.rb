require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin_user) { users(:admin_2) }
  let(:regular_user) { users(:svs_3) }

  describe "GET /admin/users" do
    context "authentication and authorization" do
      it "requires authentication" do
        get admin_users_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "requires admin privileges" do
        sign_in regular_user
        get admin_users_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
      end
    end

    context "as admin" do
      before { sign_in admin_user }

      it "returns success" do
        get admin_users_path
        expect(response).to have_http_status(:success)
      end

      it "lists all users" do
        get admin_users_path
        User.find_each do |user|
          expect(response.body).to include(user.email)
        end
      end

      it "shows user details" do
        get admin_users_path
        expect(response.body).to include(admin_user.name)
        expect(response.body).to include(admin_user.email)
      end

      it "indicates admin status" do
        get admin_users_path
        expect(response.body).to include("Admin")
      end
    end
  end
end
