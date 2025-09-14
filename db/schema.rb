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

ActiveRecord::Schema[8.0].define(version: 2025_09_14_135052) do
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
    t.index ["approved_by_id"], name: "index_boundaries_on_approved_by_id"
    t.index ["boundable_type", "boundable_id", "is_canonical"], name: "index_boundaries_on_boundable_and_canonical"
    t.index ["boundable_type", "boundable_id"], name: "index_boundaries_on_boundable_type_and_boundable_id"
    t.index ["status"], name: "index_boundaries_on_status"
    t.index ["submitted_by_id"], name: "index_boundaries_on_submitted_by_id"
    t.index ["year", "source_type"], name: "index_boundaries_on_year_and_source_type"
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["prabhag_id"], name: "index_users_on_prabhag_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["ward_code"], name: "index_users_on_ward_code"
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
    t.index ["ward_code"], name: "index_wards_on_ward_code", unique: true
  end

  add_foreign_key "boundaries", "users", column: "approved_by_id"
  add_foreign_key "boundaries", "users", column: "submitted_by_id"
  add_foreign_key "prabhags", "users", column: "assigned_to_id"
  add_foreign_key "tickets", "users", column: "assigned_to_id"
  add_foreign_key "tickets", "users", column: "created_by_id"
end
