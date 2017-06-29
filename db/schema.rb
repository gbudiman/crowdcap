# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170628023941) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "contents", id: :bigserial, force: :cascade do |t|
    t.string   "title",      limit: 255,                                                                             null: false
    t.datetime "created_at",             precision: 6, default: -> { "('now'::text)::timestamp(6) with time zone" }, null: false
    t.datetime "updated_at",             precision: 6, default: -> { "('now'::text)::timestamp(6) with time zone" }, null: false
    t.index ["title"], name: "contents_title_unique", unique: true, using: :btree
  end

  create_table "features", id: :bigserial, force: :cascade do |t|
    t.bigint   "picture_id",                                                                             null: false
    t.datetime "created_at", precision: 6, default: -> { "('now'::text)::timestamp(6) with time zone" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "('now'::text)::timestamp(6) with time zone" }, null: false
    t.float    "vectors",                                                                                             array: true
  end

  create_table "picture_contents", id: :bigserial, force: :cascade do |t|
    t.bigint   "picture_id",                                                                             null: false
    t.bigint   "content_id",                                                                             null: false
    t.datetime "created_at", precision: 6, default: -> { "('now'::text)::timestamp(6) with time zone" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "('now'::text)::timestamp(6) with time zone" }, null: false
  end

  create_table "pictures", id: :bigserial, force: :cascade do |t|
    t.string   "name",       limit: 255,                                                                             null: false
    t.datetime "created_at",             precision: 6, default: -> { "('now'::text)::timestamp(6) with time zone" }, null: false
    t.datetime "updated_at",             precision: 6, default: -> { "('now'::text)::timestamp(6) with time zone" }, null: false
    t.index ["name"], name: "picture_name_index", using: :btree
    t.index ["name"], name: "picture_unique_name", unique: true, using: :btree
  end

  create_table "potentials", id: :bigserial, force: :cascade do |t|
    t.bigint   "query_id",                    null: false
    t.bigint   "target_id",                   null: false
    t.integer  "count_evaluated", default: 0, null: false
    t.integer  "count_correct",   default: 0, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["query_id", "target_id"], name: "index_potentials_on_query_id_and_target_id", unique: true, using: :btree
  end

  add_foreign_key "features", "pictures", name: "features_picture_id_foreign", on_update: :cascade, on_delete: :cascade
  add_foreign_key "picture_contents", "contents", name: "picture_contents_content_id_foreign", on_update: :cascade, on_delete: :cascade
  add_foreign_key "picture_contents", "pictures", name: "picture_contents_picture_id_foreign", on_update: :cascade, on_delete: :cascade
  add_foreign_key "potentials", "pictures", column: "query_id", name: "fk_query_picture"
  add_foreign_key "potentials", "pictures", column: "target_id", name: "fk_target_picture"
end