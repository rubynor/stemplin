# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_03_18_161808) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assigned_tasks", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["project_id"], name: "index_assigned_tasks_on_project_id"
    t.index ["task_id"], name: "index_assigned_tasks_on_task_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_memberships_on_project_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "project_reports", force: :cascade do |t|
    t.string "creator"
    t.string "timeframe"
    t.date "date_start"
    t.date "date_end"
    t.string "client_id"
    t.string "project_id"
    t.text "task_ids", default: [], array: true
    t.text "member_ids", default: [], array: true
    t.string "group_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.datetime "startdate", precision: nil
    t.text "description"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "billable_rate", default: 0, null: false
    t.boolean "billable_project", default: false, null: false
    t.index ["client_id"], name: "index_projects_on_client_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "time_regs", force: :cascade do |t|
    t.text "notes"
    t.integer "minutes", default: 0, null: false
    t.bigint "membership_id", null: false
    t.bigint "assigned_task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active"
    t.datetime "updated"
    t.date "date_worked"
    t.index ["assigned_task_id"], name: "index_time_regs_on_assigned_task_id"
    t.index ["membership_id"], name: "index_time_regs_on_membership_id"
  end

  create_table "user_reports", force: :cascade do |t|
    t.string "creator"
    t.string "timeframe"
    t.date "date_start"
    t.date "date_end"
    t.string "user_id"
    t.text "task_ids", default: [], array: true
    t.text "project_ids", default: [], array: true
    t.string "group_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "assigned_tasks", "projects"
  add_foreign_key "assigned_tasks", "tasks"
  add_foreign_key "memberships", "projects"
  add_foreign_key "memberships", "users"
  add_foreign_key "projects", "clients"
  add_foreign_key "time_regs", "assigned_tasks"
  add_foreign_key "time_regs", "memberships"
end
