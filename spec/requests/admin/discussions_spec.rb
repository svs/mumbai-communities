require 'rails_helper'

RSpec.describe "Admin::Discussions", type: :request do
  let(:user) { users(:user_one) }
  let(:admin) { users(:admin_user) }
  let(:ward) { wards(:ward_A) }
  let!(:discussion) { Discussion.create!(title: "Test Discussion", body: "body", user: user, discussable: ward) }

  describe "access control" do
    it "redirects non-admin users" do
      sign_in user
      get admin_discussions_path
      expect(response).to redirect_to(root_path)
    end

    it "allows admin access" do
      sign_in admin
      get admin_discussions_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/discussions" do
    it "lists all discussions" do
      sign_in admin
      get admin_discussions_path
      expect(response.body).to include("Test Discussion")
    end

    it "filters by status" do
      sign_in admin
      Discussion.create!(title: "Closed one", body: "body", user: user, discussable: ward, status: "closed")
      get admin_discussions_path(status: "closed")
      expect(response.body).to include("Closed one")
      expect(response.body).not_to include("Test Discussion")
    end
  end

  describe "GET /admin/discussions/:id" do
    it "shows discussion details" do
      sign_in admin
      get admin_discussion_path(discussion)
      expect(response.body).to include("Test Discussion")
    end
  end

  describe "POST /admin/discussions/:id/close" do
    it "closes the discussion" do
      sign_in admin
      post close_admin_discussion_path(discussion)
      expect(discussion.reload.status).to eq("closed")
      expect(response).to redirect_to(admin_discussion_path(discussion))
    end
  end

  describe "POST /admin/discussions/:id/reopen" do
    it "reopens a closed discussion" do
      sign_in admin
      discussion.close!
      post reopen_admin_discussion_path(discussion)
      expect(discussion.reload.status).to eq("open")
    end
  end

  describe "POST /admin/discussions/:id/archive" do
    it "archives the discussion" do
      sign_in admin
      post archive_admin_discussion_path(discussion)
      expect(discussion.reload.status).to eq("archived")
      expect(response).to redirect_to(admin_discussions_path)
    end
  end

  describe "POST /admin/discussions/:id/pin" do
    it "pins the discussion" do
      sign_in admin
      post pin_admin_discussion_path(discussion)
      expect(discussion.reload.pinned).to be true
    end
  end

  describe "POST /admin/discussions/:id/unpin" do
    it "unpins the discussion" do
      sign_in admin
      discussion.pin!
      post unpin_admin_discussion_path(discussion)
      expect(discussion.reload.pinned).to be false
    end
  end
end
