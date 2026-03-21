class AddTenureDatesToPositions < ActiveRecord::Migration[8.0]
  def change
    add_column :positions, :started_on, :date
    add_column :positions, :ended_on, :date
    add_column :positions, :active, :boolean, default: true
  end
end
