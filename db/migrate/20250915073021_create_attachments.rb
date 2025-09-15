class CreateAttachments < ActiveRecord::Migration[8.0]
  def change
    create_table :attachments do |t|
      t.references :attachable, polymorphic: true, null: false
      t.string :name, null: false
      t.string :url
      t.string :attachment_type, default: 'link'
      t.string :mime_type
      t.integer :position, default: 1

      t.timestamps
    end

    add_index :attachments, [:attachable_type, :attachable_id, :position]
  end
end
