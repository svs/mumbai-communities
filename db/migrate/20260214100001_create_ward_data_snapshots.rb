class CreateWardDataSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :ward_data_snapshots do |t|
      t.string :ward_code
      t.string :source_url, null: false
      t.string :data_type, null: false
      t.text :content
      t.string :content_hash
      t.json :parsed_data

      t.timestamps
    end

    add_index :ward_data_snapshots, [:ward_code, :data_type]
    add_index :ward_data_snapshots, :content_hash
  end
end
