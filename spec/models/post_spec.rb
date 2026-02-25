require 'rails_helper'

RSpec.describe Post, type: :model do
  let(:user) { users(:user_one) }
  let(:ward) { wards(:ward_A) }
  let(:discussion) { Discussion.create!(title: "Test", body: "body", user: user, discussable: ward) }

  describe "validations" do
    it { should validate_presence_of(:body) }
  end

  describe "associations" do
    it { should belong_to(:discussion) }
    it { should belong_to(:user) }
    it { should belong_to(:parent).optional }
    it { should have_many(:replies).dependent(:destroy) }
  end

  describe "threading" do
    it "sets depth to 0 for root posts" do
      post = discussion.posts.create!(body: "Root reply", user: user)
      expect(post.depth).to eq(0)
    end

    it "sets depth based on parent" do
      root = discussion.posts.create!(body: "Root", user: user)
      child = discussion.posts.create!(body: "Child", user: user, parent: root)
      grandchild = discussion.posts.create!(body: "Grandchild", user: user, parent: child)

      expect(child.depth).to eq(1)
      expect(grandchild.depth).to eq(2)
    end

    it "scopes roots to top-level posts only" do
      root = discussion.posts.create!(body: "Root", user: user)
      discussion.posts.create!(body: "Child", user: user, parent: root)

      expect(discussion.posts.roots).to eq([root])
    end
  end

  describe "counter cache" do
    it "increments discussion posts_count" do
      expect {
        discussion.posts.create!(body: "Reply", user: user)
      }.to change { discussion.reload.posts_count }.from(0).to(1)
    end
  end

  describe "touch_discussion" do
    it "updates discussion last_post_at on create" do
      expect(discussion.last_post_at).to be_nil
      discussion.posts.create!(body: "Reply", user: user)
      expect(discussion.reload.last_post_at).to be_present
    end
  end
end
