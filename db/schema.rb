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

ActiveRecord::Schema[7.2].define(version: 2025_12_13_011842) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "announcements", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.string "announcement_type", default: "info"
    t.datetime "published_at"
    t.datetime "expires_at"
    t.boolean "is_published", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_published"], name: "index_announcements_on_is_published"
    t.index ["published_at"], name: "index_announcements_on_published_at"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "announcement_id"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notification_type", default: 0, null: false, comment: "通知種類: 0=お知らせ, 1=非アクティブリマインド, 2=リアクションまとめ"
    t.text "message", comment: "リマインダー通知のメッセージ"
    t.string "url", comment: "リマインダー通知のリンク先"
    t.index ["announcement_id"], name: "index_notifications_on_announcement_id"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "walk_id"
    t.text "body"
    t.integer "weather"
    t.integer "feeling"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["user_id", "created_at"], name: "index_posts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["walk_id"], name: "index_posts_on_walk_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.integer "kind", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "kind"], name: "index_reactions_on_post_id_and_kind"
    t.index ["post_id"], name: "index_reactions_on_post_id"
    t.index ["user_id", "post_id", "kind"], name: "index_reactions_on_user_post_kind", unique: true
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_uid"
    t.text "google_token"
    t.text "google_refresh_token"
    t.datetime "google_expires_at"
    t.string "avatar_url"
    t.string "name"
    t.integer "target_distance", default: 3000, null: false
    t.boolean "use_google_avatar", default: true
    t.boolean "is_admin", default: false, null: false
    t.boolean "walk_reminder_enabled", default: false, null: false, comment: "散歩時間リマインド通知の有効/無効"
    t.time "walk_reminder_time", default: "2000-01-01 19:00:00", comment: "散歩リマインド通知の時刻"
    t.boolean "inactive_days_reminder_enabled", default: true, null: false, comment: "非アクティブリマインド通知の有効/無効"
    t.integer "inactive_days_threshold", default: 3, null: false, comment: "非アクティブと判定する日数"
    t.boolean "reaction_summary_enabled", default: true, null: false, comment: "リアクションまとめ通知の有効/無効"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_admin"], name: "index_users_on_is_admin"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "walks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "walked_on"
    t.integer "duration"
    t.decimal "distance"
    t.string "location"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "steps"
    t.integer "calories_burned"
    t.index ["user_id", "walked_on"], name: "index_walks_on_user_id_and_walked_on"
    t.index ["user_id"], name: "index_walks_on_user_id"
    t.index ["walked_on"], name: "index_walks_on_walked_on"
  end

  create_table "web_push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "endpoint", null: false, comment: "通知送信先URL"
    t.string "p256dh", null: false, comment: "暗号化キー (P-256 curve)"
    t.string "auth_key", null: false, comment: "認証シークレット"
    t.string "user_agent", comment: "登録したブラウザ/デバイス情報"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endpoint"], name: "index_web_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_web_push_subscriptions_on_user_id"
  end

  add_foreign_key "notifications", "announcements"
  add_foreign_key "notifications", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "posts", "walks"
  add_foreign_key "reactions", "posts"
  add_foreign_key "reactions", "users"
  add_foreign_key "walks", "users"
  add_foreign_key "web_push_subscriptions", "users"
end
