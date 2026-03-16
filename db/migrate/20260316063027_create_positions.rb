class CreatePositions < ActiveRecord::Migration[8.0]
  def change
    create_table :positions do |t|
      t.string :designation
      t.string :email
      t.string :phone
      t.string :person_name
      t.string :level
      t.references :department, null: false, foreign_key: true
      t.json :metadata

      t.timestamps
    end
  end
end
