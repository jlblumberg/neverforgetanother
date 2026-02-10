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

ActiveRecord::Schema[8.1].define(version: 2026_02_10_024935) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "reminder_deliveries", force: :cascade do |t|
    t.integer "attempt_count", default: 0, null: false
    t.integer "channel", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.bigint "reminder_id", null: false
    t.datetime "scheduled_at", null: false
    t.datetime "sent_at"
    t.integer "status", default: 0, null: false
    t.string "telnyx_message_id"
    t.datetime "updated_at", null: false
    t.index ["reminder_id", "scheduled_at", "channel"], name: "index_reminder_deliveries_on_reminder_scheduled_at_channel", unique: true
    t.index ["reminder_id"], name: "index_reminder_deliveries_on_reminder_id"
  end

  create_table "reminders", force: :cascade do |t|
    t.datetime "cancelled"
    t.datetime "created_at", null: false
    t.string "description", limit: 100, null: false
    t.boolean "email_enabled", default: false, null: false
    t.integer "period", null: false
    t.boolean "sms_enabled", default: false, null: false
    t.datetime "started", null: false
    t.string "title", limit: 25, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_reminders_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "phone_country_iso"
    t.datetime "phone_verified_at"
    t.string "provider", null: false
    t.string "timezone"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true, where: "(phone IS NOT NULL)"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "reminder_deliveries", "reminders"
  add_foreign_key "reminders", "users"
end
