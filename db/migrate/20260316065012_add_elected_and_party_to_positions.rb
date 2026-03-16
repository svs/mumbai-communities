class AddElectedAndPartyToPositions < ActiveRecord::Migration[8.0]
  def change
    add_column :positions, :elected, :boolean, default: false
    add_column :positions, :political_party, :string
  end
end
