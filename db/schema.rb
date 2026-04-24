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

ActiveRecord::Schema[8.1].define(version: 2026_04_24_122013) do
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
    t.check_constraint "char_length(sentence) <= 1000", name: "check_examples_sentence_length"
    t.check_constraint "char_length(translation) <= 1000", name: "check_examples_translation_length"
  end

  create_table "meanings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "definition", null: false
    t.integer "display_order", null: false
    t.datetime "updated_at", null: false
    t.bigint "word_id", null: false
    t.index ["word_id"], name: "index_meanings_on_word_id"
    t.check_constraint "char_length(definition) <= 1000", name: "check_meanings_definition_length"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.interval "easy_interval", null: false
    t.interval "hard_interval", null: false
    t.interval "uncertain_interval", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_settings_on_user_id"
    t.check_constraint "hard_interval < uncertain_interval AND uncertain_interval < easy_interval", name: "check_settings_intervals_ascending_order"
    t.check_constraint "hard_interval > 'PT0S'::interval AND uncertain_interval > 'PT0S'::interval AND easy_interval > 'PT0S'::interval", name: "check_settings_intervals_positive"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "guest_expires_at"
    t.string "name"
    t.string "provider", null: false
    t.string "provider_uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "provider_uid"], name: "index_users_on_provider_and_provider_uid", unique: true
    t.check_constraint "provider::text <> 'guest'::text OR guest_expires_at IS NOT NULL", name: "check_guest_expires_at_presence"
    t.check_constraint "provider::text = 'guest'::text OR provider_uid IS NOT NULL", name: "chk_provider_uid_required_for_non_guest"
    t.check_constraint "provider::text = ANY (ARRAY['google'::character varying, 'guest'::character varying]::text[])", name: "check_users_provider_values"
  end

  create_table "wordbooks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_wordbooks_on_user_id"
    t.check_constraint "char_length(title::text) <= 255", name: "check_wordbooks_title_length"
  end

  create_table "words", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "next_review_at"
    t.string "spelling", null: false
    t.string "status", default: "not_studied", null: false
    t.datetime "updated_at", null: false
    t.bigint "wordbook_id", null: false
    t.index ["wordbook_id"], name: "index_words_on_wordbook_id"
    t.check_constraint "char_length(spelling::text) <= 255", name: "check_words_spelling_length"
    t.check_constraint "status::text = ANY (ARRAY['not_studied'::character varying, 'hard'::character varying, 'uncertain'::character varying, 'easy'::character varying]::text[])", name: "check_words_status_values"
  end

  add_foreign_key "examples", "words"
  add_foreign_key "meanings", "words"
  add_foreign_key "settings", "users"
  add_foreign_key "wordbooks", "users"
  add_foreign_key "words", "wordbooks"
end
