class AddInReplyToStatusIdToTweets < ActiveRecord::Migration[8.0]
  def change
    add_column :tweets, :in_reply_to_status_id, :string
  end
end
