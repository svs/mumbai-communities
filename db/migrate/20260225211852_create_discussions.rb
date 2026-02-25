class CreateDiscussions < ActiveRecord::Migration[8.0]
  def change
    create_table :discussions do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.string :discussable_type
      t.integer :discussable_id
      t.references :user, foreign_key: true
      t.references :category, foreign_key: true
      t.string :status, default: "open"
      t.boolean :pinned, default: false
      t.integer :posts_count, default: 0
      t.datetime :last_post_at

      t.timestamps
    end

    add_index :discussions, [:discussable_type, :discussable_id]
    add_index :discussions, :status
    add_index :discussions, [:pinned, :last_post_at]
  end
end
