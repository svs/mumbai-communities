class AddConversationIdToTweets < ActiveRecord::Migration[8.0]
  def change
    add_column :tweets, :conversation_id, :string
  end
end
