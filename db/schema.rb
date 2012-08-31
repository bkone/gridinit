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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120831032911) do

  create_table "attachments", :force => true do |t|
    t.string "filename"
    t.binary "data",     :limit => 16777215
  end

  create_table "nodes", :force => true do |t|
    t.string   "host"
    t.string   "role",        :default => "standalone"
    t.string   "master"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "instance_id"
    t.integer  "user_id"
    t.datetime "stopped"
    t.string   "location"
    t.string   "region"
  end

  create_table "runs", :force => true do |t|
    t.text     "params"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "status"
    t.integer  "privacy_flag"
    t.string   "notes"
    t.integer  "threads"
    t.integer  "user_id"
    t.datetime "started"
    t.datetime "completed"
  end

  create_table "transactions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "node_id"
    t.string   "instance_id"
    t.string   "instance_type"
    t.integer  "hours"
    t.integer  "rate"
    t.integer  "amount"
    t.string   "card_token"
    t.boolean  "success"
    t.string   "purchase_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.datetime "stopped_at"
  end

  create_table "users", :force => true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "email"
    t.string   "avatar_url"
    t.string   "role"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "card_token"
  end

end
