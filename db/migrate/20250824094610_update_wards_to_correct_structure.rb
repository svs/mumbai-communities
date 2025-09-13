class UpdateWardsToCorrectStructure < ActiveRecord::Migration[8.0]
  def change
    # Drop the existing incorrect wards table
    drop_table :wards if table_exists?(:wards)
    
    # Create new wards table with correct structure
    create_table :wards do |t|
      t.string :ward_code, null: false
      t.string :name, null: false
      t.text :boundary_geojson
      t.boolean :is_geocoded, default: false
      t.decimal :total_area, precision: 10, scale: 6
      t.integer :population_estimate
      t.string :contact_officer_name
      t.string :contact_officer_email
      t.string :contact_officer_phone
      
      t.timestamps
    end
    
    add_index :wards, :ward_code, unique: true
  end
end
