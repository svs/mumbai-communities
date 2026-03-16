class CreateOrganisations < ActiveRecord::Migration[8.0]
  def change
    create_table :organisations do |t|
      t.string :name
      t.string :org_type
      t.string :website
      t.string :jurisdiction
      t.references :organisable, polymorphic: true, null: true
      t.references :parent, null: true, foreign_key: { to_table: :organisations }

      t.timestamps
    end
  end
end
