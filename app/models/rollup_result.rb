# Stores rolled up results
class RollupResult < RollupDB
  set_table_name "rollup_results"

  # Create a new result object
  def self.create_result(name, span)
    # lets see if we have one, we look for one dated between now
    # and back as far as interval if we find it still open use it
    result = RollupResult.new(:query_name => name, :sum_value => 0, :span => span, :reported_at => RollupTasks.now)
    return result
  end
end

