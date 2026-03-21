# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_21_230418) do
  create_table "attachments", force: :cascade do |t|
    t.string "attachable_type", null: false
    t.integer "attachable_id", null: false
    t.string "name", null: false
    t.string "url"
    t.string "attachment_type", default: "link"
    t.string "mime_type"
    t.integer "position", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attachable_type", "attachable_id", "position"], name: "idx_on_attachable_type_attachable_id_position_f0678034d9"
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable"
  end

  create_table "boundaries", force: :cascade do |t|
    t.string "boundable_type", null: false
    t.integer "boundable_id", null: false
    t.text "geojson", null: false
    t.string "source_type", null: false
    t.integer "year"
    t.string "status", default: "pending"
    t.boolean "is_canonical", default: false
    t.integer "submitted_by_id"
    t.integer "approved_by_id"
    t.json "metadata"
    t.datetime "approved_at"
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "edited_by_id"
    t.index ["approved_by_id"], name: "index_boundaries_on_approved_by_id"
    t.index ["boundable_type", "boundable_id", "is_canonical"], name: "index_boundaries_on_boundable_and_canonical"
    t.index ["boundable_type", "boundable_id"], name: "index_boundaries_on_boundable_type_and_boundable_id"
    t.index ["edited_by_id"], name: "index_boundaries_on_edited_by_id"
    t.index ["status"], name: "index_boundaries_on_status"
    t.index ["submitted_by_id"], name: "index_boundaries_on_submitted_by_id"
    t.index ["year", "source_type"], name: "index_boundaries_on_year_and_source_type"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "position", default: 0
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "organisation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id"], name: "index_departments_on_organisation_id"
  end

  create_table "discussions", force: :cascade do |t|
    t.string "title", null: false
    t.text "body", null: false
    t.string "discussable_type"
    t.integer "discussable_id"
    t.integer "user_id"
    t.integer "category_id"
    t.string "status", default: "open"
    t.boolean "pinned", default: false
    t.integer "posts_count", default: 0
    t.datetime "last_post_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_discussions_on_category_id"
    t.index ["discussable_type", "discussable_id"], name: "index_discussions_on_discussable_type_and_discussable_id"
    t.index ["pinned", "last_post_at"], name: "index_discussions_on_pinned_and_last_post_at"
    t.index ["status"], name: "index_discussions_on_status"
    t.index ["user_id"], name: "index_discussions_on_user_id"
  end

  create_table "facilities", force: :cascade do |t|
    t.string "name"
    t.string "facility_type", null: false
    t.string "source", null: false
    t.string "external_id"
    t.string "ward_code"
    t.integer "prabhag_number"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "address"
    t.json "raw_data"
    t.string "content_hash"
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_type"], name: "index_facilities_on_facility_type"
    t.index ["source", "external_id"], name: "index_facilities_on_source_and_external_id", unique: true
    t.index ["ward_code", "facility_type"], name: "index_facilities_on_ward_code_and_facility_type"
  end

  create_table "issues", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.string "ward_code", null: false
    t.integer "category_id"
    t.integer "created_by_id", null: false
    t.integer "tweet_id"
    t.string "status", default: "open"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_issues_on_category_id"
    t.index ["created_by_id"], name: "index_issues_on_created_by_id"
    t.index ["status"], name: "index_issues_on_status"
    t.index ["tweet_id"], name: "index_issues_on_tweet_id"
    t.index ["ward_code"], name: "index_issues_on_ward_code"
  end

  create_table "municipalities", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organisations", force: :cascade do |t|
    t.string "name"
    t.string "org_type"
    t.string "website"
    t.string "jurisdiction"
    t.string "organisable_type"
    t.integer "organisable_id"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisable_type", "organisable_id"], name: "index_organisations_on_organisable"
    t.index ["parent_id"], name: "index_organisations_on_parent_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.text "notes"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "bio"
    t.string "linkedin_url"
    t.string "twitter_handle"
    t.json "profile_data"
    t.string "avatar_url"
  end

  create_table "positions", force: :cascade do |t|
    t.string "designation"
    t.string "email"
    t.string "phone"
    t.string "person_name"
    t.string "level"
    t.integer "department_id"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "elected", default: false
    t.string "political_party"
    t.json "profile_data"
    t.text "bio"
    t.string "linkedin_url"
    t.string "twitter_handle"
    t.date "started_on"
    t.date "ended_on"
    t.boolean "active", default: true
    t.integer "organisation_id"
    t.string "section"
    t.integer "person_id"
    t.index ["department_id"], name: "index_positions_on_department_id"
  end

  create_table "posts", force: :cascade do |t|
    t.integer "discussion_id", null: false
    t.integer "user_id", null: false
    t.integer "parent_id"
    t.text "body", null: false
    t.integer "depth", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discussion_id", "created_at"], name: "index_posts_on_discussion_id_and_created_at"
    t.index ["discussion_id"], name: "index_posts_on_discussion_id"
    t.index ["parent_id"], name: "index_posts_on_parent_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "prabhags", force: :cascade do |t|
    t.integer "number"
    t.string "name"
    t.string "ward_code"
    t.string "pdf_url"
    t.text "boundary_geojson"
    t.string "status"
    t.integer "assigned_to_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_prabhags_on_assigned_to_id"
    t.index ["number", "ward_code"], name: "index_prabhags_on_number_and_ward_code", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.integer "person_id", null: false
    t.string "roleable_type", null: false
    t.integer "roleable_id", null: false
    t.string "role_name"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_roles_on_person_id"
    t.index ["roleable_type", "roleable_id"], name: "index_roles_on_roleable"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "ticket_type"
    t.string "ward_code"
    t.integer "prabhag_number"
    t.string "status"
    t.string "priority"
    t.datetime "due_date"
    t.decimal "estimated_hours"
    t.integer "assigned_to_id"
    t.integer "created_by_id", null: false
    t.decimal "location_latitude"
    t.decimal "location_longitude"
    t.text "location_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_tickets_on_assigned_to_id"
    t.index ["created_by_id"], name: "index_tickets_on_created_by_id"
  end

  create_table "todo_items", force: :cascade do |t|
    t.integer "issue_id", null: false
    t.string "title", null: false
    t.boolean "completed", default: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id", "position"], name: "index_todo_items_on_issue_id_and_position"
  end

  create_table "tweets", force: :cascade do |t|
    t.string "tweet_id", null: false
    t.integer "ward_id", null: false
    t.text "body", null: false
    t.string "author_username"
    t.string "author_name"
    t.datetime "tweeted_at"
    t.integer "like_count", default: 0
    t.integer "retweet_count", default: 0
    t.integer "reply_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "in_reply_to_status_id"
    t.json "media_urls"
    t.string "conversation_id"
    t.string "category"
    t.string "tweet_type"
    t.index ["tweet_id"], name: "index_tweets_on_tweet_id", unique: true
    t.index ["ward_id", "tweeted_at"], name: "index_tweets_on_ward_id_and_tweeted_at"
    t.index ["ward_id"], name: "index_tweets_on_ward_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "street_address"
    t.string "ward_code"
    t.integer "prabhag_id"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "location_confirmed_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["prabhag_id"], name: "index_users_on_prabhag_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["ward_code"], name: "index_users_on_ward_code"
  end

  create_table "ward_data_snapshots", force: :cascade do |t|
    t.string "ward_code"
    t.string "source_url", null: false
    t.string "data_type", null: false
    t.text "content"
    t.string "content_hash"
    t.json "parsed_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_hash"], name: "index_ward_data_snapshots_on_content_hash"
    t.index ["ward_code", "data_type"], name: "index_ward_data_snapshots_on_ward_code_and_data_type"
  end

  create_table "wards", force: :cascade do |t|
    t.string "ward_code", null: false
    t.string "name", null: false
    t.text "boundary_geojson"
    t.boolean "is_geocoded", default: false
    t.decimal "total_area", precision: 10, scale: 6
    t.integer "population_estimate"
    t.string "contact_officer_name"
    t.string "contact_officer_email"
    t.string "contact_officer_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short_name"
    t.string "twitter_handle"
    t.integer "municipality_id"
    t.index ["municipality_id"], name: "index_wards_on_municipality_id"
    t.index ["ward_code"], name: "index_wards_on_ward_code", unique: true
  end

  add_foreign_key "boundaries", "users", column: "approved_by_id"
  add_foreign_key "boundaries", "users", column: "edited_by_id"
  add_foreign_key "boundaries", "users", column: "submitted_by_id"
  add_foreign_key "departments", "organisations"
  add_foreign_key "discussions", "categories"
  add_foreign_key "discussions", "users"
  add_foreign_key "issues", "categories"
  add_foreign_key "issues", "tweets"
  add_foreign_key "issues", "users", column: "created_by_id"
  add_foreign_key "organisations", "organisations", column: "parent_id"
  add_foreign_key "positions", "departments"
  add_foreign_key "posts", "discussions"
  add_foreign_key "posts", "posts", column: "parent_id"
  add_foreign_key "posts", "users"
  add_foreign_key "prabhags", "users", column: "assigned_to_id"
  add_foreign_key "roles", "people"
  add_foreign_key "tickets", "users", column: "assigned_to_id"
  add_foreign_key "tickets", "users", column: "created_by_id"
  add_foreign_key "todo_items", "issues"
  add_foreign_key "tweets", "wards"
  add_foreign_key "wards", "municipalities"
end
