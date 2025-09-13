class CreatePrabhags < ActiveRecord::Migration[8.0]
  def change
    create_table :prabhags do |t|
      t.integer :number
      t.string :name
      t.string :ward_code  # MCGM ward like 'A', 'K NORTH', etc.
      t.string :pdf_url
      t.text :boundary_geojson
      t.string :status
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
    
    add_index :prabhags, [:number, :ward_code], unique: true
  end
end
