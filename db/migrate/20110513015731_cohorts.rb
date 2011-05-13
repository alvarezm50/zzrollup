class Cohorts < ActiveRecord::Migration
  def self.up
    add_column :rollup_results, :cohort, :integer
    add_index :rollup_results, :cohort
  end

  def self.down
  end
end
