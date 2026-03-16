class CreateMunicipalities < ActiveRecord::Migration[8.0]
  def change
    create_table :municipalities do |t|
      t.string :name, null: false
      t.string :short_name
      t.string :state

      t.timestamps
    end

    add_reference :wards, :municipality, foreign_key: true
  end
end
