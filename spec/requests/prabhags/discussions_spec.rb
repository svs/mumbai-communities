require 'rails_helper'

RSpec.describe "Prabhags::Discussions", type: :request do
  let(:prabhag) { prabhags(:prabhag_A_225) }
  let(:user) { users(:user_one) }

  describe "GET /prabhags/:prabhag_id/discussions" do
    it "allows anonymous access" do
      get prabhag_discussions_path(prabhag)
      expect(response).to have_http_status(:success)
    end

    it "shows discussion list" do
      Discussion.create!(title: "Prabhag road issue", body: "body", user: user, discussable: prabhag)
      get prabhag_discussions_path(prabhag)
      expect(response.body).to include("Prabhag road issue")
    end
  end

  describe "POST /prabhags/:prabhag_id/discussions" do
    it "creates a discussion for a prabhag" do
      sign_in user
      expect {
        post prabhag_discussions_path(prabhag), params: { discussion: { title: "New prabhag topic", body: "Discussion body" } }
      }.to change(Discussion, :count).by(1)
      discussion = Discussion.last
      expect(discussion.discussable).to eq(prabhag)
    end
  end
end
