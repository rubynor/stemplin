class CreatePlanModule < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :plan_default_capacity_minutes, :integer, default: 2250, null: false
    add_column :access_infos, :plan_weekly_capacity_minutes, :integer
    # Bitmask of working days, bit 0 = Monday ... bit 6 = Sunday. 31 = Monday to Friday.
    add_column :access_infos, :plan_work_days, :integer, default: 31, null: false
    add_column :projects, :plan_color, :string

    create_table :plan_placeholders do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :roles
      t.timestamps
    end

    create_table :plan_assignments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.references :user, foreign_key: true
      t.references :placeholder, foreign_key: { to_table: :plan_placeholders }
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :minutes_per_day, null: false
      t.text :notes
      t.timestamps
    end
    add_index :plan_assignments, %i[organization_id start_date end_date], name: "index_plan_assignments_on_organization_and_dates"
    add_check_constraint :plan_assignments, "(user_id IS NULL) <> (placeholder_id IS NULL)", name: "plan_assignments_one_assignee"
    add_check_constraint :plan_assignments, "end_date >= start_date", name: "plan_assignments_date_order"

    create_table :plan_milestones do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.date :date, null: false
      t.timestamps
    end
  end
end
