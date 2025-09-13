class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.string :title
      t.text :description
      t.string :ticket_type
      t.string :ward_code
      t.integer :prabhag_number
      t.string :status
      t.string :priority
      t.datetime :due_date
      t.decimal :estimated_hours
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.decimal :location_latitude
      t.decimal :location_longitude
      t.text :location_address

      t.timestamps
    end
  end
end
