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

ActiveRecord::Schema[7.0].define(version: 2024_04_23_051916) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_infos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false
    t.index ["organization_id"], name: "index_access_infos_on_organization_id"
    t.index ["user_id"], name: "index_access_infos_on_user_id"
  end

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
    t.bigint "organization_id"
    t.index ["organization_id"], name: "index_clients_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rate", default: 0, null: false
    t.boolean "billable", default: false, null: false
    t.index ["client_id"], name: "index_projects_on_client_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id"
    t.index ["organization_id"], name: "index_tasks_on_organization_id"
  end

  create_table "time_regs", force: :cascade do |t|
    t.text "notes"
    t.integer "minutes", default: 0, null: false
    t.bigint "assigned_task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date_worked"
    t.datetime "start_time", precision: nil
    t.bigint "user_id", null: false
    t.index ["assigned_task_id"], name: "index_time_regs_on_assigned_task_id"
    t.index ["user_id"], name: "index_time_regs_on_user_id"
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
    t.boolean "is_verified", default: true
    t.string "locale", default: "en", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "access_infos", "organizations"
  add_foreign_key "access_infos", "users"
  add_foreign_key "assigned_tasks", "projects"
  add_foreign_key "assigned_tasks", "tasks"
  add_foreign_key "clients", "organizations"
  add_foreign_key "projects", "clients"
  add_foreign_key "tasks", "organizations"
  add_foreign_key "time_regs", "assigned_tasks"
  add_foreign_key "time_regs", "users"
end
