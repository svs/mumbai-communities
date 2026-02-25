class CreatePeople < ActiveRecord::Migration[8.0]
  def change
    create_table :people do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.text :notes
      t.json :metadata

      t.timestamps
    end
  end
end
