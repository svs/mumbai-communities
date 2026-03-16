class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.string :ward_code, null: false
      t.integer :category_id
      t.integer :created_by_id, null: false
      t.integer :tweet_id
      t.string :status, default: "open"

      t.timestamps
    end

    add_index :issues, :ward_code
    add_index :issues, :category_id
    add_index :issues, :created_by_id
    add_index :issues, :tweet_id
    add_index :issues, :status
    add_foreign_key :issues, :categories
    add_foreign_key :issues, :users, column: :created_by_id
    add_foreign_key :issues, :tweets

    create_table :todo_items do |t|
      t.integer :issue_id, null: false
      t.string :title, null: false
      t.boolean :completed, default: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :todo_items, [:issue_id, :position]
    add_foreign_key :todo_items, :issues
  end
end
