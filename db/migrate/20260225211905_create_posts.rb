class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :discussion, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :posts }
      t.text :body, null: false
      t.integer :depth, default: 0

      t.timestamps
    end

    add_index :posts, [:discussion_id, :created_at]
  end
end
