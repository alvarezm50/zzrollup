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

ActiveRecord::Schema.define(:version => 20110513015731) do

  create_table "name_and_time", :id => false, :force => true do |t|
    t.datetime "reported_at", :null => false
    t.string   "query_name",  :null => false
  end

  add_index "name_and_time", ["reported_at", "query_name"], :name => "index_name_and_time_on_reported_at_and_query_name", :unique => true

  create_table "rollup_results", :force => true do |t|
    t.datetime "reported_at"
    t.string   "query_name",  :null => false
    t.integer  "sum_value"
    t.integer  "span"
    t.integer  "cohort"
  end

  add_index "rollup_results", ["cohort"], :name => "index_rollup_results_on_cohort"
  add_index "rollup_results", ["query_name"], :name => "index_rollup_results_on_query_name"
  add_index "rollup_results", ["reported_at", "query_name"], :name => "index_rollup_results_on_reported_at_and_query_name", :unique => true
  add_index "rollup_results", ["reported_at"], :name => "index_rollup_results_on_reported_at"
  add_index "rollup_results", ["span"], :name => "index_rollup_results_on_span"

end
