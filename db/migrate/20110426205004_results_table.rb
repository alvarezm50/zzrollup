class ResultsTable < ActiveRecord::Migration
  def self.up
    create_table :rollup_results, :force => true do |t|
      t.timestamp               :reported_at
      t.string                  :query_name,             :null => false
      t.integer                 :sum_value
      t.integer                 :span
    end
    add_index :rollup_results, :query_name
    add_index :rollup_results, :reported_at
    add_index :rollup_results, :span
    add_index :rollup_results, ["reported_at", "query_name"], :unique => true

    # this is essentially a temp table that is used to hold the
    # cartesian product of the unique times and query names to be
    # used in an outer join to make sure we have no gaps when data
    # is missing
    create_table :name_and_time, :id => false, :force => true do |t|
      t.timestamp               :reported_at,            :null => false
      t.string                  :query_name,             :null => false
    end
    add_index :name_and_time, ["reported_at", "query_name"], :unique => true

  end

  def self.down
  end
end
