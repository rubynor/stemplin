class AlterTasks < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :tasks, :organizations
  end
end
