class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.references :person, null: false, foreign_key: true
      t.references :roleable, polymorphic: true, null: false
      t.string :role_name
      t.datetime :started_at
      t.datetime :ended_at
      t.json :metadata

      t.timestamps
    end
  end
end
