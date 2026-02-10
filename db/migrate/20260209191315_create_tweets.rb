class CreateTweets < ActiveRecord::Migration[8.0]
  def change
    create_table :tweets do |t|
      t.string :tweet_id, null: false
      t.references :ward, null: false, foreign_key: true
      t.text :body, null: false
      t.string :author_username
      t.string :author_name
      t.datetime :tweeted_at
      t.integer :like_count, default: 0
      t.integer :retweet_count, default: 0
      t.integer :reply_count, default: 0

      t.timestamps
    end
    add_index :tweets, :tweet_id, unique: true
    add_index :tweets, [:ward_id, :tweeted_at]
  end
end
