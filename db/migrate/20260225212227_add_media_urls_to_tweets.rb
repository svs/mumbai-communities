class AddMediaUrlsToTweets < ActiveRecord::Migration[8.0]
  def change
    add_column :tweets, :media_urls, :json
  end
end
