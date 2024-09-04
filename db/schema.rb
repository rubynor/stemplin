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

ActiveRecord::Schema[7.0].define(version: 2024_09_04_135858) do
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
    t.index ["user_id", "organization_id"], name: "index_access_infos_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_access_infos_on_user_id"
  end

  create_table "assigned_tasks", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rate", default: 0, null: false
    t.boolean "is_archived", default: false
    t.index ["project_id"], name: "index_assigned_tasks_on_project_id"
    t.index ["task_id"], name: "index_assigned_tasks_on_task_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id"
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_clients_on_discarded_at"
    t.index ["organization_id"], name: "index_clients_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency"
  end

  create_table "project_accesses", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "access_info_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_info_id"], name: "index_project_accesses_on_access_info_id"
    t.index ["project_id", "access_info_id"], name: "index_project_accesses_on_project_id_and_access_info_id", unique: true
    t.index ["project_id"], name: "index_project_accesses_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rate", default: 0, null: false
    t.boolean "billable", default: false, null: false
    t.datetime "discarded_at"
    t.index ["client_id"], name: "index_projects_on_client_id"
    t.index ["discarded_at"], name: "index_projects_on_discarded_at"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id"
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_tasks_on_discarded_at"
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
    t.datetime "discarded_at"
    t.index ["assigned_task_id"], name: "index_time_regs_on_assigned_task_id"
    t.index ["discarded_at"], name: "index_time_regs_on_discarded_at"
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
    t.string "locale", default: "en", null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.boolean "is_verified", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "access_infos", "organizations"
  add_foreign_key "access_infos", "users"
  add_foreign_key "assigned_tasks", "projects"
  add_foreign_key "assigned_tasks", "tasks"
  add_foreign_key "clients", "organizations"
  add_foreign_key "project_accesses", "access_infos"
  add_foreign_key "project_accesses", "projects"
  add_foreign_key "projects", "clients"
  add_foreign_key "tasks", "organizations"
  add_foreign_key "time_regs", "assigned_tasks"
  add_foreign_key "time_regs", "users"
end
