require 'rails_helper'

RSpec.describe Discussion, type: :model do
  let(:user) { users(:user_one) }
  let(:ward) { wards(:ward_A) }

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }
    it { should validate_inclusion_of(:status).in_array(%w[open closed archived]) }
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:discussable).optional }
    it { should belong_to(:category).optional }
    it { should have_many(:posts).dependent(:destroy) }
  end

  describe "scopes" do
    let!(:open_discussion) { Discussion.create!(title: "Open", body: "body", user: user, discussable: ward, status: "open") }
    let!(:closed_discussion) { Discussion.create!(title: "Closed", body: "body", user: user, discussable: ward, status: "closed") }
    let!(:archived_discussion) { Discussion.create!(title: "Archived", body: "body", user: user, discussable: ward, status: "archived") }

    it ".open returns only open discussions" do
      expect(Discussion.open).to include(open_discussion)
      expect(Discussion.open).not_to include(closed_discussion, archived_discussion)
    end

    it ".not_archived excludes archived discussions" do
      expect(Discussion.not_archived).to include(open_discussion, closed_discussion)
      expect(Discussion.not_archived).not_to include(archived_discussion)
    end

    it ".search finds by title or body" do
      Discussion.create!(title: "Water issue", body: "Pipe broken", user: user, discussable: ward)
      expect(Discussion.search("Water")).to be_present
      expect(Discussion.search("Pipe")).to be_present
      expect(Discussion.search("nonexistent")).to be_empty
    end
  end

  describe "status transitions" do
    let(:discussion) { Discussion.create!(title: "Test", body: "body", user: user, discussable: ward) }

    it "#close! sets status to closed" do
      discussion.close!
      expect(discussion.reload).to be_closed
    end

    it "#reopen! sets status to open" do
      discussion.close!
      discussion.reopen!
      expect(discussion.reload).to be_open
    end

    it "#archive! sets status to archived" do
      discussion.archive!
      expect(discussion.reload).to be_archived
    end
  end

  describe "pinning" do
    let(:discussion) { Discussion.create!(title: "Test", body: "body", user: user, discussable: ward) }

    it "#pin! sets pinned to true" do
      discussion.pin!
      expect(discussion.reload.pinned).to be true
    end

    it "#unpin! sets pinned to false" do
      discussion.pin!
      discussion.unpin!
      expect(discussion.reload.pinned).to be false
    end
  end

  describe "polymorphic association" do
    it "can belong to a ward" do
      discussion = Discussion.create!(title: "Ward issue", body: "body", user: user, discussable: ward)
      expect(discussion.discussable).to eq(ward)
      expect(ward.discussions).to include(discussion)
    end
  end
end
