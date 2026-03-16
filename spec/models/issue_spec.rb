require 'rails_helper'

RSpec.describe Issue, type: :model do
  fixtures :users, :wards, :categories

  let(:user) { users(:user_one) }
  let(:ward) { wards(:ward_A) }
  let(:category) { categories(:infrastructure) }

  def build_issue(attrs = {})
    Issue.new({
      title: "Test Issue",
      description: "Test description",
      ward: ward,
      created_by: user,
      category: category,
      status: "open"
    }.merge(attrs))
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build_issue).to be_valid
    end

    it "requires a title" do
      expect(build_issue(title: nil)).not_to be_valid
    end

    it "requires a description" do
      expect(build_issue(description: nil)).not_to be_valid
    end

    it "validates status inclusion" do
      expect(build_issue(status: "invalid")).not_to be_valid
      %w[open in_progress resolved closed].each do |status|
        expect(build_issue(status: status)).to be_valid
      end
    end
  end

  describe "associations" do
    it "belongs to a ward" do
      issue = build_issue
      expect(issue.ward).to eq(ward)
    end

    it "belongs to a user (created_by)" do
      issue = build_issue
      expect(issue.created_by).to eq(user)
    end

    it "optionally belongs to a category" do
      expect(build_issue(category: nil)).to be_valid
    end

    it "optionally belongs to a tweet" do
      tweet = Tweet.create!(tweet_id: "999", ward: ward, body: "Test tweet", tweeted_at: Time.current)
      issue = build_issue(tweet: tweet)
      issue.save!
      expect(issue.tweet).to eq(tweet)
    end

    it "has many todo_items" do
      issue = build_issue
      issue.save!
      issue.todo_items.create!(title: "First todo", position: 1)
      issue.todo_items.create!(title: "Second todo", position: 2)
      expect(issue.todo_items.count).to eq(2)
    end

    it "includes Discussable" do
      issue = build_issue
      issue.save!
      expect(issue).to respond_to(:discussions)
    end
  end

  describe ".from_tweet" do
    it "builds an issue from a tweet with cleaned title and category" do
      tweet = Tweet.create!(
        tweet_id: "456",
        ward: ward,
        body: "@mybmc @mybmcWardA Pothole on SV Road near station",
        author_username: "citizen",
        tweeted_at: Time.current,
        category: "roads_and_footpaths"
      )
      # Create matching category in DB
      Category.find_or_create_by!(slug: "roads_and_footpaths") do |c|
        c.name = "Roads & Footpaths"
      end

      issue = Issue.from_tweet(tweet)

      expect(issue).to be_a(Issue)
      expect(issue.tweet).to eq(tweet)
      expect(issue.ward_code).to eq(ward.ward_code)
      expect(issue.title).to be_present
      expect(issue.title).not_to include("@mybmc")
      expect(issue.description).to be_present
      expect(issue.category&.slug).to eq("roads_and_footpaths")
    end
  end

  describe "status methods" do
    it "#open? returns true when status is open" do
      expect(build_issue(status: "open")).to be_open
    end

    it "#closed? returns true when status is closed" do
      expect(build_issue(status: "closed")).to be_closed
    end

    it "#close! transitions to closed" do
      issue = build_issue
      issue.save!
      issue.close!
      expect(issue).to be_closed
    end

    it "#reopen! transitions to open" do
      issue = build_issue(status: "closed")
      issue.save!
      issue.reopen!
      expect(issue).to be_open
    end
  end

  describe "scopes" do
    before do
      build_issue(title: "Open issue", status: "open").save!
      build_issue(title: "Closed issue", status: "closed").save!
    end

    it ".open returns only open issues" do
      expect(Issue.open.pluck(:title)).to eq(["Open issue"])
    end

    it ".closed returns only closed issues" do
      expect(Issue.closed.pluck(:title)).to eq(["Closed issue"])
    end

    it ".recent orders by created_at desc" do
      expect(Issue.recent.first.title).to eq("Closed issue")
    end
  end

  describe "destroying" do
    it "destroys associated todo_items" do
      issue = build_issue
      issue.save!
      issue.todo_items.create!(title: "A todo", position: 1)
      expect { issue.destroy }.to change(TodoItem, :count).by(-1)
    end
  end
end
