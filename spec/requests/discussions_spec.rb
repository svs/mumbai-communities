require 'rails_helper'

RSpec.describe "Discussions", type: :request do
  let(:ward) { wards(:ward_A) }
  let(:user) { users(:user_one) }

  describe "GET /discussions" do
    it "allows anonymous access" do
      get discussions_path
      expect(response).to have_http_status(:success)
    end

    it "shows discussions from all wards" do
      ward_b = wards(:ward_B)
      Discussion.create!(title: "Ward A topic", body: "body", user: user, discussable: ward)
      Discussion.create!(title: "Ward B topic", body: "body", user: user, discussable: ward_b)
      get discussions_path
      expect(response.body).to include("Ward A topic")
      expect(response.body).to include("Ward B topic")
    end

    it "shows the ward name for each discussion" do
      Discussion.create!(title: "Road issue", body: "body", user: user, discussable: ward)
      get discussions_path
      expect(response.body).to include("Ward A")
    end

    it "searches across all discussions" do
      Discussion.create!(title: "Water supply problem", body: "body", user: user, discussable: ward)
      Discussion.create!(title: "Road repair", body: "body", user: user, discussable: ward)
      get discussions_path(q: "Water")
      expect(response.body).to include("Water supply problem")
      expect(response.body).not_to include("Road repair")
    end
  end

  describe "GET /discussions/:id" do
    let(:discussion) { Discussion.create!(title: "Test Discussion", body: "Details here", user: user, discussable: ward) }

    it "allows anonymous access" do
      get discussion_path(discussion)
      expect(response).to have_http_status(:success)
    end

    it "shows discussion details and replies" do
      discussion.posts.create!(body: "A reply", user: user)
      get discussion_path(discussion)
      expect(response.body).to include("Test Discussion")
      expect(response.body).to include("A reply")
    end

    it "links back to the ward-scoped discussion for replying" do
      get discussion_path(discussion)
      expect(response.body).to include(ward_discussion_path(ward, discussion))
    end
  end
end
