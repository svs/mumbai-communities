class AddLocationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :street_address, :text
    add_column :users, :ward_code, :string
    add_column :users, :prabhag_id, :integer
    add_column :users, :latitude, :decimal, precision: 10, scale: 6
    add_column :users, :longitude, :decimal, precision: 10, scale: 6
    add_column :users, :location_confirmed_at, :datetime

    add_index :users, :ward_code
    add_index :users, :prabhag_id
  end
end
