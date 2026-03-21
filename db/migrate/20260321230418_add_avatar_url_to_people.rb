class AddAvatarUrlToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :avatar_url, :string
  end
end
