class AddIsCanonicalToBoundaries < ActiveRecord::Migration[8.0]
  def change
    # Column already exists, just migrate the data
    # Migrate existing data: boundaries with status 'canonical' become status = 'approved'
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE boundaries
          SET status = 'approved'
          WHERE status = 'canonical'
        SQL
      end
    end
  end
end
