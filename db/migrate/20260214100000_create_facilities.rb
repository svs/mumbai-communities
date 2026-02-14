class CreateFacilities < ActiveRecord::Migration[8.0]
  def change
    create_table :facilities do |t|
      t.string :name
      t.string :facility_type, null: false
      t.string :source, null: false
      t.string :external_id
      t.string :ward_code
      t.integer :prabhag_number
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :address
      t.json :raw_data
      t.string :content_hash
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :facilities, [:source, :external_id], unique: true
    add_index :facilities, [:ward_code, :facility_type]
    add_index :facilities, :facility_type
  end
end
