class AddProfileDataToPositions < ActiveRecord::Migration[8.0]
  def change
    add_column :positions, :profile_data, :json
    add_column :positions, :bio, :text
    add_column :positions, :linkedin_url, :string
    add_column :positions, :twitter_handle, :string
  end
end
