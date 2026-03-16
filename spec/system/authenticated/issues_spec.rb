require 'rails_helper'

RSpec.describe "Issues", type: :system do
  fixtures :users, :wards, :categories

  let(:user) { users(:user_one) }
  let(:ward) { wards(:ward_A) }
  let(:category) { categories(:infrastructure) }

  before do
    login_as(user, scope: :user)
  end

  describe "creating an issue" do
    it "user creates an issue from the ward page" do
      visit ward_path(ward)

      click_link "New Issue"

      fill_in "Title", with: "Broken footpath near station"
      fill_in "Description", with: "The footpath on MG Road has been broken for weeks and is dangerous for pedestrians."
      select "Infrastructure", from: "Category"

      click_button "Create Issue"

      expect(page).to have_text("Broken footpath near station")
      expect(page).to have_text("The footpath on MG Road has been broken for weeks")
      expect(page).to have_text("Infrastructure")
      expect(page).to have_text("open")
    end

    it "user creates an issue from a tweet" do
      tweet = Tweet.create!(
        tweet_id: "123456",
        ward: ward,
        body: "Massive pothole on SV Road causing accidents daily @mybmcWardA",
        author_username: "citizen123",
        author_name: "Concerned Citizen",
        tweeted_at: 1.hour.ago,
        category: "roads_and_footpaths"
      )

      visit ward_tweet_path(ward, tweet)

      click_link "Create Issue"

      # Title should be AI-generated (or fallback cleaned text), not raw tweet
      expect(page).to have_field("Title")
      title_value = find_field("Title").value
      expect(title_value).not_to include("@mybmcWardA")

      click_button "Create Issue"

      expect(page).to have_text("Massive pothole on SV Road causing accidents daily")
    end
  end

  describe "viewing an issue" do
    it "shows issue details with discussion and todo list" do
      issue = Issue.create!(
        title: "Water logging on Hill Road",
        description: "Every monsoon the road floods. We need better drainage.",
        ward: ward,
        created_by: user,
        category: category,
        status: "open"
      )

      visit ward_issue_path(ward, issue)

      expect(page).to have_text("Water logging on Hill Road")
      expect(page).to have_text("Every monsoon the road floods")
      expect(page).to have_text("Infrastructure")
      expect(page).to have_text("open")
      expect(page).to have_text(user.name)

      # Discussion section
      expect(page).to have_text("Discussion")

      # Todo list section
      expect(page).to have_text("Todo")
    end
  end

  describe "adding todo items" do
    it "user adds a todo item to an issue" do
      issue = Issue.create!(
        title: "Fix broken streetlight",
        description: "Streetlight on Link Road has been out for a month.",
        ward: ward,
        created_by: user,
        category: category,
        status: "open"
      )

      visit ward_issue_path(ward, issue)

      fill_in "todo_item_title", with: "File complaint with BEST"
      click_button "Add Todo"

      expect(page).to have_text("File complaint with BEST")
    end

    it "user completes a todo item" do
      issue = Issue.create!(
        title: "Fix broken streetlight",
        description: "Streetlight on Link Road has been out for a month.",
        ward: ward,
        created_by: user,
        category: category,
        status: "open"
      )
      todo = issue.todo_items.create!(title: "File complaint with BEST", position: 1)

      visit ward_issue_path(ward, issue)

      expect(page).to have_text("File complaint with BEST")

      check "todo_item_#{todo.id}"

      expect(page).to have_checked_field("todo_item_#{todo.id}")
    end
  end

  describe "posting in issue discussion" do
    it "user adds a comment to an issue" do
      issue = Issue.create!(
        title: "Garbage not collected",
        description: "No garbage collection in Sector 5 for 3 days.",
        ward: ward,
        created_by: user,
        category: category,
        status: "open"
      )

      visit ward_issue_path(ward, issue)

      fill_in "post_body", with: "I've been facing the same problem. It's been 4 days now."
      click_button "Post"

      expect(page).to have_text("I've been facing the same problem")
    end
  end

  describe "listing issues" do
    it "shows ward issues on the ward issues index" do
      Issue.create!(
        title: "Pothole on MG Road",
        description: "Large pothole causing accidents.",
        ward: ward,
        created_by: user,
        category: category,
        status: "open"
      )
      Issue.create!(
        title: "Broken water pipe",
        description: "Water pipe leaking on SV Road.",
        ward: ward,
        created_by: user,
        category: categories(:sanitation),
        status: "open"
      )

      visit ward_issues_path(ward)

      expect(page).to have_text("Pothole on MG Road")
      expect(page).to have_text("Broken water pipe")
      expect(page).to have_text("Infrastructure")
      expect(page).to have_text("Sanitation")
    end
  end

  describe "issue status management" do
    it "issue creator can close an issue" do
      issue = Issue.create!(
        title: "Resolved pothole",
        description: "The pothole has been fixed.",
        ward: ward,
        created_by: user,
        category: category,
        status: "open"
      )

      visit ward_issue_path(ward, issue)

      click_button "Close Issue"

      expect(page).to have_text("closed")
    end
  end
end
