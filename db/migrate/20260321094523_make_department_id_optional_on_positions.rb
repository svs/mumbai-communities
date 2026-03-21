class MakeDepartmentIdOptionalOnPositions < ActiveRecord::Migration[8.0]
  def up
    change_column_null :positions, :department_id, true
  end

  def down
    change_column_null :positions, :department_id, false
  end
end
