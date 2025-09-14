class AddShortNameToWards < ActiveRecord::Migration[8.0]
  def change
    add_column :wards, :short_name, :string
  end
end
