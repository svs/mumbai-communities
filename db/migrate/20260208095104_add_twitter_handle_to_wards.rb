class AddTwitterHandleToWards < ActiveRecord::Migration[8.0]
  def up
    add_column :wards, :twitter_handle, :string

    handles = {
      "A" => "mybmcWardA",
      "B" => "mybmcWardB",
      "C" => "mybmcWardC",
      "D" => "mybmcWardD",
      "E" => "mybmcWardE",
      "F NORTH" => "mybmcWardFN",
      "F SOUTH" => "mybmcWardFS",
      "G NORTH" => "mybmcWardGN",
      "G SOUTH" => "mybmcWardGS",
      "H EAST" => "mybmcWardHE",
      "H WEST" => "mybmcWardHW",
      "K EAST" => "mybmcWardKE",
      "K NORTH" => "mybmcWardKN",
      "K WEST" => "mybmcWardKW",
      "L" => "mybmcWardL",
      "M EAST" => "mybmcWardME",
      "M WEST" => "mybmcWardMW",
      "N" => "mybmcWardN",
      "P NORTH" => "mybmcWardPN",
      "P SOUTH" => "mybmcWardPS",
      "R SOUTH" => "mybmcWardRS",
      "R/CENTRAL" => "mybmcWardRC",
      "R/Central" => "mybmcWardRC",
      "R/North" => "mybmcWardRN",
      "S" => "mybmcWardS",
      "T" => "mybmcWardT",
      "P EAST" => "mybmcWardPE"
    }

    handles.each do |ward_code, handle|
      execute "UPDATE wards SET twitter_handle = '#{handle}' WHERE ward_code = '#{ward_code}'"
    end
  end

  def down
    remove_column :wards, :twitter_handle
  end
end
