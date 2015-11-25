# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20151122170815) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "adminpack"

  create_table "jobs", force: :cascade do |t|
    t.string   "name"
    t.integer  "job_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "loads", force: :cascade do |t|
    t.date     "delivery_date"
    t.integer  "delivery_shift"
    t.integer  "status"
    t.integer  "truck_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "loads", ["delivery_date", "delivery_shift"], name: "delivery_date_shift_load_index", using: :btree
  add_index "loads", ["truck_id"], name: "index_loads_on_truck_id", using: :btree

  create_table "order_releases", force: :cascade do |t|
    t.date     "delivery_date"
    t.integer  "delivery_shift"
    t.string   "origin_name"
    t.text     "origin_raw_line_1"
    t.string   "origin_city"
    t.string   "origin_state"
    t.string   "origin_country"
    t.integer  "origin_zip"
    t.string   "destination_name"
    t.text     "destination_raw_line_1"
    t.string   "destination_city"
    t.string   "destination_state"
    t.integer  "destination_zip"
    t.string   "destination_country"
    t.string   "phone_number"
    t.integer  "mode"
    t.string   "purchase_order_number"
    t.float    "volume"
    t.integer  "handling_unit_quantity"
    t.integer  "handling_unit_type"
    t.integer  "status"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "load_id"
    t.integer  "stop_order_number"
  end

  add_index "order_releases", ["delivery_date"], name: "index_order_releases_on_delivery_date", using: :btree
  add_index "order_releases", ["delivery_shift"], name: "index_order_releases_on_delivery_shift", using: :btree
  add_index "order_releases", ["load_id"], name: "index_order_releases_on_load_id", using: :btree
  add_index "order_releases", ["status"], name: "index_order_releases_on_status", using: :btree

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "name"
  end

  create_table "trucks", force: :cascade do |t|
    t.string   "name"
    t.integer  "driver_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "max_capacity"
    t.integer  "capacity",     default: 1400
  end

  create_table "users", force: :cascade do |t|
    t.string   "login"
    t.text     "password_digest"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "user_role"
  end

  create_table "works", force: :cascade do |t|
    t.string   "name"
    t.integer  "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "loads", "trucks"
  add_foreign_key "order_releases", "loads"
end
