class CreateProjectShareTaskRates < ActiveRecord::Migration[7.1]
  def change
    create_table :project_share_task_rates do |t|
      t.references :project_share, null: false, foreign_key: true
      t.references :assigned_task, null: false, foreign_key: true
      t.integer :rate, default: 0, null: false

      t.timestamps
    end

    add_index :project_share_task_rates, [ :project_share_id, :assigned_task_id ],
              unique: true, name: "idx_project_share_task_rates_unique"
  end
end
