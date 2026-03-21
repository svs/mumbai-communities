class RefactorPositionsDropDepartment < ActiveRecord::Migration[8.0]
  def up
    add_column :positions, :organisation_id, :integer unless column_exists?(:positions, :organisation_id)
    add_column :positions, :section, :string unless column_exists?(:positions, :section)
    add_column :positions, :person_id, :integer unless column_exists?(:positions, :person_id)

    add_column :people, :bio, :text unless column_exists?(:people, :bio)
    add_column :people, :linkedin_url, :string unless column_exists?(:people, :linkedin_url)
    add_column :people, :twitter_handle, :string unless column_exists?(:people, :twitter_handle)
    add_column :people, :profile_data, :json unless column_exists?(:people, :profile_data)

    # Populate organisation_id and section from department
    execute <<-SQL
      UPDATE positions
      SET organisation_id = (
        SELECT organisation_id FROM departments WHERE departments.id = positions.department_id
      ),
      section = (
        SELECT name FROM departments WHERE departments.id = positions.department_id
      )
      WHERE department_id IS NOT NULL
    SQL
  end

  def down
    remove_column :positions, :organisation_id if column_exists?(:positions, :organisation_id)
    remove_column :positions, :section if column_exists?(:positions, :section)
    remove_column :positions, :person_id if column_exists?(:positions, :person_id)
    remove_column :people, :bio if column_exists?(:people, :bio)
    remove_column :people, :linkedin_url if column_exists?(:people, :linkedin_url)
    remove_column :people, :twitter_handle if column_exists?(:people, :twitter_handle)
    remove_column :people, :profile_data if column_exists?(:people, :profile_data)
  end
end
