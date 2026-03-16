require 'rails_helper'

RSpec.describe "Wards", type: :request do
  fixtures :users, :wards, :prabhags, :boundaries

  let(:user) { users(:user_one) }
  let(:ward) { wards(:ward_A) }

  describe "GET /wards" do
    it "gets index" do
      get wards_path
      expect(response).to have_http_status(:success)
    end

    it "allows anonymous access" do
      get wards_path
      expect(response).to have_http_status(:success)
    end

    it "displays the newspaper masthead" do
      get wards_path
      expect(response.body).to include("Mumbai Communities")
    end

    it "displays tweets from across all wards" do
      Tweet.create!(tweet_id: "idx_1", ward: ward, body: "Colaba road repair", author_username: "mybmcWardA", author_name: "BMC Ward A", tweeted_at: 1.hour.ago)
      get wards_path
      expect(response.body).to include("Colaba road repair")
    end

    it "shows ward attribution for each tweet" do
      Tweet.create!(tweet_id: "idx_2", ward: ward, body: "Test dispatch", author_username: "mybmcWardA", author_name: "BMC Ward A", tweeted_at: 1.hour.ago)
      get wards_path
      expect(response.body).to include("Ward A")
    end

    it "paginates tweets" do
      12.times do |i|
        Tweet.create!(tweet_id: "page_#{i}", ward: ward, body: "Tweet #{i}",
                      author_username: "mybmcWardA", author_name: "BMC Ward A",
                      tweeted_at: i.hours.ago)
      end
      get wards_path
      expect(response.body).to include("Tweet 0")
      expect(response.body).not_to include("Tweet 11")
    end

    it "shows tweets in reverse chronological order" do
      Tweet.create!(tweet_id: "idx_old", ward: ward, body: "Older dispatch", author_username: "mybmcWardA", author_name: "BMC Ward A", tweeted_at: 2.days.ago)
      Tweet.create!(tweet_id: "idx_new", ward: ward, body: "Newer dispatch", author_username: "mybmcWardA", author_name: "BMC Ward A", tweeted_at: 1.hour.ago)
      get wards_path
      newer_pos = response.body.index("Newer dispatch")
      older_pos = response.body.index("Older dispatch")
      expect(newer_pos).to be < older_pos
    end
  end

  describe "GET /wards/:id" do
    it "gets show" do
      get ward_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "gets show as JSON without errors" do
      get ward_path(ward), headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('features')
      expect(json_response['features']).to be_an(Array)
    end

    it "allows anonymous access" do
      get ward_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "shows news tab content by default" do
      get ward_path(ward)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("News")
      expect(response.body).to include("Officials")
      expect(response.body).to include("Facilities")
      expect(response.body).to include("Issues")
    end

    it "displays tweets inline on show page" do
      Tweet.create!(tweet_id: "req_test_show", ward: ward, body: "Road work near Colaba", author_username: "mybmcWardA", author_name: "BMC Ward A", tweeted_at: 1.hour.ago)
      get ward_path(ward)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Road work near Colaba")
    end
  end

  describe "GET /wards/:id/info" do
    it "redirects to officials" do
      get info_ward_path(ward)
      expect(response).to redirect_to(officials_ward_path(ward))
    end
  end

  describe "GET /wards/:id/officials" do
    it "returns success" do
      get officials_ward_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "displays ward officials in the directory" do
      ac = Person.create!(name: "Ramesh Pawar", phone: "022-22607000", email: "ac.a@mcgm.gov.in")
      ac.roles.create!(roleable: ward, role_name: "assistant_commissioner")

      corp = Person.create!(name: "Sujata Sanap", phone: "9870040562")
      corp.roles.create!(roleable: ward, role_name: "corporator")

      get officials_ward_path(ward)
      expect(response.body).to include("Ramesh Pawar")
      expect(response.body).to include("Sujata Sanap")
      expect(response.body).to include("Assistant Commissioner")
    end
  end

  describe "GET /wards/:id/facilities-overview" do
    it "returns success" do
      get facilities_tab_ward_path(ward)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /wards/:id/issues-overview" do
    it "returns success" do
      get issues_tab_ward_path(ward)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /wards/locate" do
    it "redirects to the ward containing the given point" do
      # Point inside G/S ward boundary (boundable_id: 21)
      get locate_wards_path(lat: 19.005, lng: 72.822)
      expect(response).to redirect_to(ward_path(wards(:"ward_G SOUTH")))
    end

    it "redirects back to wards index with alert when no ward found" do
      get locate_wards_path(lat: 28.6, lng: 77.2)
      expect(response).to redirect_to(wards_path)
      expect(flash[:alert]).to be_present
    end

    it "redirects back to wards index when params missing" do
      get locate_wards_path
      expect(response).to redirect_to(wards_path)
    end
  end

  describe "GET /wards/:id/news" do
    it "returns success" do
      get news_ward_path(ward)
      expect(response).to have_http_status(:success)
    end

    it "displays tweets" do
      Tweet.create!(tweet_id: "req_test_1", ward: ward, body: "Water pipeline repair in Colaba", author_username: "mybmcWardA", author_name: "BMC Ward A", tweeted_at: 1.hour.ago)
      get news_ward_path(ward)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Water pipeline repair in Colaba")
      expect(response.body).to include("From the Community")
    end
  end
end
