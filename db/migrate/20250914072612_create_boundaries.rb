class CreateBoundaries < ActiveRecord::Migration[8.0]
  def change
    create_table :boundaries do |t|
      t.string :boundable_type, null: false
      t.integer :boundable_id, null: false
      t.text :geojson, null: false
      t.string :source_type, null: false
      t.integer :year
      t.string :status, default: 'pending'
      t.boolean :is_canonical, default: false
      t.references :submitted_by, foreign_key: { to_table: :users }, null: true
      t.references :approved_by, foreign_key: { to_table: :users }, null: true
      t.json :metadata
      t.datetime :approved_at
      t.text :rejection_reason
      t.timestamps

      t.index [:boundable_type, :boundable_id]
      t.index [:boundable_type, :boundable_id, :is_canonical],
              name: 'index_boundaries_on_boundable_and_canonical'
      t.index [:year, :source_type]
      t.index :status
    end
  end
end
