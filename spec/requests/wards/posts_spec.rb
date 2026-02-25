require 'rails_helper'

RSpec.describe "Wards::Posts", type: :request do
  let(:ward) { wards(:ward_A) }
  let(:user) { users(:user_one) }
  let(:other_user) { users(:user_two) }
  let(:discussion) { Discussion.create!(title: "Test", body: "body", user: user, discussable: ward) }

  describe "POST /wards/:ward_id/discussions/:discussion_id/posts" do
    it "requires authentication" do
      post ward_discussion_posts_path(ward, discussion), params: { post: { body: "Reply" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "creates a reply" do
      sign_in user
      expect {
        post ward_discussion_posts_path(ward, discussion), params: { post: { body: "Great point!" } }
      }.to change(Post, :count).by(1)
      expect(response).to redirect_to(ward_discussion_path(ward, discussion, anchor: "post-#{Post.last.id}"))
    end

    it "creates a nested reply" do
      sign_in user
      root_post = discussion.posts.create!(body: "Root", user: user)
      post ward_discussion_posts_path(ward, discussion), params: { post: { body: "Nested reply", parent_id: root_post.id } }
      new_post = Post.last
      expect(new_post.parent).to eq(root_post)
      expect(new_post.depth).to eq(1)
    end

    it "rejects blank replies" do
      sign_in user
      post ward_discussion_posts_path(ward, discussion), params: { post: { body: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /wards/:ward_id/discussions/:discussion_id/posts/:id" do
    let(:reply) { discussion.posts.create!(body: "Original reply", user: user) }

    it "allows the author to update" do
      sign_in user
      patch ward_discussion_post_path(ward, discussion, reply), params: { post: { body: "Updated reply" } }
      expect(reply.reload.body).to eq("Updated reply")
    end

    it "prevents other users from updating" do
      sign_in other_user
      patch ward_discussion_post_path(ward, discussion, reply), params: { post: { body: "Hacked" } }
      expect(reply.reload.body).to eq("Original reply")
    end
  end

  describe "DELETE /wards/:ward_id/discussions/:discussion_id/posts/:id" do
    let!(:reply) { discussion.posts.create!(body: "To delete", user: user) }

    it "allows the author to delete" do
      sign_in user
      expect {
        delete ward_discussion_post_path(ward, discussion, reply)
      }.to change(Post, :count).by(-1)
    end

    it "prevents other users from deleting" do
      sign_in other_user
      expect {
        delete ward_discussion_post_path(ward, discussion, reply)
      }.not_to change(Post, :count)
    end
  end
end
