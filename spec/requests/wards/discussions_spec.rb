require 'rails_helper'

RSpec.describe "Wards::Discussions", type: :request do
  let(:ward) { wards(:ward_A) }
  let(:user) { users(:user_one) }
  let(:admin) { users(:admin_user) }
  let(:other_user) { users(:user_two) }

  describe "GET /wards/:ward_id/discussions" do
    it "allows anonymous access" do
      get ward_discussions_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "shows discussion list" do
      Discussion.create!(title: "Road repair needed", body: "The main road has potholes", user: user, discussable: ward)
      get ward_discussions_path(ward)
      expect(response.body).to include("Road repair needed")
    end

    it "does not show archived discussions" do
      Discussion.create!(title: "Active discussion", body: "body", user: user, discussable: ward, status: "open")
      Discussion.create!(title: "Archived discussion", body: "body", user: user, discussable: ward, status: "archived")
      get ward_discussions_path(ward)
      expect(response.body).to include("Active discussion")
      expect(response.body).not_to include("Archived discussion")
    end

    it "searches discussions" do
      Discussion.create!(title: "Water supply issue", body: "body", user: user, discussable: ward)
      Discussion.create!(title: "Road problem", body: "body", user: user, discussable: ward)
      get ward_discussions_path(ward, q: "Water")
      expect(response.body).to include("Water supply issue")
      expect(response.body).not_to include("Road problem")
    end

    it "filters by category" do
      cat = categories(:infrastructure)
      Discussion.create!(title: "Road work", body: "body", user: user, discussable: ward, category: cat)
      Discussion.create!(title: "General chat", body: "body", user: user, discussable: ward)
      get ward_discussions_path(ward, category: "infrastructure")
      expect(response.body).to include("Road work")
      expect(response.body).not_to include("General chat")
    end
  end

  describe "GET /wards/:ward_id/discussions/:id" do
    let(:discussion) { Discussion.create!(title: "Test Discussion", body: "Some details", user: user, discussable: ward) }

    it "allows anonymous access" do
      get ward_discussion_path(ward, discussion)
      expect(response).to have_http_status(:success)
    end

    it "shows discussion details" do
      get ward_discussion_path(ward, discussion)
      expect(response.body).to include("Test Discussion")
      expect(response.body).to include("Some details")
    end

    it "shows replies" do
      discussion.posts.create!(body: "I agree completely", user: other_user)
      get ward_discussion_path(ward, discussion)
      expect(response.body).to include("I agree completely")
    end
  end

  describe "POST /wards/:ward_id/discussions" do
    it "requires authentication" do
      post ward_discussions_path(ward), params: { discussion: { title: "Test", body: "Body" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "creates a discussion" do
      sign_in user
      expect {
        post ward_discussions_path(ward), params: { discussion: { title: "New topic", body: "Discussion body" } }
      }.to change(Discussion, :count).by(1)
      expect(response).to redirect_to(ward_discussion_path(ward, Discussion.last))
    end

    it "rejects invalid discussions" do
      sign_in user
      post ward_discussions_path(ward), params: { discussion: { title: "", body: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /wards/:ward_id/discussions/:id" do
    let(:discussion) { Discussion.create!(title: "Original", body: "body", user: user, discussable: ward) }

    it "allows the author to update" do
      sign_in user
      patch ward_discussion_path(ward, discussion), params: { discussion: { title: "Updated title" } }
      expect(discussion.reload.title).to eq("Updated title")
    end

    it "allows admin to update" do
      sign_in admin
      patch ward_discussion_path(ward, discussion), params: { discussion: { title: "Admin edit" } }
      expect(discussion.reload.title).to eq("Admin edit")
    end

    it "prevents other users from updating" do
      sign_in other_user
      patch ward_discussion_path(ward, discussion), params: { discussion: { title: "Hacked" } }
      expect(discussion.reload.title).to eq("Original")
    end
  end

  describe "DELETE /wards/:ward_id/discussions/:id" do
    let!(:discussion) { Discussion.create!(title: "To delete", body: "body", user: user, discussable: ward) }

    it "allows the author to delete" do
      sign_in user
      expect {
        delete ward_discussion_path(ward, discussion)
      }.to change(Discussion, :count).by(-1)
    end

    it "prevents other users from deleting" do
      sign_in other_user
      expect {
        delete ward_discussion_path(ward, discussion)
      }.not_to change(Discussion, :count)
    end
  end
end
