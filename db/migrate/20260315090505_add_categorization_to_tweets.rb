class AddCategorizationToTweets < ActiveRecord::Migration[8.0]
  def change
    add_column :tweets, :category, :string
    add_column :tweets, :tweet_type, :string
  end
end
