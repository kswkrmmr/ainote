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

ActiveRecord::Schema[8.1].define(version: 2026_08_14_054111) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "invitations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "room_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_invitations_on_room_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "original_body", null: false
    t.bigint "theme_id", null: false
    t.text "translated_body", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["theme_id"], name: "index_messages_on_theme_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "room_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "partner_display_name", null: false
    t.bigint "room_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["room_id", "user_id"], name: "index_room_members_on_room_id_and_user_id", unique: true
    t.index ["room_id"], name: "index_room_members_on_room_id"
    t.index ["user_id"], name: "index_room_members_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "owner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_rooms_on_owner_id"
  end

  create_table "themes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "room_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["room_id"], name: "index_themes_on_room_id"
    t.index ["user_id"], name: "index_themes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "nickname", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "invitations", "rooms"
  add_foreign_key "messages", "themes"
  add_foreign_key "messages", "users"
  add_foreign_key "room_members", "rooms"
  add_foreign_key "room_members", "users"
  add_foreign_key "rooms", "users", column: "owner_id"
  add_foreign_key "themes", "rooms"
  add_foreign_key "themes", "users"
end
