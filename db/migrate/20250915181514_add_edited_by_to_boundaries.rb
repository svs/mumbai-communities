class AddEditedByToBoundaries < ActiveRecord::Migration[8.0]
  def change
    add_reference :boundaries, :edited_by, null: true, foreign_key: { to_table: :users }
  end
end
