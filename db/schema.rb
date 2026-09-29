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

ActiveRecord::Schema[7.1].define(version: 2026_09_29_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "access_infos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false
    t.integer "plan_weekly_capacity_minutes"
    t.integer "plan_work_days", default: 31, null: false
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
    t.boolean "advanced_time_copying", default: false, null: false
    t.integer "plan_default_capacity_minutes", default: 2250, null: false
  end

  create_table "plan_assignments", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "project_id"
    t.bigint "user_id"
    t.bigint "placeholder_id"
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "minutes_per_day", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "start_date", "end_date"], name: "index_plan_assignments_on_organization_and_dates"
    t.index ["organization_id"], name: "index_plan_assignments_on_organization_id"
    t.index ["placeholder_id"], name: "index_plan_assignments_on_placeholder_id"
    t.index ["project_id"], name: "index_plan_assignments_on_project_id"
    t.index ["user_id"], name: "index_plan_assignments_on_user_id"
    t.check_constraint "(user_id IS NULL) <> (placeholder_id IS NULL)", name: "plan_assignments_one_assignee"
    t.check_constraint "end_date >= start_date", name: "plan_assignments_date_order"
  end

  create_table "plan_milestones", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_plan_milestones_on_organization_id"
    t.index ["project_id"], name: "index_plan_milestones_on_project_id"
  end

  create_table "plan_placeholders", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "roles"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_plan_placeholders_on_organization_id"
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

  create_table "project_shares", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "invitation_token", null: false
    t.bigint "invited_by_id", null: false
    t.string "invited_email", null: false
    t.bigint "organization_id"
    t.bigint "project_id", null: false
    t.datetime "rejected_at"
    t.datetime "revoked_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["invitation_token"], name: "index_project_shares_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_project_shares_on_invited_by_id"
    t.index ["organization_id"], name: "index_project_shares_on_organization_id"
    t.index ["project_id", "invited_email"], name: "index_project_shares_on_pending_project_and_email", unique: true, where: "(status = 0)"
    t.index ["project_id", "organization_id"], name: "index_project_shares_on_accepted_project_and_organization", unique: true, where: "(status = 1)"
    t.index ["project_id"], name: "index_project_shares_on_project_id"
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
    t.string "plan_color"
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
    t.string "api_token"
    t.string "api_token_digest"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["api_token_digest"], name: "index_users_on_api_token_digest", unique: true
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
  add_foreign_key "plan_assignments", "organizations"
  add_foreign_key "plan_assignments", "plan_placeholders", column: "placeholder_id"
  add_foreign_key "plan_assignments", "projects"
  add_foreign_key "plan_assignments", "users"
  add_foreign_key "plan_milestones", "organizations"
  add_foreign_key "plan_milestones", "projects"
  add_foreign_key "plan_placeholders", "organizations"
  add_foreign_key "project_accesses", "access_infos"
  add_foreign_key "project_accesses", "projects"
  add_foreign_key "project_shares", "organizations"
  add_foreign_key "project_shares", "projects"
  add_foreign_key "project_shares", "users", column: "invited_by_id"
  add_foreign_key "projects", "clients"
  add_foreign_key "tasks", "organizations"
  add_foreign_key "time_regs", "assigned_tasks"
  add_foreign_key "time_regs", "users"
end
