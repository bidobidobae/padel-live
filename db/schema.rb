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

ActiveRecord::Schema[8.1].define(version: 2026_01_11_102313) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cameras", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "camera_uid", null: false
    t.bigint "court_id", null: false
    t.datetime "created_at", null: false
    t.string "device_path"
    t.datetime "updated_at", null: false
    t.index ["court_id"], name: "index_cameras_on_court_id"
  end

  create_table "courts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "number"
    t.datetime "updated_at", null: false
  end

  create_table "recordings", force: :cascade do |t|
    t.boolean "active", default: true
    t.bigint "camera_id", null: false
    t.bigint "court_id", null: false
    t.datetime "created_at", null: false
    t.string "file_path"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "updated_at", null: false
    t.index ["camera_id"], name: "index_recordings_on_camera_id"
    t.index ["court_id"], name: "index_recordings_on_court_id"
  end

  add_foreign_key "cameras", "courts"
  add_foreign_key "recordings", "cameras"
  add_foreign_key "recordings", "courts"
end
