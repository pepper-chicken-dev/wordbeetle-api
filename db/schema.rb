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

ActiveRecord::Schema[8.1].define(version: 2026_02_16_000005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "examples", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "display_order", null: false
    t.text "sentence", null: false
    t.text "translation", null: false
    t.datetime "updated_at", null: false
    t.bigint "word_id", null: false
    t.index ["word_id"], name: "index_examples_on_word_id"
  end

  create_table "meanings", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "display_order", null: false
    t.datetime "updated_at", null: false
    t.bigint "word_id", null: false
    t.index ["word_id"], name: "index_meanings_on_word_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "easy_interval_days", null: false
    t.integer "hard_interval_days", null: false
    t.integer "uncertain_interval_days", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_settings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "google_id"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "wordbooks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_wordbooks_on_user_id"
  end

  create_table "words", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "next_review_date"
    t.string "spelling", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.bigint "wordbook_id", null: false
    t.index ["wordbook_id"], name: "index_words_on_wordbook_id"
  end

  add_foreign_key "examples", "words"
  add_foreign_key "meanings", "words"
  add_foreign_key "settings", "users"
  add_foreign_key "wordbooks", "users"
  add_foreign_key "words", "wordbooks"
end
